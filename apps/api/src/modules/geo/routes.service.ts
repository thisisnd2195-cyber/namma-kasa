import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type {
  GeoJsonArea,
  RecordableTrip,
  RecordedPath,
  Route,
} from "@namma-kasa/shared";
import type { createRouteSchema, updateRouteSchema } from "@namma-kasa/shared";
import type { z } from "zod";
import { DB, type Db } from "../../db/db.module";
import { GeoRepository } from "./geo.repository";

type CreateRoute = z.infer<typeof createRouteSchema>;
type UpdateRoute = z.infer<typeof updateRouteSchema>;

interface RouteRow {
  id: string;
  ward_id: string;
  name: string;
  route_code: string;
  serviceable_area: string;
  collection_days: number[];
  window_start: string;
  window_end: string;
  passes_per_day: number;
  waste_type_schedule: Record<string, string[]>;
  recorded_path: string | null;
  recorded_path_trip_id: string | null;
  recorded_path_at: Date | null;
}

@Injectable()
export class RoutesService {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly geo: GeoRepository,
  ) {}

  private toRoute(row: RouteRow): Route {
    return {
      id: row.id,
      wardId: row.ward_id,
      name: row.name,
      routeCode: row.route_code,
      serviceableArea: JSON.parse(row.serviceable_area) as GeoJsonArea,
      collectionDays: row.collection_days,
      windowStart: row.window_start.slice(0, 5),
      windowEnd: row.window_end.slice(0, 5),
      passesPerDay: row.passes_per_day,
      wasteTypeSchedule: row.waste_type_schedule as Route["wasteTypeSchedule"],
      // Written by recordPathFromTrip. Selected here because a value nobody
      // can read back is not a recorded path, it is a write-only column.
      recordedPath: row.recorded_path
        ? {
            geometry: JSON.parse(row.recorded_path) as RecordedPath["geometry"],
            tripId: row.recorded_path_trip_id,
            recordedAt: row.recorded_path_at ?? new Date(),
          }
        : null,
    };
  }

  private selectRoute() {
    return this.db
      .selectFrom("routes")
      .select([
        "id",
        "ward_id",
        "name",
        "route_code",
        sql<string>`ST_AsGeoJSON(serviceable_area)`.as("serviceable_area"),
        "collection_days",
        sql<string>`window_start::text`.as("window_start"),
        sql<string>`window_end::text`.as("window_end"),
        "passes_per_day",
        "waste_type_schedule",
        sql<string | null>`ST_AsGeoJSON(recorded_path)`.as("recorded_path"),
        "recorded_path_trip_id",
        "recorded_path_at",
      ]);
  }

  async listForWard(wardId: string): Promise<Route[]> {
    const rows = await this.selectRoute().where("ward_id", "=", wardId).orderBy("route_code").execute();
    return rows.map((row) => this.toRoute(row as RouteRow));
  }

  async get(id: string): Promise<Route> {
    const row = await this.selectRoute().where("id", "=", id).executeTakeFirst();
    if (!row) throw new HttpException("Route not found", HttpStatus.NOT_FOUND);
    return this.toRoute(row as RouteRow);
  }

  async create(input: CreateRoute): Promise<Route> {
    this.assertWindow(input.windowStart, input.windowEnd);

    const inserted = await this.translateGeoErrors(() =>
      this.db
        .insertInto("routes")
        .values({
          ward_id: input.wardId,
          name: input.name,
          route_code: input.routeCode,
          serviceable_area: this.geo.multi(input.serviceableArea),
          collection_days: sql`${input.collectionDays}::smallint[]` as unknown as number[],
          window_start: input.windowStart,
          window_end: input.windowEnd,
          passes_per_day: input.passesPerDay,
          waste_type_schedule: input.wasteTypeSchedule,
        })
        .returning("id")
        .executeTakeFirstOrThrow(),
    );

    return this.get(inserted.id);
  }

  async update(id: string, input: UpdateRoute): Promise<Route> {
    const current = await this.get(id);
    this.assertWindow(input.windowStart ?? current.windowStart, input.windowEnd ?? current.windowEnd);

    await this.translateGeoErrors(() =>
      this.db
        .updateTable("routes")
        .set({
          ...(input.name ? { name: input.name } : {}),
          ...(input.routeCode ? { route_code: input.routeCode } : {}),
          ...(input.serviceableArea
            ? { serviceable_area: this.geo.multi(input.serviceableArea) }
            : {}),
          ...(input.collectionDays
            ? { collection_days: sql`${input.collectionDays}::smallint[]` as unknown as number[] }
            : {}),
          ...(input.windowStart ? { window_start: input.windowStart } : {}),
          ...(input.windowEnd ? { window_end: input.windowEnd } : {}),
          ...(input.passesPerDay ? { passes_per_day: input.passesPerDay } : {}),
          ...(input.wasteTypeSchedule ? { waste_type_schedule: input.wasteTypeSchedule } : {}),
          updated_at: new Date(),
        })
        .where("id", "=", id)
        .execute(),
    );

    if (input.serviceableArea) await this.geo.reflagStrandedHouseholds(current.wardId);
    return this.get(id);
  }

  /** Completed trips whose trail could become this route's path. */
  async recordableTrips(routeId: string): Promise<RecordableTrip[]> {
    const rows = await sql<{
      id: string;
      service_date: string;
      pass_number: number;
      registration_number: string;
      position_count: string;
      ended_at: Date | null;
    }>`
      SELECT t.id,
             t.service_date::text AS service_date,
             t.pass_number,
             a.registration_number,
             count(p.*)::text AS position_count,
             t.ended_at
      FROM trips t
      JOIN autos a ON a.id = t.auto_id
      LEFT JOIN location_pings p ON p.trip_id = t.id
      WHERE t.route_id = ${routeId}::uuid
        AND t.status = 'completed'
      GROUP BY t.id, a.registration_number
      -- Two points make a line but not a route; anything less cannot be used.
      HAVING count(p.*) >= 2
      ORDER BY t.ended_at DESC NULLS LAST
      LIMIT 20
    `.execute(this.db);

    return rows.rows.map((row) => ({
      id: row.id,
      serviceDate: row.service_date,
      passNumber: row.pass_number,
      registrationNumber: row.registration_number,
      positionCount: Number(row.position_count),
      endedAt: row.ended_at,
    }));
  }

  /**
   * Adopt a completed trip's GPS trail as this route's path (FR-ROUTE-04).
   *
   * Drawing a path by hand in the portal is slow and approximate; the auto has
   * already driven the real one. Only a completed trip counts — an active
   * trip's trail is half a route, and adopting it would record a dead end.
   */
  async recordPathFromTrip(routeId: string, tripId: string): Promise<Route> {
    const trip = await this.db
      .selectFrom("trips")
      .select(["id", "route_id", "status"])
      .where("id", "=", tripId)
      .executeTakeFirst();
    if (!trip) throw new HttpException("Trip not found", HttpStatus.NOT_FOUND);
    if (trip.route_id !== routeId) {
      throw new HttpException("That trip did not run this route", HttpStatus.CONFLICT);
    }
    if (trip.status !== "completed") {
      throw new HttpException(
        "Only a completed trip has a full trail to record.",
        HttpStatus.CONFLICT,
      );
    }

    // Two points is the minimum for a line; a trip that never moved has no
    // path worth keeping, and ST_MakeLine would return null anyway.
    // location_pings stores plain lat/lng doubles, not a geometry — the table
    // is a Timescale hypertable and carries no id or geo column.
    const built = await sql<{ path: string | null }>`
      SELECT ST_AsGeoJSON(
        ST_MakeLine(
          ST_SetSRID(ST_MakePoint(p.lng, p.lat), 4326) ORDER BY p.recorded_at
        )
      ) AS path
      FROM location_pings p
      WHERE p.trip_id = ${tripId}::uuid
      HAVING count(*) >= 2
    `.execute(this.db);

    if (!built.rows[0]?.path) {
      throw new HttpException(
        "That trip has too few positions to build a path.",
        HttpStatus.CONFLICT,
      );
    }

    await this.db
      .updateTable("routes")
      .set({
        recorded_path: sql`ST_SetSRID(ST_GeomFromGeoJSON(${built.rows[0].path}), 4326)::geography`,
        recorded_path_trip_id: tripId,
        recorded_path_at: new Date(),
        updated_at: new Date(),
      })
      .where("id", "=", routeId)
      .execute();

    return this.get(routeId);
  }

  private assertWindow(start: string, end: string): void {
    if (start >= end) {
      throw new HttpException(
        "Collection window must end after it starts",
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }
  }

  /**
   * The containment and non-overlap rules live in database triggers so they
   * hold for every writer; this turns their errors into the 422/409 the
   * portal draws conflicts from.
   */
  private async translateGeoErrors<T>(run: () => Promise<T>): Promise<T> {
    try {
      return await run();
    } catch (error) {
      const message = error instanceof Error ? error.message : "";
      if (/within its ward boundary/.test(message)) {
        throw new HttpException(
          "Route area must lie entirely inside its ward",
          HttpStatus.UNPROCESSABLE_ENTITY,
        );
      }
      const overlap = /overlaps existing route: (.+)$/.exec(message);
      if (overlap) {
        throw new HttpException(
          `Route area overlaps existing route: ${overlap[1]}`,
          HttpStatus.CONFLICT,
        );
      }
      throw error;
    }
  }
}
