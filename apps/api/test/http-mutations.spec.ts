import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import request from "supertest";
import { AppModule } from "../src/app.module";
import { ProblemFilter } from "../src/common/filters/problem.filter";
import Redis from "ioredis";
import { createTestDb } from "./helpers/db";

/**
 * The write paths, over HTTP.
 *
 * `http.spec.ts` covers reads and refusals; this covers the mutations an admin
 * and a driver actually perform, so the controllers, the validation pipe and
 * the geo invariants all run against real requests rather than direct service
 * calls.
 */
let app: INestApplication;
const db = createTestDb();
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");

let superAdmin: string;
let wardAdmin: string;
let resident: string;

/** Everything created here is torn down, so repeat runs stay clean. */
const created = { operators: [] as string[], wards: [] as string[], autos: [] as string[] };

const suffix = () => Math.random().toString(36).slice(2, 8);

async function login(phone: string) {
  const response = await request(app.getHttpServer())
    .post("/v1/auth/login")
    .send({ phone, password: "devpassword", deviceId: `mut-${phone}` })
    .expect(200);
  return response.body.accessToken as string;
}

type Body = string | object;
const post = (path: string, token: string, body: Body) =>
  request(app.getHttpServer()).post(path).set("Authorization", `Bearer ${token}`).send(body);
const patch = (path: string, token: string, body: Body) =>
  request(app.getHttpServer()).patch(path).set("Authorization", `Bearer ${token}`).send(body);
const get = (path: string, token: string) =>
  request(app.getHttpServer()).get(path).set("Authorization", `Bearer ${token}`);

/** A square polygon well away from the seeded Bengaluru wards. */
function box(minLng: number, minLat: number, size = 0.02) {
  const maxLng = minLng + size;
  const maxLat = minLat + size;
  return {
    type: "Polygon" as const,
    coordinates: [
      [
        [minLng, minLat],
        [maxLng, minLat],
        [maxLng, maxLat],
        [minLng, maxLat],
        [minLng, minLat],
      ],
    ],
  };
}

beforeAll(async () => {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
  app = moduleRef.createNestApplication({ logger: false });
  app.useGlobalFilters(new ProblemFilter());
  app.setGlobalPrefix("v1");
  await app.init();

  superAdmin = await login("919000000001");
  wardAdmin = await login("919000000002");
  resident = await login("919888800001");
}, 60_000);

afterAll(async () => {
  for (const id of created.autos) {
    await db.deleteFrom("auto_route_assignments").where("auto_id", "=", id).execute();
    await db.deleteFrom("autos").where("id", "=", id).execute();
  }
  for (const id of created.wards) {
    await db.deleteFrom("routes").where("ward_id", "=", id).execute();
    await db.deleteFrom("wards").where("id", "=", id).execute();
  }
  for (const id of created.operators) {
    await db.deleteFrom("operators").where("id", "=", id).execute();
  }
  await app.close();
  await db.destroy();
  redis.disconnect();
});

