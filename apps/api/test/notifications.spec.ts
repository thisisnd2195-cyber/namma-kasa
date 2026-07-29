import { afterAll, beforeEach, describe, expect, it } from "vitest";
import Redis from "ioredis";
import { createTestDb } from "./helpers/db";
import { GeofenceService, proximityDedupKey } from "../src/modules/notify/geofence.service";
import { NotifyService } from "../src/modules/notify/notify.service";
import { proximityCopy, roundDistance } from "../src/modules/notify/templates";
import type { PushMessage, PushSender } from "../src/modules/notify/push-sender";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

const db = createTestDb();
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");
const geofence = new GeofenceService(db, redis);

/** Records what would have been pushed, and can be told to fail. */
class RecordingPushSender implements PushSender {
  readonly sent: PushMessage[] = [];
  shouldFail = false;

  async send(message: PushMessage) {
    if (this.shouldFail) throw new Error("push transport down");
    this.sent.push(message);
    return { delivered: message.tokens.length, failedTokens: [] };
  }
}

const push = new RecordingPushSender();
const notify = new NotifyService(db, push);

afterAll(async () => {
  await db.destroy();
  redis.disconnect();
});

async function seededHousehold() {
  return db
    .selectFrom("households as h")
    .innerJoin("users as u", "u.id", "h.user_id")
    .select([
      "h.id as householdId",
      "h.user_id as userId",
      "h.route_id as routeId",
      "u.locale",
      (eb) => eb.fn<number>("ST_Y", ["h.house_geo"]).as("lat"),
      (eb) => eb.fn<number>("ST_X", ["h.house_geo"]).as("lng"),
    ])
    .where("h.route_id", "is not", null)
    .executeTakeFirstOrThrow();
}

describe("proximity geofence (FR-NOTIF-01, FR-NOTIF-02)", () => {
  let household: Awaited<ReturnType<typeof seededHousehold>>;

  beforeEach(async () => {
    household = await seededHousehold();
    const key = proximityDedupKey(
      household.householdId,
      household.routeId!,
      serviceDateIST(),
      1,
    );
    await redis.del(key);
  });

  it("alerts a household the auto has come close to", async () => {
    const hits = await geofence.hitsFor(household.routeId!, 1, {
      lat: household.lat,
      lng: household.lng,
    });
    expect(hits.map((h) => h.householdId)).toContain(household.householdId);
  });

  it("does not alert a household the auto is nowhere near", async () => {
    // ~5 km away, well outside any configured radius.
    const hits = await geofence.hitsFor(household.routeId!, 1, {
      lat: household.lat + 0.045,
      lng: household.lng,
    });
    expect(hits.map((h) => h.householdId)).not.toContain(household.householdId);
  });

  /**
   * Two autos can serve one pass, and the auto passes a house repeatedly while
   * working the street. Either would produce a stream of alerts without this.
   */
  it("alerts once per pass however many times the auto comes near", async () => {
    const position = { lat: household.lat, lng: household.lng };

    const first = await geofence.hitsFor(household.routeId!, 1, position);
    expect(first.map((h) => h.householdId)).toContain(household.householdId);

    const second = await geofence.hitsFor(household.routeId!, 1, position);
    expect(second.map((h) => h.householdId)).not.toContain(household.householdId);
  });

  it("alerts again on the next pass of the day", async () => {
    const position = { lat: household.lat, lng: household.lng };
    await geofence.hitsFor(household.routeId!, 1, position);

    const passTwoKey = proximityDedupKey(
      household.householdId,
      household.routeId!,
      serviceDateIST(),
      2,
    );
    await redis.del(passTwoKey);

    const secondPass = await geofence.hitsFor(household.routeId!, 2, position);
    expect(secondPass.map((h) => h.householdId)).toContain(household.householdId);
  });
});

