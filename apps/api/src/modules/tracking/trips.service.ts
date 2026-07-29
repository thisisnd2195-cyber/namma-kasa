import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type { DriverAssignment, Trip, TripEndReason, WasteType } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";

/** All scheduling is IST; "today" means the Indian calendar date (CHK030). */
export function serviceDateIST(now = new Date()): string {
  return new Date(now.getTime() + 5.5 * 3_600_000).toISOString().slice(0, 10);
}

export function weekdayIST(now = new Date()): number {
  const day = new Date(now.getTime() + 5.5 * 3_600_000).getUTCDay();
  return day === 0 ? 7 : day; // ISO: Monday = 1
}

interface TripRow {
  id: string;
  auto_id: string;
  driver_id: string;
  route_id: string;
  pass_number: number;
  service_date: string;
  started_at: Date;
  ended_at: Date | null;
  status: "active" | "completed" | "aborted";
  end_reason: TripEndReason | null;
  distance_covered_m: number | null;
}

const toTrip = (row: TripRow): Trip => ({
  id: row.id,
  autoId: row.auto_id,
  driverId: row.driver_id,
  routeId: row.route_id,
  passNumber: row.pass_number,
  serviceDate: String(row.service_date).slice(0, 10),
  startedAt: row.started_at,
  endedAt: row.ended_at,
  status: row.status,
  endReason: row.end_reason,
  distanceCoveredM: row.distance_covered_m,
});

@Injectable()
export class TripsService {
  constructor(@Inject(DB) private readonly db: Db) {}

  /** Resolves the driver behind a user account, with their current assignment. */
  private async currentAssignment(userId: string) {
    const row = await this.db
      .selectFrom("drivers as d")
      .innerJoin("driver_auto_assignments as da", (join) =>
        join.onRef("da.driver_id", "=", "d.id").on("da.effective_to", "is", null),
      )
      .innerJoin("autos as a", "a.id", "da.auto_id")
      .innerJoin("auto_route_assignments as ar", (join) =>
        join.onRef("ar.auto_id", "=", "a.id").on("ar.effective_to", "is", null),
      )
      .innerJoin("routes as r", "r.id", "ar.route_id")
      .select([
        "d.id as driverId",
        "a.id as autoId",
        "a.registration_number as registrationNumber",
        "r.id as routeId",
        "r.name as routeName",
        "r.route_code as routeCode",
        sql<string>`ST_AsGeoJSON(r.serviceable_area)`.as("area"),
        sql<string>`r.window_start::text`.as("windowStart"),
        sql<string>`r.window_end::text`.as("windowEnd"),
        "r.collection_days as collectionDays",
        "r.passes_per_day as passesPerDay",
        "r.waste_type_schedule as wasteSchedule",
      ])
      .where("d.user_id", "=", userId)
      .where("d.status", "=", "active")
      .executeTakeFirst();

    if (!row) {
      throw new HttpException(
        "No auto or route assigned. Contact your Ward Admin.",
        HttpStatus.NOT_FOUND,
      );
    }
    return row;
  }

  async assignmentFor(userId: string): Promise<DriverAssignment> {
    const a = await this.currentAssignment(userId);
    const serviceDate = serviceDateIST();
    const weekday = weekdayIST();

    const passes = await this.db
      .selectFrom("route_pass_days")
      .select(["pass_number", "status"])
      .where("route_id", "=", a.routeId)
      .where("service_date", "=", serviceDate)
      .execute();

    const completed = passes.filter((p) => p.status === "completed").length;
    const settled = new Set(
      passes.filter((p) => p.status !== "pending").map((p) => p.pass_number),
    );
    const nextPass =
      Array.from({ length: a.passesPerDay }, (_, i) => i + 1).find((n) => !settled.has(n)) ?? null;

    const active = await this.db
      .selectFrom("trips")
      .selectAll()
      .where("auto_id", "=", a.autoId)
      .where("status", "=", "active")
      .executeTakeFirst();

    const schedule = a.wasteSchedule as Record<string, WasteType[]>;

    return {
      auto: { id: a.autoId, registrationNumber: a.registrationNumber },
      route: {
        id: a.routeId,
        name: a.routeName,
        routeCode: a.routeCode,
        serviceableArea: JSON.parse(a.area),
        windowStart: a.windowStart.slice(0, 5),
        windowEnd: a.windowEnd.slice(0, 5),
        collectionDays: a.collectionDays,
      },
      today: {
        wasteTypes: schedule[String(weekday)] ?? [],
        passesTotal: a.passesPerDay,
        passesCompleted: completed,
        nextPassNumber: nextPass,
        isCollectionDay: a.collectionDays.includes(weekday),
      },
      activeTrip: active ? toTrip(active as unknown as TripRow) : null,
    };
  }

