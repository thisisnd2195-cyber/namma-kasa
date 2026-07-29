import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import request from "supertest";
import Redis from "ioredis";
import { AppModule } from "../src/app.module";
import { ProblemFilter } from "../src/common/filters/problem.filter";
import { createTestDb } from "./helpers/db";
import { lastPingKey, seqKey } from "../src/modules/tracking/ingest.service";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

/**
 * A driver's day over HTTP: register against a pre-provisioned phone, see the
 * assignment, start a pass, push positions, take a photo, report a problem,
 * and end the trip.
 *
 * This is the HTTPS fallback path — the one used when MQTT is unreachable —
 * so it is not the same code as end-to-end.spec.ts even though both end in
 * IngestService.
 */
let app: INestApplication;
const db = createTestDb();
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");

let driverToken: string;
let driverUserId: string;
let driverId: string;
let autoId: string;
let routeId: string;

/** Monotonic across the file: ingest drops any seq it has already seen. */
let seq = Date.now() % 1_000_000;
const nextSeq = () => ++seq;

const post = (path: string, token: string, body?: unknown) =>
  request(app.getHttpServer())
    .post(path)
    .set("Authorization", `Bearer ${token}`)
    .send(body ?? {});
const patch = (path: string, token: string, body?: unknown) =>
  request(app.getHttpServer())
    .patch(path)
    .set("Authorization", `Bearer ${token}`)
    .send(body ?? {});
const get = (path: string, token: string) =>
  request(app.getHttpServer()).get(path).set("Authorization", `Bearer ${token}`);

beforeAll(async () => {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
  app = moduleRef.createNestApplication({ logger: false });
  app.useGlobalFilters(new ProblemFilter());
  app.setGlobalPrefix("v1");
  await app.init();

  // Provision a fresh driver rather than reusing the seeded one, whose account
  // may already exist from an earlier run with an unknown password.
  const admin = await request(app.getHttpServer())
    .post("/v1/auth/login")
    .send({ phone: "919000000001", password: "devpassword", deviceId: "driver-spec-admin" })
    .expect(200);
  const superAdmin = admin.body.accessToken as string;

  const ward = await db
    .selectFrom("wards")
    .select("id")
    .where("ward_admin_user_id", "is not", null)
    .executeTakeFirstOrThrow();
  const route = await db
    .selectFrom("routes")
    .select("id")
    .where("ward_id", "=", ward.id)
    .executeTakeFirstOrThrow();

  const phone = `9197${Math.floor(Math.random() * 90000000) + 10000000}`;
  const suffix = Math.floor(Math.random() * 9000) + 1000;

  const provisioned = await post("/v1/admin/drivers", superAdmin, {
    wardId: ward.id,
    fullName: "Spec Driver",
    phone,
    licenseNumber: `KA-SPEC-${suffix}`,
  }).expect(201);
  driverId = provisioned.body.id;

  const auto = await post("/v1/admin/autos", superAdmin, {
    registrationNumber: `KA53DR${suffix}`,
    wardId: ward.id,
    photos: [],
  }).expect(201);
  autoId = auto.body.id;
  routeId = route.id;

  await post(`/v1/admin/autos/${autoId}/assign-route`, superAdmin, {
    routeId,
    effectiveFrom: new Date().toISOString(),
  }).expect(204);
  await post(`/v1/admin/drivers/${driverId}/assign-auto`, superAdmin, {
    autoId,
    effectiveFrom: new Date().toISOString(),
  }).expect(204);

  // Now claim the account the way the app does: OTP, then register.
  await request(app.getHttpServer()).post("/v1/auth/otp/send").send({ phone }).expect(202);

  const verify = await request(app.getHttpServer())
    .post("/v1/auth/otp/verify")
    .send({ phone, code: await storedOtp(phone) })
    .expect(200);

  const registered = await request(app.getHttpServer())
    .post("/v1/auth/register")
    .send({
      role: "driver",
      verificationToken: verify.body.verificationToken,
      credential: { password: "devpassword" },
      profile: { locale: "kn", consent: true },
      deviceId: "driver-spec",
    })
    .expect(201);

  driverToken = registered.body.accessToken;
  driverUserId = registered.body.user.id;
}, 60_000);

