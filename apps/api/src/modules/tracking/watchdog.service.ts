import { Inject, Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { sql } from "kysely";
import type Redis from "ioredis";
import { DB, type Db } from "../../db/db.module";
import { REDIS } from "../../redis/redis.module";
import { IngestService, lastPingKey } from "./ingest.service";
import { TripsService } from "./trips.service";

/** A phone that stops reporting for this long is presumed to have died. */
const TRACKING_DROPPED_MS = 3 * 60_000;
/** Idle this long prompts the driver to confirm the trip is over (FR-DRV-08). */
const IDLE_PROMPT_MS = 30 * 60_000;
/** Idle and unreachable this long ends it without them (Clarifications CHK033). */
const IDLE_FORCE_END_MS = 45 * 60_000;

const SWEEP_INTERVAL_MS = 30_000;

export interface TrackingAlert {
  tripId: string;
  autoId: string;
  registrationNumber: string;
  routeName: string;
  wardId: string;
  silentForMs: number;
}

@Injectable()
export class WatchdogService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(WatchdogService.name);
  private timer?: NodeJS.Timeout;

  constructor(
    @Inject(DB) private readonly db: Db,
    @Inject(REDIS) private readonly redis: Redis,
    private readonly trips: TripsService,
    private readonly ingest: IngestService,
  ) {}

  onModuleInit(): void {
    this.timer = setInterval(() => {
      void this.sweep().catch((error: unknown) =>
        this.logger.error(`Watchdog sweep failed: ${String(error)}`),
      );
    }, SWEEP_INTERVAL_MS);
    // Timers must not hold the process open during shutdown or tests.
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  async sweep(now = new Date()): Promise<{ alerts: TrackingAlert[]; forceEnded: number }> {
    const alerts = await this.trackingDropped(now);
    const forceEnded = await this.forceEndAbandonedTrips(now);
    await this.trips.markElapsedPassesSkipped(now);
    return { alerts, forceEnded };
  }

  /**
   * Trips whose pings have stopped. Measured from server receipt, so a device
   * with a skewed clock cannot mask or fake a gap.
   */
  async trackingDropped(now = new Date()): Promise<TrackingAlert[]> {
    const active = await this.activeTrips();
    const alerts: TrackingAlert[] = [];

    for (const trip of active) {
      const last = Number((await this.redis.get(lastPingKey(trip.tripId))) ?? 0);
      // A trip that has never reported is measured from when it started.
      const reference = last || trip.startedMs;
      const silentForMs = now.getTime() - reference;
      if (silentForMs > TRACKING_DROPPED_MS) {
        alerts.push({ ...trip, silentForMs });
      }
    }
    return alerts;
  }

  private async forceEndAbandonedTrips(now: Date): Promise<number> {
    const active = await this.activeTrips();
    let ended = 0;

    for (const trip of active) {
      const last = Number((await this.redis.get(lastPingKey(trip.tripId))) ?? 0);
      const reference = last || trip.startedMs;
      const silentForMs = now.getTime() - reference;

      // The driver prompt at 30 minutes is the app's job; the backend only
      // steps in once the device is both idle and unreachable, because an
      // unreachable phone can never answer that prompt.
      if (silentForMs > IDLE_FORCE_END_MS) {
        await this.trips.end(trip.tripId, "auto_idle");
        const context = await this.ingest.contextFor(trip.tripId);
        if (context) await this.ingest.clearLiveState(context);
        ended += 1;
        this.logger.warn(
          `Force-ended trip ${trip.tripId}: no pings for ${Math.round(silentForMs / 60_000)} min`,
        );
      }
    }
    return ended;
  }

  /** True once the trip has been idle long enough to prompt the driver. */
  idlePromptDue(silentForMs: number): boolean {
    return silentForMs > IDLE_PROMPT_MS;
  }

  private async activeTrips() {
    return this.db
      .selectFrom("trips as t")
      .innerJoin("autos as a", "a.id", "t.auto_id")
      .innerJoin("routes as r", "r.id", "t.route_id")
      .select([
        "t.id as tripId",
        "t.auto_id as autoId",
        sql<number>`(extract(epoch from t.started_at) * 1000)::float8`.as("startedMs"),
        "a.registration_number as registrationNumber",
        "a.ward_id as wardId",
        "r.name as routeName",
      ])
      .where("t.status", "=", "active")
      .execute();
  }
}
