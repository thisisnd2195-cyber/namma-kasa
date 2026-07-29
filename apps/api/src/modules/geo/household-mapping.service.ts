import { Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type { LatLng, MappingStatus } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";

export interface HouseholdMapping {
  wardId: string | null;
  routeId: string | null;
  status: MappingStatus;
}

@Injectable()
export class HouseholdMappingService {
  constructor(@Inject(DB) private readonly db: Db) {}

  /**
   * Derives ward and route from the house pin by point-in-polygon (FR-AUTH-08).
   * Route areas cannot overlap within a ward (FR-ROUTE-05), so at most one
   * route can match — no tie-breaking needed. A pin that resolves to no route
   * lands in the Ward Admin review queue rather than being guessed at.
   */
  async resolve(pin: LatLng): Promise<HouseholdMapping> {
    const point = sql<string>`ST_SetSRID(ST_MakePoint(${pin.lng}, ${pin.lat}), 4326)`;

    const ward = await this.db
      .selectFrom("wards")
      .select("id")
      .where("status", "=", "active")
      .where(sql<boolean>`ST_Contains(boundary, ${point})`)
      .executeTakeFirst();

    if (!ward) return { wardId: null, routeId: null, status: "pending_review" };

    const route = await this.db
      .selectFrom("routes")
      .select("id")
      .where("ward_id", "=", ward.id)
      .where(sql<boolean>`ST_Contains(serviceable_area, ${point})`)
      .executeTakeFirst();

    return {
      wardId: ward.id,
      routeId: route?.id ?? null,
      status: route ? "auto" : "pending_review",
    };
  }
}
