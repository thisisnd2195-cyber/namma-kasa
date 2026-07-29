import { afterAll, describe, expect, it } from "vitest";
import { ConfigService } from "@nestjs/config";
import Redis from "ioredis";
import type { AccessClaims } from "@namma-kasa/shared";
import { createTestDb } from "./helpers/db";
import { HouseholdsService } from "../src/modules/geo/households.service";
import { MediaService } from "../src/modules/tracking/media.service";
import { TripsService } from "../src/modules/tracking/trips.service";

const db = createTestDb();
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");
const trips = new TripsService(db);
const households = new HouseholdsService(db);

const config = {
  get: (key: string, fallback?: unknown) =>
    ({
      S3_ENDPOINT: process.env.S3_ENDPOINT ?? "http://localhost:9000",
      S3_BUCKET: "namma-kasa-media",
      S3_ACCESS_KEY: "minioadmin",
      S3_SECRET_KEY: "minioadmin",
    })[key] ?? fallback,
  getOrThrow: (key: string) => {
    const value = (config.get as (k: string, f?: unknown) => unknown)(key);
    if (value === undefined) throw new Error(`missing ${key}`);
    return value;
  },
} as unknown as ConfigService;

const media = new MediaService(db, config);

afterAll(async () => {
  await db.destroy();
  redis.disconnect();
});

async function seededDriver() {
  return db
    .selectFrom("drivers")
    .select(["id", "user_id", "ward_id"])
    .where("user_id", "is not", null)
    .executeTakeFirstOrThrow();
}

describe("driver home payload (FR-DRV-01)", () => {
  it("returns the auto, route, window, waste types and pass progress", async () => {
    const driver = await seededDriver();
    const assignment = await trips.assignmentFor(driver.user_id!);

    // Everything the driver's home screen renders, in one payload.
    expect(assignment.auto.registrationNumber).toBeTruthy();
    expect(assignment.route.id).toBeTruthy();
    expect((assignment.route.serviceableArea as { type: string }).type).toMatch(/Polygon/);
    expect(assignment.route.windowStart).toMatch(/^\d{2}:\d{2}$/);
    expect(assignment.route.windowEnd).toMatch(/^\d{2}:\d{2}$/);
    expect(Array.isArray(assignment.today.wasteTypes)).toBe(true);
    expect(assignment.today.passesTotal).toBeGreaterThanOrEqual(1);
    expect(assignment.today.passesCompleted).toBeGreaterThanOrEqual(0);
    expect(assignment.today.passesCompleted).toBeLessThanOrEqual(assignment.today.passesTotal);
  });

  it("never exposes the next pass beyond what the route allows", async () => {
    const driver = await seededDriver();
    const assignment = await trips.assignmentFor(driver.user_id!);

    if (assignment.today.nextPassNumber !== null) {
      expect(assignment.today.nextPassNumber).toBeGreaterThanOrEqual(1);
      expect(assignment.today.nextPassNumber).toBeLessThanOrEqual(assignment.today.passesTotal);
    }
  });

  it("refuses a user who is not a provisioned driver", async () => {
    const resident = await db
      .selectFrom("users")
      .select("id")
      .where("role", "=", "resident")
      .executeTakeFirstOrThrow();

    await expect(trips.assignmentFor(resident.id)).rejects.toThrow();
  });
});

describe("a driver may only act on their own trip (FR-DRV-02)", () => {
  it("accepts the driver who owns the trip", async () => {
    const trip = await db
      .selectFrom("trips as t")
      .innerJoin("drivers as d", "d.id", "t.driver_id")
      .select(["t.id as tripId", "d.user_id as userId"])
      .where("d.user_id", "is not", null)
      .executeTakeFirstOrThrow();

    await expect(trips.requireOwnedTrip(trip.tripId, trip.userId!)).resolves.toBeUndefined();
  });

  it("rejects another driver's user id", async () => {
    const trip = await db
      .selectFrom("trips as t")
      .innerJoin("drivers as d", "d.id", "t.driver_id")
      .select(["t.id as tripId", "d.user_id as userId"])
      .where("d.user_id", "is not", null)
      .executeTakeFirstOrThrow();

    const stranger = await db
      .selectFrom("users")
      .select("id")
      .where("id", "!=", trip.userId!)
      .executeTakeFirstOrThrow();

    // Otherwise one driver could end, or attach photos to, another's trip.
    await expect(trips.requireOwnedTrip(trip.tripId, stranger.id)).rejects.toThrow(/not your trip/i);
  });

  it("rejects a trip id that does not exist", async () => {
    const driver = await seededDriver();
    await expect(
      trips.requireOwnedTrip("00000000-0000-0000-0000-000000000000", driver.user_id!),
    ).rejects.toThrow(/not your trip/i);
  });
});