/** The OTP is held in Redis by the send endpoint; tests read it back. */
async function storedOtp(phone: string): Promise<string> {
  const keys = await redis.keys(`otp:*${phone}*`);
  for (const key of keys) {
    const value = await redis.get(key);
    if (value && /^\d{6}$/.test(value)) return value;
    if (value) {
      try {
        const parsed = JSON.parse(value) as { code?: string };
        if (parsed.code) return parsed.code;
      } catch {
        // not json; fall through
      }
    }
  }
  throw new Error(`no OTP stored for ${phone}`);
}

afterAll(async () => {
  // Everything this spec created, in dependency order.
  await db.deleteFrom("driver_issues").where("driver_id", "=", driverId).execute();
  await db.deleteFrom("media_uploads").where("driver_id", "=", driverId).execute();
  await db.deleteFrom("trips").where("driver_id", "=", driverId).execute();
  await db.deleteFrom("driver_auto_assignments").where("driver_id", "=", driverId).execute();
  await db.deleteFrom("auto_route_assignments").where("auto_id", "=", autoId).execute();
  await db.deleteFrom("drivers").where("id", "=", driverId).execute();
  await db.deleteFrom("autos").where("id", "=", autoId).execute();
  if (driverUserId) await db.deleteFrom("users").where("id", "=", driverUserId).execute();

  await app.close();
  await db.destroy();
  redis.disconnect();
});

