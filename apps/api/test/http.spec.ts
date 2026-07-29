import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { Test } from "@nestjs/testing";
import type { INestApplication } from "@nestjs/common";
import request from "supertest";
import { AppModule } from "../src/app.module";
import { ProblemFilter } from "../src/common/filters/problem.filter";
import { createTestDb } from "./helpers/db";

/**
 * The real application over HTTP.
 *
 * Every other spec calls services directly, which leaves controllers, guards,
 * the validation pipe and the audit interceptor unexecuted — and those are
 * where authorization actually lives. A service that refuses correctly is no
 * use if the route never reaches it, or reaches it without a guard.
 */
let app: INestApplication;
const db = createTestDb();

/** Signed-in contexts, obtained the way a real client would. */
let superAdmin: string;
let wardAdmin: string;
let resident: string;

async function login(phone: string, password: string): Promise<string> {
  const response = await request(app.getHttpServer())
    .post("/v1/auth/login")
    .send({ phone, password, deviceId: `http-spec-${phone}` });

  if (response.status !== 200 && response.status !== 201) {
    throw new Error(`login failed for ${phone}: ${response.status} ${response.text}`);
  }
  return response.body.accessToken as string;
}

beforeAll(async () => {
  const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();

  app = moduleRef.createNestApplication({ logger: false });
  // Mirrors main.ts, so the surface under test is the surface that ships.
  app.useGlobalFilters(new ProblemFilter());
  app.setGlobalPrefix("v1");
  await app.init();

  superAdmin = await login("919000000001", "devpassword");
  wardAdmin = await login("919000000002", "devpassword");
  resident = await login("919888800001", "devpassword");
}, 60_000);

afterAll(async () => {
  await app.close();
  await db.destroy();
});

const get = (path: string, token?: string) => {
  const req = request(app.getHttpServer()).get(path);
  return token ? req.set("Authorization", `Bearer ${token}`) : req;
};

describe("authentication is required and enforced", () => {
  it("rejects an unauthenticated request", async () => {
    await get("/v1/resident/home").expect(401);
  });

  it("rejects a malformed bearer token", async () => {
    await get("/v1/resident/home", "not-a-jwt").expect(401);
  });

  it("lets a signed-in resident through", async () => {
    const response = await get("/v1/resident/home", resident).expect(200);
    expect(response.body.household).toBeDefined();
  });

  it("leaves the metrics endpoint public", async () => {
    const response = await get("/v1/metrics").expect(200);
    expect(response.text).toContain("#");
  });
});

