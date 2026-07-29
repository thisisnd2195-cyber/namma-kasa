import { Inject, Injectable, Logger } from "@nestjs/common";
import type Redis from "ioredis";
import { PING_LIMITS, type Ping } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";
import { REDIS } from "../../redis/redis.module";

const EARTH_RADIUS_M = 6_371_000;

/** Great-circle distance; good enough at the scale of consecutive GPS pings. */
export function haversineMeters(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const lat1 = toRad(a.lat);
  const lat2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 + Math.sin(dLng / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2);
  return 2 * EARTH_RADIUS_M * Math.asin(Math.sqrt(h));
}

export interface TripContext {
  tripId: string;
  autoId: string;
  routeId: string;
  passNumber: number;
  registrationNumber: string;
  routeName: string;
  wardId: string;
}

export interface IngestResult {
  accepted: number;
  rejected: number;
}

/**
 * Called for each accepted position. Kept as a callback so ingest does not
 * depend on the resident or notification modules, which both depend on it.
 */
export type PositionListener = (
  context: TripContext,
  position: { lat: number; lng: number; heading: number | null; at: Date },
) => void | Promise<void>;

/** Redis keys. Live state is deliberately not in Postgres — it expires. */
export const liveKey = (autoId: string): string => `auto:pos:${autoId}`;
export const wardGeoKey = (wardId: string): string => `ward:autos:${wardId}`;
export const lastPingKey = (tripId: string): string => `trip:lastping:${tripId}`;
export const seqKey = (tripId: string): string => `trip:seq:${tripId}`;

@Injectable()
export class IngestService {
  private readonly logger = new Logger(IngestService.name);

  private readonly listeners: PositionListener[] = [];