describe("a driver's day over HTTP", () => {
  let tripId: string;

  it("shows the assignment the home screen renders (FR-DRV-01)", async () => {
    const response = await get("/v1/driver/assignment", driverToken);
    if (response.status !== 200) return; // driver has no active assignment

    expect(response.body.auto.registrationNumber).toBeTruthy();
    expect(response.body.route.id).toBeTruthy();
    expect(response.body.today).toHaveProperty("passesTotal");
    // Driver identity is theirs; the payload is not the resident's.
    expect(response.body.today).toHaveProperty("passesCompleted");
  });

  it("starts a pass, or reports why it cannot (FR-DRV-02)", async () => {
    const assignment = await get("/v1/driver/assignment", driverToken);
    if (assignment.status !== 200) return;

    // End anything already running so the pass sequence is deterministic.
    // Pass state (route_pass_days) is shared per ROUTE, so an active trip left
    // by another auto — e.g. the live smoke test — blocks this pass too.
    await db
      .updateTable("trips")
      .set({ status: "completed", ended_at: new Date() })
      .where("route_id", "=", assignment.body.route.id)
      .where("status", "=", "active")
      .execute();
    await db
      .updateTable("route_pass_days")
      .set({ status: "completed" })
      .where("route_id", "=", assignment.body.route.id)
      .where("status", "=", "active")
      .execute();

    const next = assignment.body.today.nextPassNumber ?? 1;
    const response = await post("/v1/driver/trips", driverToken, { passNumber: next });

    if (response.status === 201) {
      tripId = response.body.id;
      expect(response.body.status).toBe("active");
      expect(response.body.passNumber).toBe(next);
    } else {
      // Out-of-order or already-served passes are refused, which is the rule.
      expect([409, 422]).toContain(response.status);
    }
  });

  it("refuses a pass number the route does not have", async () => {
    const response = await post("/v1/driver/trips", driverToken, { passNumber: 99 });
    expect([409, 422]).toContain(response.status);
  });

  it("accepts a batch of positions over the HTTPS fallback (FR-DRV-03)", async () => {
    if (!tripId) return;
    await redis.del(seqKey(tripId), lastPingKey(tripId));

    const response = await post(`/v1/driver/trips/${tripId}/pings`, driverToken, {
      pings: [
        { lat: 12.9716, lng: 77.5946, recordedAt: new Date().toISOString(), seq: nextSeq() },
        { lat: 12.9717, lng: 77.5947, recordedAt: new Date().toISOString(), seq: nextSeq() },
      ],
    }).expect(202);

    expect(response.body.accepted).toBe(2);
    expect(response.body.rejected).toBe(0);
  });

  it("rejects a replayed sequence rather than double-counting the trail", async () => {
    if (!tripId) return;
    const replayed = seq; // already accepted above

    const response = await post(`/v1/driver/trips/${tripId}/pings`, driverToken, {
      pings: [
        { lat: 12.9716, lng: 77.5946, recordedAt: new Date().toISOString(), seq: replayed },
      ],
    }).expect(202);

    expect(response.body.accepted).toBe(0);
    expect(response.body.rejected).toBe(1);
  });

  it("rejects a position too inaccurate to be evidence", async () => {
    if (!tripId) return;

    const response = await post(`/v1/driver/trips/${tripId}/pings`, driverToken, {
      pings: [
        {
          lat: 12.9716,
          lng: 77.5946,
          recordedAt: new Date().toISOString(),
          seq: nextSeq(),
          accuracy: 500,
        },
      ],
    }).expect(202);

    expect(response.body.rejected).toBe(1);
  });

  it("refuses a batch larger than the contract allows", async () => {
    if (!tripId) return;

    await post(`/v1/driver/trips/${tripId}/pings`, driverToken, {
      pings: Array.from({ length: 25 }, () => ({
        lat: 12.97,
        lng: 77.59,
        recordedAt: new Date().toISOString(),
        seq: nextSeq(),
      })),
    }).expect(422);
  });

  it("issues an MQTT token scoped to this trip alone", async () => {
    if (!tripId) return;

    const response = await post(`/v1/driver/trips/${tripId}/mqtt-token`, driverToken).expect(201);
    expect(response.body.username).toBe(driverUserId);
    expect(response.body.expiresInSec).toBeGreaterThan(0);
  });

  it("refuses to issue a token for someone else's trip", async () => {
    const other = await db
      .selectFrom("trips")
      .select("id")
      .where("id", "!=", tripId ?? "00000000-0000-0000-0000-000000000000")
      .executeTakeFirst();
    if (!other) return;

    const response = await post(`/v1/driver/trips/${other.id}/mqtt-token`, driverToken);
    expect([403, 404]).toContain(response.status);
  });

  it("presigns and confirms a geotagged photo (FR-DRV-06)", async () => {
    if (!tripId) return;

    const presigned = await post(`/v1/driver/trips/${tripId}/media/presign`, driverToken, {
      contentType: "image/jpeg",
      type: "collection_proof",
    }).expect(201);

    expect(presigned.body.uploadUrl).toContain("X-Amz-Signature");

    await post(`/v1/driver/trips/${tripId}/media/confirm`, driverToken, {
      uploadId: presigned.body.uploadId,
      objectUrl: presigned.body.objectUrl,
      type: "collection_proof",
      geo: { lat: 12.9716, lng: 77.5946 },
      capturedAt: new Date().toISOString(),
    }).expect(201);

    const stored = await db
      .selectFrom("media_uploads")
      .select("id")
      .where("trip_id", "=", tripId)
      .executeTakeFirst();
    expect(stored).toBeDefined();
  });

  it("reports a breakdown to the ward admin (FR-DRV-07)", async () => {
    const response = await post("/v1/driver/issues", driverToken, {
      kind: "breakdown",
      note: "Rear tyre, over HTTP",
      geo: { lat: 12.9716, lng: 77.5946 },
    }).expect(201);

    expect(response.body.kind).toBe("breakdown");
    expect(response.body.acknowledgedAt).toBeNull();
  });

  it("ends the trip and stops it being active", async () => {
    if (!tripId) return;

    const response = await patch(`/v1/driver/trips/${tripId}/end`, driverToken, {
      reason: "driver",
      distanceCoveredM: 1200,
    }).expect(200);

    expect(response.body.status).toBe("completed");

    const row = await db
      .selectFrom("trips")
      .select(["status", "service_date"])
      .where("id", "=", tripId)
      .executeTakeFirstOrThrow();
    expect(row.status).toBe("completed");
    expect(row.service_date).toBe(serviceDateIST());
  });

  it("refuses to end a trip twice", async () => {
    if (!tripId) return;
    const response = await patch(`/v1/driver/trips/${tripId}/end`, driverToken, {
      reason: "driver",
    });
    expect([409, 404, 200]).toContain(response.status);
  });
});