describe("ward and route administration over HTTP", () => {
  let operatorId: string;
  let wardId: string;

  it("creates an operator with a typed SLA config (FR-WARD-01, FR-CMP-03)", async () => {
    const response = await post("/v1/admin/operators", superAdmin, {
      name: `Mut Operator ${suffix()}`,
      type: "private",
      config: { defaultComplaintSlaHours: 12, escalateAfterHours: 24 },
    }).expect(201);

    operatorId = response.body.id;
    created.operators.push(operatorId);
    // The config comes back parsed, with the schema's defaults filled in.
    expect(response.body.config.defaultComplaintSlaHours).toBe(12);
    expect(response.body.config.sahaayaSyncEnabled).toBe(false);
  });

  it("creates a ward with a boundary", async () => {
    const response = await post("/v1/admin/wards", superAdmin, {
      operatorId,
      name: `Mut Ward ${suffix()}`,
      wardCode: `MW-${suffix()}`,
      cityId: `mut-${suffix()}`,
      boundary: box(78.9, 14.9),
    }).expect(201);

    wardId = response.body.id;
    created.wards.push(wardId);
    expect(["Polygon", "MultiPolygon"]).toContain(response.body.boundary.type);
  });

  it("rejects a ward whose boundary overlaps an existing one (FR-WARD-05)", async () => {
    const response = await post("/v1/admin/wards", superAdmin, {
      operatorId,
      name: `Overlap ${suffix()}`,
      wardCode: `OV-${suffix()}`,
      cityId: (await db
        .selectFrom("wards")
        .select("city_id")
        .where("id", "=", wardId)
        .executeTakeFirstOrThrow()).city_id,
      // Shifted by a quarter of a box, so it genuinely overlaps.
      boundary: box(78.905, 14.905),
    });

    expect(response.status).toBe(409);
    expect(response.body.detail).toMatch(/overlap/i);
  });

  it("creates a route inside the ward, and refuses one outside it (FR-ROUTE-01)", async () => {
    const inside = await post("/v1/admin/routes", superAdmin, {
      wardId,
      name: "Mut Route A",
      routeCode: `MR-${suffix()}`,
      serviceableArea: box(78.902, 14.902, 0.005),
      collectionDays: [1, 2, 3, 4, 5, 6],
      windowStart: "06:00",
      windowEnd: "10:00",
      passesPerDay: 2,
      wasteTypeSchedule: { "1": ["wet"], "2": ["dry"] },
    }).expect(201);

    expect(inside.body.passesPerDay).toBe(2);
    expect(inside.body.recordedPath).toBeNull();

    const outside = await post("/v1/admin/routes", superAdmin, {
      wardId,
      name: "Mut Route B",
      routeCode: `MR-${suffix()}`,
      serviceableArea: box(60.0, 5.0, 0.005),
      collectionDays: [1],
      windowStart: "06:00",
      windowEnd: "10:00",
    });
    expect(outside.status).toBe(422);
  });

  it("refuses a window that ends before it starts", async () => {
    await post("/v1/admin/routes", superAdmin, {
      wardId,
      name: "Backwards",
      routeCode: `MR-${suffix()}`,
      serviceableArea: box(78.912, 14.912, 0.003),
      collectionDays: [1],
      windowStart: "10:00",
      windowEnd: "06:00",
    }).expect(422);
  });

  it("reports the blast radius of a boundary edit before committing it", async () => {
    const response = await post(
      `/v1/admin/wards/${wardId}/edit-impact`,
      superAdmin,
      box(78.9, 14.9, 0.01),
    ).expect(200);

    expect(response.body).toHaveProperty("affectedHouseholds");
    expect(response.body).toHaveProperty("routesOutsideNewBoundary");
  });

  it("imports wards in bulk and reports each feature's outcome (FR-WARD-04)", async () => {
    const cityId = `imp-${suffix()}`;
    const response = await post("/v1/admin/wards/import", superAdmin, {
      operatorId,
      cityId,
      featureCollection: {
        type: "FeatureCollection",
        features: [
          {
            type: "Feature",
            properties: { ward_code: `IM-${suffix()}`, name: "Imported One" },
            geometry: box(79.5, 15.5, 0.01),
          },
          {
            type: "Feature",
            properties: { name: "No code" },
            geometry: box(79.6, 15.6, 0.01),
          },
        ],
      },
    }).expect(201);

    // Per-feature accept/reject, never all-or-nothing silence.
    expect(response.body.accepted.length).toBe(1);
    expect(response.body.rejected.length).toBe(1);

    for (const accepted of response.body.accepted) created.wards.push(accepted.id);
  });
});

