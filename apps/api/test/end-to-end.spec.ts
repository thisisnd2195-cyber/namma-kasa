import { createServer, type Server } from "node:http";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ConfigService } from "@nestjs/config";
import Redis from "ioredis";
import mqtt from "mqtt";
import { WebSocket } from "ws";
import { sql } from "kysely";
import { createTestDb } from "./helpers/db";
import { DegradationService } from "../src/modules/tracking/degradation";
import { IngestService, lastPingKey, seqKey } from "../src/modules/tracking/ingest.service";
import { LiveGateway } from "../src/modules/tracking/live.gateway";
import { MqttConsumer } from "../src/modules/tracking/mqtt.consumer";
import { TokensService } from "../src/modules/auth/tokens.service";
import { GeofenceService, proximityDedupKey } from "../src/modules/notify/geofence.service";
import { NotifyService } from "../src/modules/notify/notify.service";
import type { PushMessage, PushSender } from "../src/modules/notify/push-sender";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

/**
 * Constitution V names two flows that MUST have integration coverage before
 * release: trip tracking and proximity notification, end to end.
 *
 * Every component below is separately unit-tested and passes. What this file
 * covers is the seam between them — the driver's phone publishing over MQTT at
 * one end, and a resident's WebSocket frame plus a queued push at the other.
 * Both junction pieces (MqttConsumer, LiveGateway) had no test at all, and the
 * last three defects in this project all lived in exactly that kind of gap.
 */
const JWT_SECRET = "test-secret-for-end-to-end";
const MQTT_URL = process.env.MQTT_URL ?? "mqtt://localhost:1883";
const REDIS_URL = process.env.REDIS_URL ?? "redis://localhost:6379";

const db = createTestDb();
const redis = new Redis(REDIS_URL);

/**
 * Ingest drops any ping whose seq is not greater than the last one seen for
 * the trip, so the counter has to be monotonic across the whole file. A
 * wrapping value (Date.now() % n) silently loses pings.
 */
let seq = Date.now() % 1_000_000;
const nextSeq = () => ++seq;

class RecordingPushSender implements PushSender {
  readonly sent: PushMessage[] = [];
  async send(message: PushMessage) {
    this.sent.push(message);
    return { delivered: message.tokens.length, failedTokens: [] };
  }
}

/** Enough ConfigService for the pieces under test; nothing boots the app. */
const SETTINGS: Record<string, unknown> = {
  JWT_SECRET,
  MQTT_URL,
  MQTT_USERNAME: "namma-kasa-ingest",
  MQTT_PASSWORD: "devpassword",
};

const config = {
  // The real ConfigService takes a default as the second argument, and
  // accessTtlSec relies on it — dropping it yields NaN, not a fallback.
  get: (key: string, fallback?: unknown) => SETTINGS[key] ?? fallback,
  getOrThrow: (key: string) => {
    const value = SETTINGS[key];
    if (value === undefined) throw new Error(`missing ${key}`);
    return value;
  },
} as unknown as ConfigService;

const tokens = new TokensService(db, config);
const push = new RecordingPushSender();
const notify = new NotifyService(db, push);
const ingest = new IngestService(db, redis);
const geofence = new GeofenceService(db, redis);
const gateway = new LiveGateway(tokens, config, new DegradationService(redis));
const consumer = new MqttConsumer(config, ingest);

let http: Server;
let port: number;
let fixture: {
  tripId: string;
  routeId: string;
  autoId: string;
  registrationNumber: string;
  passNumber: number;
  householdId: string;
  residentUserId: string;
  lat: number;
  lng: number;
};