describe("role boundaries (FR-WARD-06, FR-RES-07)", () => {
  it("refuses a resident reaching an admin route", async () => {
    await get("/v1/admin/operators", resident).expect(403);
  });

  it("refuses a resident reaching a driver route", async () => {
    await get("/v1/driver/assignment", resident).expect(403);
  });

  it("refuses a ward admin managing operators, which is super-admin work", async () => {
    await get("/v1/admin/operators", wardAdmin).expect(403);
  });

  it("lets a super admin list operators", async () => {
    const response = await get("/v1/admin/operators", superAdmin).expect(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  it("pins a ward admin to their own ward", async () => {
    const wards = await get("/v1/admin/wards", superAdmin).expect(200);
    const mine = await db
      .selectFrom("wards")
      .select("id")
      .where("ward_admin_user_id", "is not", null)
      .executeTakeFirstOrThrow();
    const other = wards.body.find((w: { id: string }) => w.id !== mine.id);
    if (!other) return;

    // The portal's own gate is cosmetic; this is the control that matters.
    await get(`/v1/admin/live/wards/${other.id}`, wardAdmin).expect(403);
  });
});

describe("request validation returns RFC 9457 problems", () => {
  it("rejects a bad body with a problem document, not a stack trace", async () => {
    const response = await request(app.getHttpServer())
      .post("/v1/auth/otp/send")
      .send({ phone: "not-a-phone" })
      .expect(422);

    expect(response.body.status).toBe(422);
    expect(response.body.detail).toBeTruthy();
    expect(response.body.title).toBeTruthy();
  });

  it("does not 500 on a malformed uuid in a path", async () => {
    const response = await get("/v1/admin/live/wards/not-a-uuid", superAdmin);
    // Whatever it decides, it must be a client error rather than a crash.
    expect(response.status).toBeLessThan(500);
  });

  it("reports an unknown route as 404", async () => {
    await get("/v1/no-such-thing", superAdmin).expect(404);
  });
});

describe("resident surface", () => {
  it("serves the home payload the app renders", async () => {
    const response = await get("/v1/resident/home", resident).expect(200);

    expect(response.body).toHaveProperty("household");
    expect(response.body).toHaveProperty("servingAutos");
    expect(response.body).toHaveProperty("canRateToday");
    expect(response.body).toHaveProperty("missedToday");
  });

  it("lists the resident's own complaints", async () => {
    const response = await get("/v1/resident/complaints", resident).expect(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  it("never leaks driver identity to a resident (FR-RES-07)", async () => {
    const response = await get("/v1/resident/home", resident).expect(200);
    const body = JSON.stringify(response.body);

    const drivers = await db.selectFrom("drivers").select(["full_name", "phone"]).execute();
    for (const driver of drivers) {
      expect(body).not.toContain(driver.full_name);
      expect(body).not.toContain(driver.phone);
    }
  });

  it("accepts a settings update and reflects it back", async () => {
    await request(app.getHttpServer())
      .patch("/v1/resident/settings")
      .set("Authorization", `Bearer ${resident}`)
      .send({ notificationRadiusM: 450 })
      .expect(200);

    const response = await get("/v1/resident/home", resident).expect(200);
    expect(response.body.household.notificationRadiusM).toBe(450);
  });

  it("refuses a radius outside the allowed range (FR-RES-05)", async () => {
    await request(app.getHttpServer())
      .patch("/v1/resident/settings")
      .set("Authorization", `Bearer ${resident}`)
      .send({ notificationRadiusM: 5000 })
      .expect(422);
  });
});

describe("admin surface", () => {
  it("lists wards, routes and the review queue", async () => {
    await get("/v1/admin/wards", superAdmin).expect(200);
    await get("/v1/admin/households/review-queue", wardAdmin).expect(200);

    const ward = await db.selectFrom("wards").select("id").executeTakeFirstOrThrow();
    await get(`/v1/admin/routes?wardId=${ward.id}`, superAdmin).expect(200);
  });

  it("serves the city rollup only to a super admin (FR-DASH-02)", async () => {
    const response = await get("/v1/admin/dashboard/city", superAdmin).expect(200);
    expect(response.body.routeCoverage).toBeDefined();

    await get("/v1/admin/dashboard/city", wardAdmin).expect(403);
  });

  it("serves missed pickups to both admin roles (FR-DASH-03)", async () => {
    await get("/v1/admin/dashboard/missed-pickups", superAdmin).expect(200);
    await get("/v1/admin/dashboard/missed-pickups", wardAdmin).expect(200);
  });

  it("serves the live ward view with positions and alerts (FR-DASH-01)", async () => {
    const ward = await db
      .selectFrom("wards")
      .select("id")
      .where("ward_admin_user_id", "is not", null)
      .executeTakeFirstOrThrow();

    const response = await get(`/v1/admin/live/wards/${ward.id}`, wardAdmin).expect(200);
    expect(response.body).toHaveProperty("positions");
    expect(response.body).toHaveProperty("alerts");
  });

  it("lists driver-reported issues for a ward (FR-DRV-07)", async () => {
    const ward = await db
      .selectFrom("wards")
      .select("id")
      .where("ward_admin_user_id", "is not", null)
      .executeTakeFirstOrThrow();

    const response = await get(`/v1/admin/driver-issues/wards/${ward.id}`, wardAdmin).expect(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  it("writes an audit row for a mutation made over HTTP (SC-010)", async () => {
    const before = await auditCount();

    const operator = await request(app.getHttpServer())
      .post("/v1/admin/operators")
      .set("Authorization", `Bearer ${superAdmin}`)
      .send({ name: `HTTP spec ${Date.now()}`, type: "private", config: {} })
      .expect(201);

    // The interceptor writes after the response, so give it a moment.
    await new Promise((resolve) => setTimeout(resolve, 250));
    expect(await auditCount()).toBeGreaterThan(before);

    await db.deleteFrom("operators").where("id", "=", operator.body.id).execute();
  });

  async function auditCount(): Promise<number> {
    const row = await db
      .selectFrom("audit_log")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .executeTakeFirstOrThrow();
    return Number(row.count);
  }
});

describe("auth flows", () => {
  it("sends an OTP, or rate-limits a repeat request", async () => {
    const response = await request(app.getHttpServer())
      .post("/v1/auth/otp/send")
      .send({ phone: `9198888${Math.floor(Math.random() * 90000) + 10000}` });

    // 202 on send; 429 if this phone asked recently. Both are correct, and
    // which one depends on what earlier tests did.
    expect([202, 429]).toContain(response.status);
    if (response.status === 202) {
      expect(response.body.resendAfterSec).toBeGreaterThan(0);
    }
  });

  it("refuses a wrong password without saying which part was wrong", async () => {
    const response = await request(app.getHttpServer())
      .post("/v1/auth/login")
      .send({ phone: "919888800001", password: "wrong-password", deviceId: "x" })
      .expect(401);

    expect(response.body.detail ?? "").not.toMatch(/user|account|exists/i);
  });

  it("rotates a refresh token and invalidates the old one (FR-AUTH-06)", async () => {
    const first = await request(app.getHttpServer())
      .post("/v1/auth/login")
      .send({ phone: "919888800003", password: "devpassword", deviceId: "rotate-spec" })
      .expect(200);

    const rotated = await request(app.getHttpServer())
      .post("/v1/auth/refresh")
      .send({ refreshToken: first.body.refreshToken })
      .expect(200);

    expect(rotated.body.accessToken).toBeTruthy();
    expect(rotated.body.refreshToken).not.toBe(first.body.refreshToken);

    // Reusing a rotated token is the signal of a stolen one.
    await request(app.getHttpServer())
      .post("/v1/auth/refresh")
      .send({ refreshToken: first.body.refreshToken })
      .expect(401);
  });

  it("rejects a Google id token when none can be verified (T074)", async () => {
    // The seam the mobile fake exercises: an unverifiable token must fail
    // closed, not fall through to an account.
    const response = await request(app.getHttpServer())
      .post("/v1/auth/login")
      .send({ googleIdToken: "fake-google-id-token:dev@example.com", deviceId: "x" });

    // Fails closed: an unverifiable token must never yield a session.
    expect(response.status).toBeGreaterThanOrEqual(400);
    expect(response.body.accessToken).toBeUndefined();
  });
});

describe("driver surface", () => {
  it("refuses an admin reaching a driver route", async () => {
    await get("/v1/driver/assignment", superAdmin).expect(403);
  });

  it("serves an assignment to a real driver, or says there is none", async () => {
    const driver = await db
      .selectFrom("drivers")
      .select("user_id")
      .where("user_id", "is not", null)
      .executeTakeFirst();
    if (!driver) return;

    const phone = await db
      .selectFrom("users")
      .select("phone")
      .where("id", "=", driver.user_id!)
      .executeTakeFirstOrThrow();

    let token: string;
    try {
      token = await login(phone.phone, "devpassword");
    } catch {
      return; // seeded driver has no password account
    }

    const response = await get("/v1/driver/assignment", token);
    expect([200, 404, 409]).toContain(response.status);
  });
});