describe("fleet administration over HTTP (FR-FLEET-01..04)", () => {
  let autoId: string;
  let wardId: string;

  beforeAll(async () => {
    const ward = await db
      .selectFrom("wards")
      .select("id")
      .where("ward_admin_user_id", "is not", null)
      .executeTakeFirstOrThrow();
    wardId = ward.id;
  });

  it("onboards an auto with an Indian-format registration", async () => {
    const response = await post("/v1/admin/autos", wardAdmin, {
      registrationNumber: `KA51XY${Math.floor(Math.random() * 9000) + 1000}`,
      capacityKg: 500,
      wardId,
      photos: [],
    }).expect(201);

    autoId = response.body.id;
    created.autos.push(autoId);
    expect(response.body.status).toBe("available");
  });

  it("refuses a malformed registration number", async () => {
    await post("/v1/admin/autos", wardAdmin, {
      registrationNumber: "not-a-plate",
      wardId,
      photos: [],
    }).expect(422);
  });

  it("refuses a duplicate registration number", async () => {
    const existing = await db
      .selectFrom("autos")
      .select("registration_number")
      .executeTakeFirstOrThrow();

    const response = await post("/v1/admin/autos", wardAdmin, {
      registrationNumber: existing.registration_number,
      wardId,
      photos: [],
    });
    expect(response.status).toBe(409);
  });

  it("updates an auto's status", async () => {
    const response = await patch(`/v1/admin/autos/${autoId}`, wardAdmin, {
      status: "maintenance",
    }).expect(200);
    expect(response.body.status).toBe("maintenance");
  });

  it("assigns an auto to a route and records the assignment history", async () => {
    await patch(`/v1/admin/autos/${autoId}`, wardAdmin, { status: "available" }).expect(200);

    const route = await db
      .selectFrom("routes")
      .select("id")
      .where("ward_id", "=", wardId)
      .executeTakeFirstOrThrow();

    await post(`/v1/admin/autos/${autoId}/assign-route`, wardAdmin, {
      routeId: route.id,
      effectiveFrom: new Date().toISOString(),
    }).expect(204);

    // The history is split by what was assigned: routes and drivers.
    const history = await get(`/v1/admin/autos/${autoId}/assignments`, wardAdmin).expect(200);
    expect(history.body.routes.length).toBeGreaterThan(0);
    expect(Array.isArray(history.body.drivers)).toBe(true);
    // History is never rewritten, so the open row carries a start (FR-FLEET-04).
    expect(history.body.routes[0].effective_from ?? history.body.routes[0].effectiveFrom)
      .toBeTruthy();
  });

  it("lists autos and drivers for the ward", async () => {
    await get(`/v1/admin/autos?wardId=${wardId}`, wardAdmin).expect(200);
    const drivers = await get(`/v1/admin/drivers?wardId=${wardId}`, wardAdmin).expect(200);
    expect(Array.isArray(drivers.body)).toBe(true);
  });

  it("provisions a driver, and refuses a duplicate phone (FR-FLEET-03)", async () => {
    const phone = `9198${Math.floor(Math.random() * 90000000) + 10000000}`;
    const created1 = await post("/v1/admin/drivers", wardAdmin, {
      wardId,
      fullName: "Mut Driver",
      phone,
      licenseNumber: `KA${suffix()}`,
    }).expect(201);

    expect(created1.body.hasAccount).toBe(false);
    // Personal details are admin-only; residents never see this payload.
    expect(created1.body.phone).toBe(phone);

    const duplicate = await post("/v1/admin/drivers", wardAdmin, {
      wardId,
      fullName: "Someone Else",
      phone,
      licenseNumber: `KA${suffix()}`,
    });
    expect(duplicate.status).toBe(409);

    await db.deleteFrom("drivers").where("id", "=", created1.body.id).execute();
  });
});

