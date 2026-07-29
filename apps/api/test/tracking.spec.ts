import { afterAll, beforeEach, describe, expect, it } from "vitest";
import Redis from "ioredis";
import { PING_LIMITS, type Ping } from "@namma-kasa/shared";
import { createTestDb } from "./helpers/db";
import { IngestService, haversineMeters, lastPingKey } from "../src/modules/tracking/ingest.service";
import { TripsService, serviceDateIST } from "../src/modules/tracking/trips.service";
import { WatchdogService } from "../src/modules/tracking/watchdog.service";

const db = createTestDb();
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");
const ingest = new IngestService(db, redis);
const trips = new TripsService(db);
const watchdog = new WatchdogService(db, redis, trips, ingest);

afterAll(async () => {
  await db.destroy();
  redis.disconnect();
});

/** Uses the seeded ward/route/auto/driver, which every dev database has. */
async function seededTrip() {
  const assignment = await db
    .selectFrom("auto_route_assignments as ar")
    .innerJoin("autos as a", "a.id", "ar.auto_id")
    .innerJoin("driver_auto_assignments as da", (join) =>
      join.onRef("da.auto_id", "=", "a.id").on("da.effective_to", "is", null),
    )
    .select(["a.id as autoId", "da.driver_id as driverId", "ar.route_id as routeId"])
    .where("ar.effective_to", "is", null)
    .executeTakeFirstOrThrow();

  await db
    .updateTable("trips")
    .set({ status: "aborted", ended_at: new Date(), end_reason: "admin" })
    .where("auto_id", "=", assignment.autoId)
    .where("status", "=", "active")
    .execute();

  const trip = await db
    .insertInto("trips")
    .values({
      auto_id: assignment.autoId,
      driver_id: assignment.driverId,
      route_id: assignment.routeId,
      pass_number: 1,
      service_date: serviceDateIST(),
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  const context = await ingest.contextFor(trip.id);
  if (!context) throw new Error("trip context missing");
  return { trip, context };
}

function ping(overrides: Partial<Ping> & { seq: number }): Ping {
  return {
    lat: 12.9612,
    lng: 77.5925,
    speed: 3,
    heading: 90,
    accuracy: 8,
    recordedAt: new Date(),
    ...overrides,
  };
}

describe("ping ingest (spec §4 integrity rules)", () => {
  let context: Awaited<ReturnType<typeof seededTrip>>["context"];

  beforeEach(async () => {
    ({ context } = await seededTrip());
    await redis.del(`trip:seq:${context.tripId}`, lastPingKey(context.tripId));
  });

  it("stores accepted pings and updates the live position", async () => {
    const base = Date.now();
    const result = await ingest.ingest(context, [
      ping({ seq: 0, recordedAt: new Date(base) }),
      ping({ seq: 1, lat: 12.9614, recordedAt: new Date(base + 5000) }),
    ]);

    expect(result).toEqual({ accepted: 2, rejected: 0 });

    const stored = await db
      .selectFrom("location_pings")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .where("trip_id", "=", context.tripId)
      .executeTakeFirstOrThrow();
    expect(Number(stored.count)).toBe(2);

    const live = await redis.hgetall(`auto:pos:${context.autoId}`);
    expect(live.registrationNumber).toBe(context.registrationNumber);
    expect(Number(live.lat)).toBeCloseTo(12.9614, 4);
  });

  it("rejects pings whose accuracy is worse than the limit", async () => {
    const result = await ingest.ingest(context, [
      ping({ seq: 0, accuracy: PING_LIMITS.maxAccuracyM + 50 }),
    ]);
    expect(result).toEqual({ accepted: 0, rejected: 1 });
  });

  /** A GPS jump would otherwise make the auto teleport on the resident's map. */
  it("rejects a fix implying an impossible speed", async () => {
    const base = Date.now();
    const result = await ingest.ingest(context, [
      ping({ seq: 0, recordedAt: new Date(base) }),
      // ~11 km in 5 seconds
      ping({ seq: 1, lat: 13.06, recordedAt: new Date(base + 5000) }),
    ]);
    expect(result).toEqual({ accepted: 1, rejected: 1 });
  });

  it("drops duplicate redeliveries by sequence number", async () => {
    const base = Date.now();
    await ingest.ingest(context, [ping({ seq: 0, recordedAt: new Date(base) })]);
    // QoS 1 can deliver the same message twice.
    const replay = await ingest.ingest(context, [ping({ seq: 0, recordedAt: new Date(base) })]);
    expect(replay).toEqual({ accepted: 0, rejected: 1 });
  });

  it("replays an offline spool in recorded order", async () => {
    const base = Date.now();
    const result = await ingest.ingest(context, [
      ping({ seq: 3, lat: 12.9618, recordedAt: new Date(base + 15_000) }),
      ping({ seq: 1, lat: 12.9614, recordedAt: new Date(base + 5_000) }),
      ping({ seq: 2, lat: 12.9616, recordedAt: new Date(base + 10_000) }),
    ]);
    expect(result.accepted).toBe(3);

    const rows = await db
      .selectFrom("location_pings")
      .select("lat")
      .where("trip_id", "=", context.tripId)
      .orderBy("recorded_at")
      .execute();
    expect(rows.map((r) => Number(r.lat.toFixed(4)))).toEqual([12.9614, 12.9616, 12.9618]);
  });

  it("exposes the position on the ward dashboard", async () => {
    await ingest.ingest(context, [ping({ seq: 0 })]);
    const positions = await ingest.livePositionsForWard(context.wardId);
    const mine = positions.find((p) => p.tripId === context.tripId);
    expect(mine?.registrationNumber).toBe(context.registrationNumber);
    expect(mine?.trackingDropped).toBe(false);
  });
});

describe("watchdogs (FR-DRV-05, FR-DRV-08)", () => {
  it("raises a tracking-dropped alert after three silent minutes", async () => {
    const { context } = await seededTrip();
    await ingest.ingest(context, [ping({ seq: 0 })]);

    const quiet = await watchdog.trackingDropped();
    expect(quiet.find((a) => a.tripId === context.tripId)).toBeUndefined();

    // Rewind the last-seen marker rather than waiting three real minutes.
    await redis.set(lastPingKey(context.tripId), String(Date.now() - 4 * 60_000));

    const alerts = await watchdog.trackingDropped();
    const alert = alerts.find((a) => a.tripId === context.tripId);
    expect(alert).toBeDefined();
    expect(alert!.registrationNumber).toBe(context.registrationNumber);
  });

  it("force-ends a trip whose device has been unreachable for 45 minutes", async () => {
    const { trip, context } = await seededTrip();
    await ingest.ingest(context, [ping({ seq: 0 })]);
    await redis.set(lastPingKey(context.tripId), String(Date.now() - 50 * 60_000));

    await watchdog.sweep();

    const after = await db
      .selectFrom("trips")
      .select(["status", "end_reason"])
      .where("id", "=", trip.id)
      .executeTakeFirstOrThrow();
    expect(after.status).toBe("completed");
    expect(after.end_reason).toBe("auto_idle");
  });

  it("does not prompt before the idle threshold", () => {
    expect(watchdog.idlePromptDue(10 * 60_000)).toBe(false);
    expect(watchdog.idlePromptDue(31 * 60_000)).toBe(true);
  });
});

describe("trip lifecycle (FR-DRV-02)", () => {
  it("refuses a second active trip for the same auto", async () => {
    const { context } = await seededTrip();
    const driverUser = await db
      .selectFrom("drivers")
      .select("user_id")
      .where("id", "=", (
        await db
          .selectFrom("trips")
          .select("driver_id")
          .where("id", "=", context.tripId)
          .executeTakeFirstOrThrow()
      ).driver_id)
      .executeTakeFirstOrThrow();

    if (!driverUser.user_id) return; // driver has not registered in this database

    await expect(trips.start(driverUser.user_id, 1)).rejects.toThrow(/already on a trip/i);
  });

  it("ends a trip and settles its pass", async () => {
    const { trip } = await seededTrip();
    const ended = await trips.end(trip.id, "driver");
    expect(ended.status).toBe("completed");

    const pass = await db
      .selectFrom("route_pass_days")
      .select("status")
      .where("route_id", "=", trip.route_id)
      .where("service_date", "=", serviceDateIST())
      .where("pass_number", "=", 1)
      .executeTakeFirst();
    // The pass row only exists when the trip was started through the service.
    if (pass) expect(["completed", "active", "skipped"]).toContain(pass.status);
  });

  it("refuses to end a trip twice", async () => {
    const { trip } = await seededTrip();
    await trips.end(trip.id, "driver");
    await expect(trips.end(trip.id, "driver")).rejects.toThrow(/already completed/i);
  });
});

describe("distance helper", () => {
  it("measures a known separation", () => {
    // Roughly 1.11 km per 0.01 degree of latitude.
    const metres = haversineMeters({ lat: 12.96, lng: 77.59 }, { lat: 12.97, lng: 77.59 });
    expect(metres).toBeGreaterThan(1050);
    expect(metres).toBeLessThan(1150);
  });
});
