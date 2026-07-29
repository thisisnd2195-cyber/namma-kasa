import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import {
  COLLECTION_PROXIMITY_M,
  type Household,
  type ResidentHome,
  type WasteType,
} from "@namma-kasa/shared";
import type { updateHouseholdSchema, residentSettingsSchema } from "@namma-kasa/shared";
import type { z } from "zod";
import { RollupsService } from "../compliance/rollups.service";
import { DB, type Db } from "../../db/db.module";
import { HouseholdMappingService } from "../geo/household-mapping.service";
import { IngestService, haversineMeters } from "../tracking/ingest.service";
import { serviceDateIST, weekdayIST } from "../tracking/trips.service";

type UpdateHousehold = z.infer<typeof updateHouseholdSchema>;
type ResidentSettings = z.infer<typeof residentSettingsSchema>;

@Injectable()
export class ResidentService {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly mapping: HouseholdMappingService,
    private readonly ingest: IngestService,
    private readonly rollups: RollupsService,
  ) {}

  private householdQuery() {
    return this.db
      .selectFrom("households")
      .select([
        "id",
        "user_id",
        "full_name",
        "address_line",
        "landmark",
        sql<number>`ST_Y(house_geo)`.as("lat"),
        sql<number>`ST_X(house_geo)`.as("lng"),
        "ward_id",
        "route_id",
        "mapping_status",
        "notification_radius_m",
      ]);
  }

  async householdFor(userId: string): Promise<Household> {
    const row = await this.householdQuery().where("user_id", "=", userId).executeTakeFirst();
    if (!row) throw new HttpException("No household registered", HttpStatus.NOT_FOUND);
    return {
      id: row.id,
      fullName: row.full_name,
      addressLine: row.address_line,
      landmark: row.landmark,
      pin: { lat: row.lat, lng: row.lng },
      wardId: row.ward_id,
      routeId: row.route_id,
      mappingStatus: row.mapping_status,
      notificationRadiusM: row.notification_radius_m,
    };
  }

  /**
   * Everything the resident's home screen needs in one call: who serves them,
   * when, what to put out, and where the auto is right now.
   */
  async home(userId: string): Promise<ResidentHome> {
    const household = await this.householdFor(userId);

    if (!household.routeId) {
      // Pin fell outside every route; the Ward Admin has to place it.
      return {
        household,
        route: null,
        servingAutos: [],
        currentPass: null,
        lastCollectedAt: null,
        canRateToday: false,
        missedToday: false,
      };
    }

    const route = await this.db
      .selectFrom("routes")
      .select([
        "id",
        "name",
        sql<string>`window_start::text`.as("windowStart"),
        sql<string>`window_end::text`.as("windowEnd"),
        "passes_per_day",
        "collection_days",
        "waste_type_schedule",
      ])
      .where("id", "=", household.routeId)
      .executeTakeFirstOrThrow();

    const weekday = weekdayIST();
    const schedule = route.waste_type_schedule as Record<string, WasteType[]>;

    const activeTrips = await this.db
      .selectFrom("trips as t")
      .innerJoin("autos as a", "a.id", "t.auto_id")
      .select([
        "t.id as tripId",
        "t.auto_id as autoId",
        "t.pass_number as passNumber",
        "a.registration_number as registrationNumber",
      ])
      .where("t.route_id", "=", household.routeId)
      .where("t.status", "=", "active")
      .execute();

    const positions = household.wardId
      ? await this.ingest.livePositionsForWard(household.wardId)
      : [];

    const servingAutos = activeTrips.flatMap((trip) => {
      const position = positions.find((p) => p.tripId === trip.tripId);
      if (!position) return [];
      return [
        {
          tripId: trip.tripId,
          registrationNumber: trip.registrationNumber,
          passNumber: trip.passNumber,
          lat: position.lat,
          lng: position.lng,
          heading: position.heading,
          at: position.at,
          distanceM: Math.round(haversineMeters(household.pin, position)),
        },
      ];
    });

    const lastCollection = await this.db
      .selectFrom("household_collections")
      .select([
        sql<number>`(extract(epoch from detected_at) * 1000)::float8`.as("detectedMs"),
        sql<string>`detected_at::date::text`.as("collectionDate"),
      ])
      .where("household_id", "=", household.id)
      .orderBy("detected_at", "desc")
      .executeTakeFirst();

    const today = serviceDateIST();
    const ratedToday = await this.db
      .selectFrom("ratings")
      .select("id")
      .where("household_id", "=", household.id)
      .where("collection_date", "=", today)
      .executeTakeFirst();

    return {
      household,
      route: {
        id: route.id,
        name: route.name,
        windowStart: route.windowStart.slice(0, 5),
        windowEnd: route.windowEnd.slice(0, 5),
        passesPerDay: route.passes_per_day,
        todayWasteTypes: schedule[String(weekday)] ?? [],
        isCollectionDay: route.collection_days.includes(weekday),
      },
      servingAutos,
      currentPass: activeTrips[0]?.passNumber ?? null,
      lastCollectedAt: lastCollection ? new Date(lastCollection.detectedMs) : null,
      // Rating is offered only once the auto has actually been past today.
      canRateToday:
        !ratedToday && lastCollection?.collectionDate === today,
      missedToday: await this.rollups.missedForHousehold(household.id),
    };
  }

  async updateHousehold(userId: string, input: UpdateHousehold): Promise<Household> {
    const current = await this.householdFor(userId);

    let mapping: { wardId: string | null; routeId: string | null; status: string } | null = null;
    if (input.pin) {
      const resolved = await this.mapping.resolve(input.pin);
      mapping = resolved;
    }

    await this.db
      .updateTable("households")
      .set({
        ...(input.fullName ? { full_name: input.fullName } : {}),
        ...(input.addressLine ? { address_line: input.addressLine } : {}),
        ...(input.landmark !== undefined ? { landmark: input.landmark ?? null } : {}),
        ...(input.pin
          ? {
              house_geo: sql<string>`ST_SetSRID(ST_MakePoint(${input.pin.lng}, ${input.pin.lat}), 4326)`,
              ward_id: mapping!.wardId,
              route_id: mapping!.routeId,
              mapping_status: mapping!.status as Household["mappingStatus"],
            }
          : {}),
        updated_at: new Date(),
      })
      .where("id", "=", current.id)
      .execute();

    return this.householdFor(userId);
  }

  async updateSettings(userId: string, input: ResidentSettings): Promise<Household> {
    const household = await this.householdFor(userId);
    if (input.notificationRadiusM !== undefined) {
      await this.db
        .updateTable("households")
        .set({ notification_radius_m: input.notificationRadiusM, updated_at: new Date() })
        .where("id", "=", household.id)
        .execute();
    }
    if (input.locale) {
      await this.db
        .updateTable("users")
        .set({ locale: input.locale, updated_at: new Date() })
        .where("id", "=", userId)
        .execute();
    }
    return this.householdFor(userId);
  }

  /**
   * Records that an auto came close enough to a house to have served it. This
   * is what makes "last collected" a fact rather than a claim — nobody presses
   * anything, and the evidence is the GPS trail (Clarifications CHK002).
   *
   * Unique on (household, trip), so repeated passes within one trip record once.
   */
  async recordCollectionsNear(
    tripId: string,
    routeId: string,
    passNumber: number,
    position: { lat: number; lng: number },
  ): Promise<string[]> {
    const point = sql`ST_SetSRID(ST_MakePoint(${position.lng}, ${position.lat}), 4326)::geography`;

    const rows = await sql<{ household_id: string }>`
      INSERT INTO household_collections (household_id, trip_id, route_id, pass_number)
      SELECT h.id, ${tripId}::uuid, ${routeId}::uuid, ${passNumber}
      FROM households h
      WHERE h.route_id = ${routeId}::uuid
        AND ST_DWithin(h.house_geo::geography, ${point}, ${COLLECTION_PROXIMITY_M})
      ON CONFLICT (household_id, trip_id) DO NOTHING
      RETURNING household_id
    `.execute(this.db);

    return rows.rows.map((row) => row.household_id);
  }
}