  /**
   * Starting pass n requires pass n−1 to be settled — completed, aborted, or
   * auto-marked skipped when its window elapsed unstarted (FR-DRV-02).
   */
  async start(userId: string, passNumber: number): Promise<Trip> {
    const a = await this.currentAssignment(userId);
    const serviceDate = serviceDateIST();

    if (passNumber > a.passesPerDay) {
      throw new HttpException(
        `This route runs ${a.passesPerDay} pass(es) per day`,
        HttpStatus.UNPROCESSABLE_ENTITY,
      );
    }

    const existingActive = await this.db
      .selectFrom("trips")
      .select("id")
      .where("auto_id", "=", a.autoId)
      .where("status", "=", "active")
      .executeTakeFirst();
    if (existingActive) {
      throw new HttpException("This auto is already on a trip", HttpStatus.CONFLICT);
    }

    if (passNumber > 1) {
      const previous = await this.db
        .selectFrom("route_pass_days")
        .select("status")
        .where("route_id", "=", a.routeId)
        .where("service_date", "=", serviceDate)
        .where("pass_number", "=", passNumber - 1)
        .executeTakeFirst();

      if (!previous || previous.status === "pending" || previous.status === "active") {
        throw new HttpException(
          `Finish pass ${passNumber - 1} before starting pass ${passNumber}`,
          HttpStatus.CONFLICT,
        );
      }
    }

    const already = await this.db
      .selectFrom("route_pass_days")
      .select("status")
      .where("route_id", "=", a.routeId)
      .where("service_date", "=", serviceDate)
      .where("pass_number", "=", passNumber)
      .executeTakeFirst();
    if (already && already.status !== "pending") {
      throw new HttpException(`Pass ${passNumber} is already ${already.status}`, HttpStatus.CONFLICT);
    }

    return this.db.transaction().execute(async (trx) => {
      const trip = await trx
        .insertInto("trips")
        .values({
          auto_id: a.autoId,
          driver_id: a.driverId,
          route_id: a.routeId,
          pass_number: passNumber,
          service_date: serviceDate,
        })
        .returningAll()
        .executeTakeFirstOrThrow();

      await trx
        .insertInto("route_pass_days")
        .values({
          route_id: a.routeId,
          service_date: serviceDate,
          pass_number: passNumber,
          status: "active",
          trip_id: trip.id,
        })
        .onConflict((oc) =>
          oc
            .columns(["route_id", "service_date", "pass_number"])
            .doUpdateSet({ status: "active", trip_id: trip.id, updated_at: new Date() }),
        )
        .execute();

      return toTrip(trip as unknown as TripRow);
    });
  }

  async end(
    tripId: string,
    reason: TripEndReason = "driver",
    distanceCoveredM?: number,
  ): Promise<Trip> {
    const trip = await this.db
      .selectFrom("trips")
      .selectAll()
      .where("id", "=", tripId)
      .executeTakeFirst();
    if (!trip) throw new HttpException("Trip not found", HttpStatus.NOT_FOUND);
    if (trip.status !== "active") {
      throw new HttpException(`Trip is already ${trip.status}`, HttpStatus.CONFLICT);
    }

    const status = reason === "admin" ? "aborted" : "completed";

    return this.db.transaction().execute(async (trx) => {
      const updated = await trx
        .updateTable("trips")
        .set({
          status,
          end_reason: reason,
          ended_at: new Date(),
          ...(distanceCoveredM !== undefined ? { distance_covered_m: distanceCoveredM } : {}),
        })
        .where("id", "=", tripId)
        .returningAll()
        .executeTakeFirstOrThrow();

      await trx
        .updateTable("route_pass_days")
        .set({ status, updated_at: new Date() })
        .where("route_id", "=", trip.route_id)
        .where("service_date", "=", trip.service_date)
        .where("pass_number", "=", trip.pass_number)
        .execute();

      return toTrip(updated as unknown as TripRow);
    });
  }

  async driverIdFor(userId: string): Promise<string> {
    const driver = await this.db
      .selectFrom("drivers")
      .select("id")
      .where("user_id", "=", userId)
      .executeTakeFirst();
    if (!driver) throw new HttpException("Not a driver", HttpStatus.FORBIDDEN);
    return driver.id;
  }

  async requireOwnedTrip(tripId: string, userId: string): Promise<void> {
    const owned = await this.db
      .selectFrom("trips as t")
      .innerJoin("drivers as d", "d.id", "t.driver_id")
      .select("t.id")
      .where("t.id", "=", tripId)
      .where("d.user_id", "=", userId)
      .executeTakeFirst();
    if (!owned) throw new HttpException("Not your trip", HttpStatus.FORBIDDEN);
  }

  /**
   * Closes out passes whose collection window has elapsed without a trip, so a
   * missed pass is visible as `skipped` rather than silently pending forever.
   */
  async markElapsedPassesSkipped(now = new Date()): Promise<number> {
    const serviceDate = serviceDateIST(now);
    const weekday = weekdayIST(now);
    const nowIstTime = new Date(now.getTime() + 5.5 * 3_600_000).toISOString().slice(11, 19);

    const result = await sql<{ route_id: string }>`
      WITH due AS (
        SELECT r.id AS route_id, gs.pass_number
        FROM routes r
        CROSS JOIN LATERAL generate_series(1, r.passes_per_day) AS gs(pass_number)
        WHERE ${weekday} = ANY (r.collection_days)
          AND r.window_end < ${nowIstTime}::time
      )
      INSERT INTO route_pass_days (route_id, service_date, pass_number, status)
      SELECT due.route_id, ${serviceDate}::date, due.pass_number, 'skipped'
      FROM due
      ON CONFLICT (route_id, service_date, pass_number) DO UPDATE
        SET status = 'skipped', updated_at = now()
        WHERE route_pass_days.status = 'pending'
      RETURNING route_id
    `.execute(this.db);

    return result.rows.length;
  }
}
