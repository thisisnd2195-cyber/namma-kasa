import { Inject, Injectable } from "@nestjs/common";
import { sql, type RawBuilder } from "kysely";
import type Redis from "ioredis";
import { DB, type Db } from "../../db/db.module";
import { REDIS } from "../../redis/redis.module";
import { serviceDateIST as serviceDate } from "../tracking/trips.service";

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

/**
 * "Arrived at your street" is a second, closer alert (FR-NOTIF-03), so it needs
 * its own dedup key. Sharing the proximity key would mean whichever fired first
 * suppressed the other, and the resident would get one alert at an arbitrary
 * distance instead of a heads-up followed by a now-or-never.
 */
export const arrivalDedupKey = (
  householdId: string,
  routeId: string,
  serviceDate: string,
  passNumber: number,
): string => `arrive:${householdId}:${routeId}:${serviceDate}:${passNumber}`;

/** FR-NOTIF-03: close enough that the resident should be walking out now. */
export const ARRIVAL_RADIUS_M = 75;

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
    return this.claim(
      // Each household chooses its own radius, so the ring is per row.
      await this.within(routeId, position, sql`h.notification_radius_m`),
      (householdId) => proximityDedupKey(householdId, routeId, serviceDate(now), passNumber),
    );
  }

  /**
   * Households the auto has just pulled up to (FR-NOTIF-03). A fixed ring, not
   * the household's own radius: this alert means "it is here", which is the
   * same distance for everybody.
   */
  async arrivalsFor(
    routeId: string,
    passNumber: number,
    position: { lat: number; lng: number },
    now = new Date(),
  ): Promise<ProximityHit[]> {
    return this.claim(
      await this.within(routeId, position, sql.lit(ARRIVAL_RADIUS_M)),
      (householdId) => arrivalDedupKey(householdId, routeId, serviceDate(now), passNumber),
    );
  }

  /** Active households on the route inside `radius` metres of the auto. */
  private async within(
    routeId: string,
    position: { lat: number; lng: number },
    radius: RawBuilder<number>,
  ) {
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
        AND ST_DWithin(h.house_geo::geography, ${point}, ${radius})
    `.execute(this.db);

    return candidates.rows;
  }

  /** Keeps only the households not already told, under the given key. */
  private async claim(
    rows: {
      household_id: string;
      user_id: string;
      locale: "en" | "kn";
      distance_m: number;
      radius_m: number;
    }[],
    keyFor: (householdId: string) => string,
  ): Promise<ProximityHit[]> {
    const hits: ProximityHit[] = [];
    for (const row of rows) {
      // SET NX is the whole dedup: first writer wins, and the key outlives the
      // collection day so a late second pass cannot re-alert for the first.
      const claimed = await this.redis.set(keyFor(row.household_id), "1", "EX", 36 * 3600, "NX");
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