describe("notification copy (Clarifications CHK026)", () => {
  it("rounds distance to 50 m so the map and the push agree", () => {
    expect(roundDistance(237)).toBe(250);
    expect(roundDistance(312)).toBe(300);
    // Never claims to be closer than the GPS can justify.
    expect(roundDistance(4)).toBe(50);
  });

  it("writes Kannada for a Kannada resident", () => {
    const copy = proximityCopy("kn", 300, ["wet", "dry"]);
    expect(copy.title).toContain("ಆಟೋ");
    expect(copy.body).toContain("ಹಸಿ ಕಸ");
  });

  it("names today's waste types so the resident puts out the right bin", () => {
    const copy = proximityCopy("en", 300, ["wet", "sanitary"]);
    expect(copy.title).toBe("Auto is ~300 m away");
    expect(copy.body).toBe("Today: Wet + Sanitary");
  });
});

describe("notification outbox", () => {
  async function clearFor(userId: string) {
    await db.deleteFrom("notifications").where("user_id", "=", userId).execute();
  }

  it("delivers a queued notification and marks it sent", async () => {
    const household = await seededHousehold();
    await clearFor(household.userId);

    const queued = await notify.queueProximity({
      userId: household.userId,
      locale: household.locale,
      distanceM: 280,
      wasteTypes: ["wet"],
      routeId: household.routeId!,
      tripId: "00000000-0000-4000-8000-000000000001",
      dedupKey: `test-${crypto.randomUUID()}`,
    });
    expect(queued).toBe(true);

    const delivered = await notify.drain();
    expect(delivered).toBeGreaterThanOrEqual(0);

    const row = await db
      .selectFrom("notifications")
      .select("sent_at")
      .where("user_id", "=", household.userId)
      .executeTakeFirstOrThrow();
    expect(row.sent_at).not.toBeNull();
  });

  it("refuses a duplicate dedup key even if the Redis claim is gone", async () => {
    const household = await seededHousehold();
    await clearFor(household.userId);
    const dedupKey = `test-${crypto.randomUUID()}`;

    const first = await notify.queueProximity({
      userId: household.userId,
      locale: "en",
      distanceM: 300,
      wasteTypes: [],
      routeId: household.routeId!,
      tripId: "00000000-0000-4000-8000-000000000001",
      dedupKey,
    });
    const second = await notify.queueProximity({
      userId: household.userId,
      locale: "en",
      distanceM: 300,
      wasteTypes: [],
      routeId: household.routeId!,
      tripId: "00000000-0000-4000-8000-000000000001",
      dedupKey,
    });

    expect(first).toBe(true);
    expect(second).toBe(false);
  });

  /** A push outage must not lose the alert; the next drain retries it. */
  it("leaves a notification unsent when the transport fails", async () => {
    const household = await seededHousehold();
    await clearFor(household.userId);
    await notify.queueProximity({
      userId: household.userId,
      locale: "en",
      distanceM: 300,
      wasteTypes: [],
      routeId: household.routeId!,
      tripId: "00000000-0000-4000-8000-000000000001",
      dedupKey: `test-${crypto.randomUUID()}`,
    });

    push.shouldFail = true;
    await notify.drain();
    push.shouldFail = false;

    const stillPending = await db
      .selectFrom("notifications")
      .select("sent_at")
      .where("user_id", "=", household.userId)
      .executeTakeFirstOrThrow();
    expect(stillPending.sent_at).toBeNull();

    await notify.drain();
    const afterRetry = await db
      .selectFrom("notifications")
      .select("sent_at")
      .where("user_id", "=", household.userId)
      .executeTakeFirstOrThrow();
    expect(afterRetry.sent_at).not.toBeNull();
  });

  /** SC-005 budget: geofence hit to push handed off within 10 seconds. */
  it("queues and drains well inside the latency budget", async () => {
    const household = await seededHousehold();
    await clearFor(household.userId);

    const started = Date.now();
    await notify.queueProximity({
      userId: household.userId,
      locale: "en",
      distanceM: 300,
      wasteTypes: ["wet"],
      routeId: household.routeId!,
      tripId: "00000000-0000-4000-8000-000000000001",
      dedupKey: `test-${crypto.randomUUID()}`,
    });
    await notify.drain();
    const elapsedMs = Date.now() - started;

    expect(elapsedMs).toBeLessThan(10_000);
  });
});