/** An active trip on a route that has a household sitting on it. */
async function activeTripWithResident() {
  const row = await db
    .selectFrom("trips as t")
    .innerJoin("autos as a", "a.id", "t.auto_id")
    .innerJoin("households as h", "h.route_id", "t.route_id")
    .innerJoin("users as u", "u.id", "h.user_id")
    .select([
      "t.id as tripId",
      "t.route_id as routeId",
      "t.auto_id as autoId",
      "t.pass_number as passNumber",
      "a.registration_number as registrationNumber",
      "h.id as householdId",
      "u.id as residentUserId",
      (eb) => eb.fn<number>("ST_Y", ["h.house_geo"]).as("lat"),
      (eb) => eb.fn<number>("ST_X", ["h.house_geo"]).as("lng"),
    ])
    .where("t.status", "=", "active")
    .where("u.status", "=", "active")
    .executeTakeFirst();

  if (row) return { ...row, routeId: row.routeId! };

  // No fixture matched, so build one from an existing route and household.
  const seed = await db
    .selectFrom("households as h")
    .innerJoin("routes as r", "r.id", "h.route_id")
    .innerJoin("autos as a", "a.ward_id", "r.ward_id")
    .innerJoin("users as u", "u.id", "h.user_id")
    .select([
      "h.id as householdId",
      "h.route_id as routeId",
      "a.id as autoId",
      "a.registration_number as registrationNumber",
      "u.id as residentUserId",
      (eb) => eb.fn<number>("ST_Y", ["h.house_geo"]).as("lat"),
      (eb) => eb.fn<number>("ST_X", ["h.house_geo"]).as("lng"),
    ])
    .where("u.status", "=", "active")
    .executeTakeFirstOrThrow();

  await db
    .updateTable("trips")
    .set({ status: "completed" })
    .where("auto_id", "=", seed.autoId)
    .where("status", "=", "active")
    .execute();

  const driver = await db
    .selectFrom("drivers")
    .select("id")
    .where("user_id", "is not", null)
    .executeTakeFirstOrThrow();

  const trip = await db
    .insertInto("trips")
    .values({
      route_id: seed.routeId!,
      auto_id: seed.autoId,
      driver_id: driver.id,
      pass_number: 1,
      service_date: serviceDateIST(),
      status: "active",
      started_at: new Date(),
    })
    .returning(["id", "pass_number"])
    .executeTakeFirstOrThrow();

  return {
    ...seed,
    routeId: seed.routeId!,
    tripId: trip.id,
    passNumber: trip.pass_number,
  };
}

beforeAll(async () => {
  fixture = await activeTripWithResident();

  // The same wiring app.module builds: every accepted position fans out to the
  // resident's socket and to the proximity check.
  ingest.onPosition((context, position) => {
    gateway.broadcastPosition(context.routeId, {
      type: "position",
      tripId: context.tripId,
      registrationNumber: context.registrationNumber,
      passNumber: context.passNumber,
      lat: position.lat,
      lng: position.lng,
      heading: position.heading,
      at: position.at,
    });
  });

  ingest.onPosition(async (context, position) => {
    const hits = await geofence.hitsFor(context.routeId, context.passNumber, position);
    for (const hit of hits) {
      await notify.queueProximity({
        userId: hit.userId,
        locale: hit.locale,
        distanceM: hit.distanceM,
        wasteTypes: [],
        routeId: context.routeId,
        tripId: context.tripId,
        dedupKey: proximityDedupKey(
          hit.householdId,
          context.routeId,
          serviceDateIST(),
          context.passNumber,
        ),
      });
    }
  });

  // Ingest keeps the highest seq per trip in Redis, and it outlives the test
  // run. Without clearing it a fresh run starts below the stored value and
  // every ping is dropped as a duplicate.
  await redis.del(seqKey(fixture.tripId), lastPingKey(fixture.tripId));

  http = createServer();
  gateway.attach(http);
  await new Promise<void>((resolve) => http.listen(0, resolve));
  port = (http.address() as { port: number }).port;

  await consumer.onModuleInit();
});

afterAll(async () => {
  await consumer.onModuleDestroy();
  gateway.onModuleDestroy();
  await new Promise<void>((resolve) => http.close(() => resolve()));
  await db.destroy();
  redis.disconnect();
});

/** A resident token scoped to their own route, as auth.service issues. */
function residentToken(routeId: string) {
  return tokens.signAccess({
    sub: fixture.residentUserId,
    role: "resident",
    wardId: null,
    routeId,
    deviceId: null,
  });
}

function openSocket(token: string, routeId: string) {
  return new WebSocket(`ws://127.0.0.1:${port}/v1/live?token=${token}&route_id=${routeId}`);
}

/** Resolves with the first frame, or null if none arrives in time. */
function firstFrame(socket: WebSocket, timeoutMs = 8_000): Promise<Record<string, unknown> | null> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => resolve(null), timeoutMs);
    socket.once("message", (data) => {
      clearTimeout(timer);
      resolve(JSON.parse(data.toString()) as Record<string, unknown>);
    });
  });
}

