import { Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type { GeoJsonArea } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";

/** Postgres raises these as check_violation; the service maps them to HTTP. */
export const GEO_CONFLICT = {
  wardOverlap: /overlaps existing ward: (.+)$/,
  routeOutsideWard: /within its ward boundary/,
  routeOverlap: /overlaps existing route: (.+)$/,
} as const;

@Injectable()
export class GeoRepository {
  constructor(@Inject(DB) readonly db: Db) {}

  multi(area: GeoJsonArea) {
    return sql<string>`ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON(${JSON.stringify(area)}), 4326))`;
  }

  /** Returns the intersection with any overlapping ward, for the visual diff. */
  async overlapWith(
    boundary: GeoJsonArea,
    cityId: string,
    excludeWardId?: string,
  ): Promise<{ name: string; conflict: unknown } | null> {
    let query = this.db
      .selectFrom("wards")
      .select((eb) => [
        "name",
        sql<string>`ST_AsGeoJSON(ST_Intersection(boundary, ${this.multi(boundary)}))`.as(
          "conflict",
        ),
      ])
      .where("city_id", "=", cityId)
      .where("status", "=", "active")
      // Interior intersection, matching the database trigger: ST_Overlaps is
      // false for containment, which would let a nested ward through.
      .where(sql<boolean>`ST_Relate(boundary, ${this.multi(boundary)}, 'T********')`);

    if (excludeWardId) query = query.where("id", "!=", excludeWardId);

    const row = await query.executeTakeFirst();
    return row ? { name: row.name, conflict: JSON.parse(row.conflict) } : null;
  }

  /**
   * How much damage a boundary edit would do, surfaced before the save
   * (Clarifications CHK017).
   */
  async editImpact(
    wardId: string,
    boundary: GeoJsonArea,
  ): Promise<{ affectedHouseholds: number; routesOutsideNewBoundary: number }> {
    const households = await this.db
      .selectFrom("households")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .where("ward_id", "=", wardId)
      .where(sql<boolean>`NOT ST_Contains(${this.multi(boundary)}, house_geo)`)
      .executeTakeFirstOrThrow();

    const routes = await this.db
      .selectFrom("routes")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .where("ward_id", "=", wardId)
      .where(sql<boolean>`NOT ST_Within(serviceable_area, ${this.multi(boundary)})`)
      .executeTakeFirstOrThrow();

    return {
      affectedHouseholds: Number(households.count),
      routesOutsideNewBoundary: Number(routes.count),
    };
  }

  /** Households no longer inside their route go back to the review queue. */
  async reflagStrandedHouseholds(wardId: string): Promise<number> {
    const result = await sql<{ id: string }>`
      UPDATE households h
      SET route_id = NULL, mapping_status = 'pending_review', updated_at = now()
      WHERE h.ward_id = ${wardId}
        AND h.route_id IS NOT NULL
        AND NOT EXISTS (
          SELECT 1 FROM routes r
          WHERE r.id = h.route_id AND ST_Contains(r.serviceable_area, h.house_geo)
        )
      RETURNING h.id
    `.execute(this.db);
    return result.rows.length;
  }
}