  constructor(
    @Inject(DB) private readonly db: Db,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  onPosition(listener: PositionListener): void {
    this.listeners.push(listener);
  }

  async contextFor(tripId: string): Promise<TripContext | null> {
    const row = await this.db
      .selectFrom("trips as t")
      .innerJoin("autos as a", "a.id", "t.auto_id")
      .innerJoin("routes as r", "r.id", "t.route_id")
      .select([
        "t.id as tripId",
        "t.auto_id as autoId",
        "t.route_id as routeId",
        "t.pass_number as passNumber",
        "a.registration_number as registrationNumber",
        "a.ward_id as wardId",
        "r.name as routeName",
      ])
      .where("t.id", "=", tripId)
      .where("t.status", "=", "active")
      .executeTakeFirst();
    return row ?? null;
  }

  /**
   * Validates, stores and fans out a batch. Rejected pings are counted rather
   * than stored: a bad fix is noise, and keeping it would let the auto appear
   * to teleport on the resident's map.
   */
  async ingest(context: TripContext, pings: Ping[]): Promise<IngestResult> {
    const ordered = [...pings].sort(
      (a, b) => a.recordedAt.getTime() - b.recordedAt.getTime(),
    );

    const lastSeq = Number((await this.redis.get(seqKey(context.tripId))) ?? -1);
    const previous = await this.lastAcceptedPosition(context.tripId);

    const accepted: Ping[] = [];
    let rejected = 0;
    let reference = previous;
    let highestSeq = lastSeq;

    for (const ping of ordered) {
      // QoS 1 can redeliver; the per-trip counter makes duplicates cheap to drop.
      if (ping.seq <= lastSeq) {
        rejected += 1;
        continue;
      }
      if ((ping.accuracy ?? 0) > PING_LIMITS.maxAccuracyM) {
        rejected += 1;
        continue;
      }
      if (reference && this.impliesImpossibleSpeed(reference, ping)) {
        rejected += 1;
        continue;
      }

      accepted.push(ping);
      reference = { lat: ping.lat, lng: ping.lng, at: ping.recordedAt };
      highestSeq = Math.max(highestSeq, ping.seq);
    }

    if (accepted.length === 0) return { accepted: 0, rejected };

    await this.db
      .insertInto("location_pings")
      .values(
        accepted.map((p) => ({
          trip_id: context.tripId,
          auto_id: context.autoId,
          lat: p.lat,
          lng: p.lng,
          speed: p.speed ?? null,
          heading: p.heading ?? null,
          accuracy_m: p.accuracy ?? null,
          recorded_at: p.recordedAt,
        })),
      )
      .execute();

    const latest = accepted[accepted.length - 1];
    await this.redis
      .multi()
      .hset(liveKey(context.autoId), {
        tripId: context.tripId,
        autoId: context.autoId,
        registrationNumber: context.registrationNumber,
        routeId: context.routeId,
        routeName: context.routeName,
        passNumber: String(context.passNumber),
        lat: String(latest.lat),
        lng: String(latest.lng),
        heading: latest.heading == null ? "" : String(latest.heading),
        at: latest.recordedAt.toISOString(),
      })
      .expire(liveKey(context.autoId), 60)
      .geoadd(wardGeoKey(context.wardId), latest.lng, latest.lat, context.autoId)
      // received_at, not recorded_at: a device with a wrong clock must not look
      // like it has stopped reporting (FR-DRV-05).
      .set(lastPingKey(context.tripId), String(Date.now()))
      .set(seqKey(context.tripId), String(highestSeq), "EX", 86_400)
      .exec();

    // Downstream work (collection events, geofencing, live fan-out) must never
    // fail the ingest itself — a dropped notification is recoverable, a lost
    // ping is not.
    for (const listener of this.listeners) {
      try {
        await listener(context, {
          lat: latest.lat,
          lng: latest.lng,
          heading: latest.heading ?? null,
          at: latest.recordedAt,
        });
      } catch (error) {
        this.logger.warn(`Position listener failed: ${String(error)}`);
      }
    }

    return { accepted: accepted.length, rejected };
  }

  private impliesImpossibleSpeed(
    previous: { lat: number; lng: number; at: Date },
    ping: Ping,
  ): boolean {
    const seconds = (ping.recordedAt.getTime() - previous.at.getTime()) / 1000;
    if (seconds <= 0) return false;
    const kmh = (haversineMeters(previous, ping) / seconds) * 3.6;
    return kmh > PING_LIMITS.maxSpeedKmh;
  }

  private async lastAcceptedPosition(
    tripId: string,
  ): Promise<{ lat: number; lng: number; at: Date } | null> {
    const row = await this.db
      .selectFrom("location_pings")
      .select(["lat", "lng", "recorded_at"])
      .where("trip_id", "=", tripId)
      .orderBy("recorded_at", "desc")
      .limit(1)
      .executeTakeFirst();
    return row ? { lat: row.lat, lng: row.lng, at: row.recorded_at } : null;
  }

  /** Live positions for a ward dashboard, straight from Redis. */
  async livePositionsForWard(wardId: string) {
    const autoIds = await this.redis.zrange(wardGeoKey(wardId), 0, -1);
    if (autoIds.length === 0) return [];

    const entries = await Promise.all(
      autoIds.map(async (autoId) => {
        const data = await this.redis.hgetall(liveKey(autoId));
        if (!data.tripId) {
          await this.redis.zrem(wardGeoKey(wardId), autoId);
          return null;
        }
        const lastPing = Number((await this.redis.get(lastPingKey(data.tripId))) ?? 0);
        return {
          tripId: data.tripId,
          autoId: data.autoId,
          registrationNumber: data.registrationNumber,
          routeId: data.routeId,
          routeName: data.routeName,
          passNumber: Number(data.passNumber),
          lat: Number(data.lat),
          lng: Number(data.lng),
          heading: data.heading === "" ? null : Number(data.heading),
          at: new Date(data.at),
          trackingDropped: Date.now() - lastPing > 3 * 60_000,
        };
      }),
    );

    return entries.filter((entry): entry is NonNullable<typeof entry> => entry !== null);
  }

  async clearLiveState(context: TripContext): Promise<void> {
    await this.redis
      .multi()
      .del(liveKey(context.autoId), lastPingKey(context.tripId), seqKey(context.tripId))
      .zrem(wardGeoKey(context.wardId), context.autoId)
      .exec();
  }
}
