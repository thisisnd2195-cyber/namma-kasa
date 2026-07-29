import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type { AccessClaims } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";

const AGING_HOURS = 48;

@Injectable()
export class HouseholdsService {
  constructor(@Inject(DB) private readonly db: Db) {}

  /**
   * Households the system could not place. Items older than 48 h are flagged so
   * a resident is not left in limbo indefinitely (Clarifications CHK020).
   */
  async reviewQueue(wardId: string) {
    const rows = await this.db
      .selectFrom("households")
      .select([
        "id",
        "full_name",
        "address_line",
        "landmark",
        sql<number>`ST_Y(house_geo)`.as("lat"),
        sql<number>`ST_X(house_geo)`.as("lng"),
        "ward_id",
        // Epoch millis, so the aging comparison does not depend on how the
        // driver hands back timestamps.
        sql<number>`extract(epoch from created_at) * 1000`.as("created_ms"),
      ])
      .where("mapping_status", "=", "pending_review")
      .$if(Boolean(wardId), (qb) => qb.where("ward_id", "=", wardId))
      .orderBy("created_at")
      .execute();

    const threshold = Date.now() - AGING_HOURS * 3_600_000;
    return rows.map((row) => ({
      id: row.id,
      fullName: row.full_name,
      addressLine: row.address_line,
      landmark: row.landmark,
      pin: { lat: row.lat, lng: row.lng },
      wardId: row.ward_id,
      createdAt: new Date(row.created_ms),
      aging: row.created_ms < threshold,
    }));
  }

  /** Manual placement by an admin, recorded as such so it is not re-derived. */
  async assignRoute(householdId: string, routeId: string, actor: AccessClaims) {
    const household = await this.db
      .selectFrom("households")
      .select(["id", "ward_id"])
      .where("id", "=", householdId)
      .executeTakeFirst();
    if (!household) throw new HttpException("Household not found", HttpStatus.NOT_FOUND);

    const route = await this.db
      .selectFrom("routes")
      .select(["id", "ward_id"])
      .where("id", "=", routeId)
      .executeTakeFirst();
    if (!route) throw new HttpException("Route not found", HttpStatus.NOT_FOUND);

    if (actor.role === "ward_admin" && route.ward_id !== actor.wardId) {
      throw new HttpException("Outside your ward", HttpStatus.FORBIDDEN);
    }

    await this.db
      .updateTable("households")
      .set({
        route_id: routeId,
        ward_id: route.ward_id,
        mapping_status: "admin_corrected",
        updated_at: new Date(),
      })
      .where("id", "=", householdId)
      .execute();

    return { id: householdId, routeId, mappingStatus: "admin_corrected" as const };
  }
}