describe("trip tracking end to end (Constitution V)", () => {
  it("carries a driver's MQTT ping to the resident's live map", async () => {
    const socket = openSocket(residentToken(fixture.routeId), fixture.routeId);
    await new Promise<void>((resolve, reject) => {
      socket.once("open", resolve);
      socket.once("error", reject);
    });

    const frame = firstFrame(socket);

    // Published exactly as apps/mobile/lib/src/driver/trip_tracker.dart does.
    const client = await mqtt.connectAsync(MQTT_URL, {
      username: "namma-kasa-ingest",
      password: "devpassword",
    });
    await client.publishAsync(
      `trips/${fixture.tripId}/pings`,
      // Field names must match ping_spool.dart's toJson exactly; a mismatch
      // here is silently dropped by the consumer's safeParse.
      JSON.stringify([
        {
          lat: fixture.lat,
          lng: fixture.lng,
          recordedAt: new Date().toISOString(),
          seq: nextSeq(),
          accuracy: 8,
        },
      ]),
      { qos: 1 },
    );

    const received = await frame;
    await client.endAsync();
    socket.close();

    expect(received).not.toBeNull();
    expect(received!.type).toBe("position");
    expect(received!.tripId).toBe(fixture.tripId);
    expect(received!.registrationNumber).toBe(fixture.registrationNumber);
    expect(received!.lat).toBeCloseTo(fixture.lat, 4);
  });

  it("queues the proximity alert from the same ping", async () => {
    // Every household on the route shares this pass, and a claim left by an
    // earlier run would silently suppress the one being asserted here.
    const onRoute = await db
      .selectFrom("households as h")
      .innerJoin("users as u", "u.id", "h.user_id")
      .select(["h.id as householdId", "u.id as userId"])
      .where("h.route_id", "=", fixture.routeId)
      .execute();

    for (const household of onRoute) {
      await redis.del(
        proximityDedupKey(
          household.householdId,
          fixture.routeId,
          serviceDateIST(),
          fixture.passNumber,
        ),
      );
    }
    await db
      .deleteFrom("notifications")
      .where(
        "user_id",
        "in",
        onRoute.map((h) => h.userId),
      )
      .where("kind", "=", "proximity")
      .execute();

    const client = await mqtt.connectAsync(MQTT_URL, {
      username: "namma-kasa-ingest",
      password: "devpassword",
    });
    await client.publishAsync(
      `trips/${fixture.tripId}/pings`,
      JSON.stringify({
        lat: fixture.lat,
        lng: fixture.lng,
        recordedAt: new Date().toISOString(),
        seq: nextSeq(),
        accuracy: 8,
      }),
      { qos: 1 },
    );

    // The consumer and the geofence both run off the broker's delivery.
    const queued = await waitFor(async () => {
      const row = await db
        .selectFrom("notifications")
        .select("id")
        .where(
          "user_id",
          "in",
          onRoute.map((h) => h.userId),
        )
        .where("kind", "=", "proximity")
        .executeTakeFirst();
      return row !== undefined;
    });

    await client.endAsync();
    expect(queued).toBe(true);
  });

  it("does not send another route's positions to a resident", async () => {
    const otherRoute = await db
      .selectFrom("routes")
      .select("id")
      .where("id", "!=", fixture.routeId)
      .executeTakeFirst();
    if (!otherRoute) return;

    // A token for the other route cannot even open a socket on this one.
    const socket = openSocket(residentToken(otherRoute.id), fixture.routeId);
    const outcome = await new Promise<string>((resolve) => {
      socket.once("open", () => resolve("open"));
      socket.once("error", () => resolve("rejected"));
      setTimeout(() => resolve("timeout"), 5_000);
    });
    socket.close();

    expect(outcome).toBe("rejected");
  });

  it("rejects a socket with no token at all", async () => {
    const socket = new WebSocket(
      `ws://127.0.0.1:${port}/v1/live?route_id=${fixture.routeId}`,
    );
    const outcome = await new Promise<string>((resolve) => {
      socket.once("open", () => resolve("open"));
      socket.once("error", () => resolve("rejected"));
      setTimeout(() => resolve("timeout"), 5_000);
    });
    socket.close();

    expect(outcome).toBe("rejected");
  });

  it("drops a ping for a trip that has already ended", async () => {
    const ended = await db
      .selectFrom("trips")
      .select("id")
      .where("status", "=", "completed")
      .executeTakeFirstOrThrow();

    const before = await pingCount(ended.id);

    const client = await mqtt.connectAsync(MQTT_URL, {
      username: "namma-kasa-ingest",
      password: "devpassword",
    });
    await client.publishAsync(
      `trips/${ended.id}/pings`,
      JSON.stringify({
        lat: fixture.lat,
        lng: fixture.lng,
        recordedAt: new Date().toISOString(),
        seq: nextSeq(),
      }),
      { qos: 1 },
    );
    await new Promise((resolve) => setTimeout(resolve, 1_500));
    await client.endAsync();

    // Resurrecting a finished trip would corrupt the collection record.
    expect(await pingCount(ended.id)).toBe(before);
  });
});

async function pingCount(tripId: string): Promise<number> {
  const row = await sql<{ count: string }>`
    SELECT count(*)::text AS count FROM location_pings WHERE trip_id = ${tripId}::uuid
  `.execute(db);
  return Number(row.rows[0]?.count ?? 0);
}

/** Polls until true or the budget runs out; the broker delivers async. */
async function waitFor(check: () => Promise<boolean>, budgetMs = 8_000): Promise<boolean> {
  const deadline = Date.now() + budgetMs;
  while (Date.now() < deadline) {
    if (await check()) return true;
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  return false;
}