describe("geotagged photo capture (FR-DRV-06)", () => {
  it("issues a presigned PUT and a matching public object url", async () => {
    const trip = await db.selectFrom("trips").select("id").executeTakeFirstOrThrow();

    const result = await media.presign({
      tripId: trip.id,
      prefix: `trips/${trip.id}`,
      contentType: "image/jpeg",
    });

    expect(result.uploadId).toMatch(/^[0-9a-f-]{36}$/);
    // A jpeg must land as .jpg, and both urls must address the same object.
    expect(result.objectUrl).toContain(`${result.uploadId}.jpg`);
    expect(result.uploadUrl).toContain(`${result.uploadId}.jpg`);
    expect(result.uploadUrl).toContain("X-Amz-Signature");
  });

  it("records the upload and its geotag on confirm", async () => {
    const trip = await db
      .selectFrom("trips as t")
      .innerJoin("drivers as d", "d.id", "t.driver_id")
      .select(["t.id as tripId", "d.id as driverId"])
      .executeTakeFirstOrThrow();

    const presigned = await media.presign({
      tripId: trip.tripId,
      prefix: `trips/${trip.tripId}`,
      contentType: "image/jpeg",
    });

    // confirm mints its own row id; the presigned uploadId only names the
    // object, and is carried into the row through object_url.
    const saved = await media.confirm({
      objectUrl: presigned.objectUrl,
      tripId: trip.tripId,
      driverId: trip.driverId,
      type: "collection_proof",
      geo: { lat: 12.9716, lng: 77.5946 },
      capturedAt: new Date(),
    });

    const row = await db
      .selectFrom("media_uploads")
      .select([
        "id",
        "trip_id",
        "type",
        "object_url",
        (eb) => eb.fn<number>("ST_Y", ["geo"]).as("lat"),
        (eb) => eb.fn<number>("ST_X", ["geo"]).as("lng"),
      ])
      .where("id", "=", saved.id)
      .executeTakeFirst();

    expect(row, "confirm did not persist the upload").toBeDefined();
    expect(row!.trip_id).toBe(trip.tripId);
    expect(row!.type).toBe("collection_proof");
    expect(row!.object_url).toContain(presigned.uploadId);
    // Geotagged is the requirement, so the point has to survive the write.
    expect(row!.lat).toBeCloseTo(12.9716, 4);
    expect(row!.lng).toBeCloseTo(77.5946, 4);
  });

  it("caps the photos one trip can carry", async () => {
    const trip = await db.selectFrom("trips").select("id").executeTakeFirstOrThrow();
    const before = await db
      .selectFrom("media_uploads")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .where("trip_id", "=", trip.id)
      .executeTakeFirstOrThrow();

    // Fill to the cap, then prove the next one is refused.
    for (let i = Number(before.count); i < 10; i++) {
      const p = await media.presign({
        tripId: trip.id,
        prefix: `trips/${trip.id}`,
        contentType: "image/jpeg",
      });
      await media.confirm({
        objectUrl: p.objectUrl,
        tripId: trip.id,
        driverId: (
          await db.selectFrom("drivers").select("id").executeTakeFirstOrThrow()
        ).id,
        type: "other",
      });
    }

    await expect(
      media.presign({ tripId: trip.id, prefix: `trips/${trip.id}`, contentType: "image/jpeg" }),
    ).rejects.toThrow(/at most 10 photos/i);

    await db.deleteFrom("media_uploads").where("trip_id", "=", trip.id).execute();
  });
});

describe("household review queue (FR-AUTH-08)", () => {
  async function wardWithHouseholds() {
    return db
      .selectFrom("households")
      .select("ward_id")
      .where("ward_id", "is not", null)
      .executeTakeFirstOrThrow();
  }

  it("lists households the automatic mapping could not place", async () => {
    const ward = await wardWithHouseholds();
    const household = await db
      .selectFrom("households")
      .select("id")
      .where("ward_id", "=", ward.ward_id!)
      .executeTakeFirstOrThrow();

    await db
      .updateTable("households")
      .set({ mapping_status: "pending_review", route_id: null })
      .where("id", "=", household.id)
      .execute();

    const queue = await households.reviewQueue(ward.ward_id!);
    expect(queue.map((h) => h.id)).toContain(household.id);
  });

  it("places a household on a route by hand and marks it corrected", async () => {
    const ward = await wardWithHouseholds();
    const household = await db
      .selectFrom("households")
      .select("id")
      .where("ward_id", "=", ward.ward_id!)
      .executeTakeFirstOrThrow();
    const route = await db
      .selectFrom("routes")
      .select("id")
      .where("ward_id", "=", ward.ward_id!)
      .executeTakeFirstOrThrow();

    const actor: AccessClaims = {
      sub: (await db.selectFrom("users").select("id").executeTakeFirstOrThrow()).id,
      role: "ward_admin",
      wardId: ward.ward_id!,
      routeId: null,
      deviceId: null,
    };

    const result = await households.assignRoute(household.id, route.id, actor);
    expect(result.routeId).toBe(route.id);
    expect(result.mappingStatus).toBe("admin_corrected");

    // And it leaves the queue, which is the point of the whole flow.
    const queue = await households.reviewQueue(ward.ward_id!);
    expect(queue.map((h) => h.id)).not.toContain(household.id);
  });

  it("refuses a ward admin reaching into another ward", async () => {
    const ward = await wardWithHouseholds();
    const household = await db
      .selectFrom("households")
      .select("id")
      .where("ward_id", "=", ward.ward_id!)
      .executeTakeFirstOrThrow();
    const route = await db
      .selectFrom("routes")
      .select(["id", "ward_id"])
      .where("ward_id", "!=", ward.ward_id!)
      .executeTakeFirst();
    if (!route) return; // single-ward fixture

    const actor: AccessClaims = {
      sub: (await db.selectFrom("users").select("id").executeTakeFirstOrThrow()).id,
      role: "ward_admin",
      wardId: ward.ward_id!,
      routeId: null,
      deviceId: null,
    };

    await expect(households.assignRoute(household.id, route.id, actor)).rejects.toThrow(
      /outside your ward/i,
    );
  });

  it("reports a missing household rather than silently doing nothing", async () => {
    const route = await db.selectFrom("routes").select(["id", "ward_id"]).executeTakeFirstOrThrow();
    const actor: AccessClaims = {
      sub: (await db.selectFrom("users").select("id").executeTakeFirstOrThrow()).id,
      role: "super_admin",
      wardId: null,
      routeId: null,
      deviceId: null,
    };

    await expect(
      households.assignRoute("00000000-0000-0000-0000-000000000000", route.id, actor),
    ).rejects.toThrow(/household not found/i);
  });
});