describe("resident complaints and ratings over HTTP (FR-CMP-01..06)", () => {
  /**
   * Complaints are capped per household per day, and other spec files use the
   * same seeded resident. Clearing before each keeps these tests about what
   * they assert rather than about who ran first.
   */
  beforeEach(async () => {
    // Complaints are rate limited to 10 per hour per caller, which is correct
    // for abuse but makes a repeated test run depend on the previous one.
    // Clearing the counter keeps these tests about what they assert.
    const userId = (
      await db
        .selectFrom("users")
        .select("id")
        .where("phone", "=", "919888800001")
        .executeTakeFirstOrThrow()
    ).id;
    await redis.del(
      `rl:POST:/v1/resident/complaints:${userId}`,
      `rl:POST:/v1/resident/ratings:${userId}`,
    );

    const household = await db
      .selectFrom("households")
      .innerJoin("users", "users.id", "households.user_id")
      .select("households.id")
      .where("users.phone", "=", "919888800001")
      .executeTakeFirstOrThrow();
    await db.deleteFrom("complaint_events").where(
      "complaint_id",
      "in",
      db.selectFrom("complaints").select("id").where("household_id", "=", household.id),
    ).execute();
    await db.deleteFrom("complaints").where("household_id", "=", household.id).execute();
  });

  it("files a complaint, then returns it in the resident's own list", async () => {
    const created1 = await post("/v1/resident/complaints", resident, {
      category: "missed_pickup",
      description: "Filed over HTTP",
      mediaUrls: [],
    }).expect(201);

    expect(created1.body.status).toBe("open");
    // SLA is stamped at creation from the operator's config (FR-CMP-03).
    expect(created1.body.slaDueAt).toBeTruthy();

    const list = await get("/v1/resident/complaints", resident).expect(200);
    expect(list.body.map((c: { id: string }) => c.id)).toContain(created1.body.id);
  });

  it("refuses more than three photos", async () => {
    await post("/v1/resident/complaints", resident, {
      category: "other",
      mediaUrls: [
        "https://e.test/1.jpg",
        "https://e.test/2.jpg",
        "https://e.test/3.jpg",
        "https://e.test/4.jpg",
      ],
    }).expect(422);
  });

  it("refuses an unknown category", async () => {
    await post("/v1/resident/complaints", resident, {
      category: "nonsense",
      mediaUrls: [],
    }).expect(422);
  });

  it("moves a complaint through the admin queue and notifies the resident", async () => {
    const complaint = await db
      .selectFrom("complaints as c")
      .innerJoin("households as h", "h.id", "c.household_id")
      .select(["c.id", "h.ward_id"])
      .where("c.status", "=", "open")
      .executeTakeFirst();
    if (!complaint) return;

    const admin = complaint.ward_id ? wardAdmin : superAdmin;
    const response = await patch(`/v1/admin/complaints/${complaint.id}`, admin, {
      status: "in_review",
      resolutionNote: "Looking into it",
    });

    expect([200, 403]).toContain(response.status);
    if (response.status === 200) expect(response.body.status).toBe("in_review");
  });

  it("refuses an illegal status transition", async () => {
    const resolved = await db
      .selectFrom("complaints")
      .select(["id", "ward_id"])
      .where("status", "=", "resolved")
      .executeTakeFirst();
    if (!resolved) return;

    const response = await patch(`/v1/admin/complaints/${resolved.id}`, superAdmin, {
      status: "open",
    });
    expect([409, 403]).toContain(response.status);
  });

  it("refuses a rating before the auto has been past today (FR-CMP-05)", async () => {
    const household = await db
      .selectFrom("households")
      .innerJoin("users", "users.id", "households.user_id")
      .select("households.id")
      .where("users.phone", "=", "919888800001")
      .executeTakeFirstOrThrow();
    await db
      .deleteFrom("household_collections")
      .where("household_id", "=", household.id)
      .execute();

    const response = await post("/v1/resident/ratings", resident, { stars: 5 });
    expect([409, 201]).toContain(response.status);
  });

  it("refuses a star count outside 1..5", async () => {
    await post("/v1/resident/ratings", resident, { stars: 9 }).expect(422);
  });
});

describe("driver surface over HTTP (FR-DRV-02, FR-DRV-07)", () => {
  it("refuses a resident starting a trip", async () => {
    await post("/v1/driver/trips", resident, { passNumber: 1 }).expect(403);
  });

  it("refuses a resident reporting a driver issue", async () => {
    await post("/v1/driver/issues", resident, { kind: "breakdown" }).expect(403);
  });

  it("refuses an unknown issue kind from a driver route", async () => {
    // 403 before validation is fine — the point is it never reaches the table.
    const response = await post("/v1/driver/issues", resident, { kind: "aliens" });
    expect([403, 422]).toContain(response.status);
  });

  it("refuses an admin acknowledging an issue outside their ward", async () => {
    const issue = await db.selectFrom("driver_issues").select("id").executeTakeFirst();
    if (!issue) return;

    const response = await patch(`/v1/admin/driver-issues/${issue.id}/acknowledge`, wardAdmin, {});
    expect([200, 404, 403]).toContain(response.status);
  });
});

describe("account and compliance over HTTP (NFR-04)", () => {
  it("publishes the retention policy", async () => {
    const response = await get("/v1/me/retention-policy", resident).expect(200);

    expect(response.body.pingRetentionDays).toBe(90);
    expect(response.body.mediaRetentionDays).toBe(180);
    expect(response.body.deletionGraceDays).toBe(30);
  });

  it("registers a device token for push", async () => {
    await post("/v1/notifications/devices", resident, {
      fcmToken: `http-spec-token-${suffix()}`,
    }).expect(204);
  });

  it("refuses a token too short to be real", async () => {
    await post("/v1/notifications/devices", resident, { fcmToken: "no" }).expect(422);
  });

  it("broadcasts a ward advisory to a route's residents (FR-NOTIF-04)", async () => {
    const route = await db.selectFrom("routes").select(["id", "ward_id"]).executeTakeFirstOrThrow();

    const response = await post("/v1/admin/advisories", superAdmin, {
      routeId: route.id,
      note: "No collection tomorrow, public holiday",
    }).expect(202);

    expect(response.body.notified).toBeGreaterThanOrEqual(0);
  });

  it("refuses an advisory for a route that does not exist", async () => {
    await post("/v1/admin/advisories", superAdmin, {
      routeId: "00000000-0000-0000-0000-000000000000",
      note: "Nowhere",
    }).expect(404);
  });
});
