import { Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type Redis from "ioredis";
import { DB, type Db } from "../../db/db.module";
import { REDIS } from "../../redis/redis.module";
import { serviceDateIST } from "../tracking/trips.service";

export interface ProximityHit {
  householdId: string;
  userId: string;
  locale: "en" | "kn";
  distanceM: number;
  radiusM: number;
}

/**
 * Dedup is per household per *pass*, not per trip. Two autos can serve one pass
 * of a route (FR-FLEET-02), and a resident should be told once that collection
 * is coming — not once per vehicle (Clarifications CHK031).
 */
export const proximityDedupKey = (
  householdId: string,
  routeId: string,
  serviceDate: string,
  passNumber: number,
): string => `prox:${householdId}:${routeId}:${serviceDate}:${passNumber}`;

@Injectable()
export class GeofenceService {
  constructor(
    @Inject(DB) private readonly db: Db,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  /**
   * Households on this route whose own alert radius the auto has just entered
   * and who have not already been told about this pass.
   *
   * Each household chooses its own radius, so the search is per-household
   * rather than one fixed ring around the auto.
   */
  async hitsFor(
    routeId: string,
    passNumber: number,
    position: { lat: number; lng: number },
    now = new Date(),
  ): Promise<ProximityHit[]> {
    const serviceDate = serviceDateIST(now);
    const point = sql`ST_SetSRID(ST_MakePoint(${position.lng}, ${position.lat}), 4326)::geography`;

    const candidates = await sql<{
      household_id: string;
      user_id: string;
      locale: "en" | "kn";
      distance_m: number;
      radius_m: number;
    }>`
      SELECT h.id AS household_id,
             h.user_id,
             u.locale,
             ST_Distance(h.house_geo::geography, ${point})::float8 AS distance_m,
             h.notification_radius_m AS radius_m
      FROM households h
      JOIN users u ON u.id = h.user_id
      WHERE h.route_id = ${routeId}::uuid
        AND u.status = 'active'
        AND ST_DWithin(h.house_geo::geography, ${point}, h.notification_radius_m)
    `.execute(this.db);

    const hits: ProximityHit[] = [];
    for (const row of candidates.rows) {
      const key = proximityDedupKey(row.household_id, routeId, serviceDate, passNumber);
      // SET NX is the whole dedup: first writer wins, and the key outlives the
      // collection day so a late second pass cannot re-alert for the first.
      const claimed = await this.redis.set(key, "1", "EX", 36 * 3600, "NX");
      if (claimed !== "OK") continue;

      hits.push({
        householdId: row.household_id,
        userId: row.user_id,
        locale: row.locale,
        distanceM: Math.round(row.distance_m),
        radiusM: row.radius_m,
      });
    }
    return hits;
  }
}
