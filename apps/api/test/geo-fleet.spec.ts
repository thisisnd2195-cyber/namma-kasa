import { afterAll, beforeAll, describe, expect, it } from "vitest";
import {
  box,
  buildAdminStack,
  randomRegistration,
  uniqueSuffix,
} from "./helpers/services";

const stack = buildAdminStack();

/**
 * Every run gets its own city. Ward uniqueness and the boundary-overlap check
 * are both scoped by city_id, so parallel or repeated runs cannot collide with
 * each other or with seed data.
 */
const TEST_CITY = `test-${crypto.randomUUID().slice(0, 8)}`;

afterAll(async () => {
  const wards = await stack.db
    .selectFrom("wards")
    .select("id")
    .where("city_id", "=", TEST_CITY)
    .execute();
  const wardIds = wards.map((w) => w.id);
  if (wardIds.length > 0) {
    await stack.db.deleteFrom("trips").where("route_id", "in",
      stack.db.selectFrom("routes").select("id").where("ward_id", "in", wardIds)).execute();
    await stack.db.deleteFrom("routes").where("ward_id", "in", wardIds).execute();
    await stack.db.deleteFrom("drivers").where("ward_id", "in", wardIds).execute();
    await stack.db.deleteFrom("autos").where("ward_id", "in", wardIds).execute();
    await stack.db.deleteFrom("wards").where("id", "in", wardIds).execute();
  }
  await stack.db.deleteFrom("operators").where("name", "like", `%${TEST_CITY}%`).execute();
  await stack.close();
});

let operatorId: string;

beforeAll(async () => {
  const operator = await stack.operators.create({
    name: `Test Operator ${TEST_CITY}`,
    type: "private",
    config: {},
  });
  operatorId = operator.id;
});

/** Far from the seeded Bengaluru wards so fixtures never collide with them. */
let lngCursor = 80;
function freshArea(width = 0.05) {
  const minLng = lngCursor;
  lngCursor += width * 3;
  return box(minLng, 20, minLng + width, 20 + width);
}

/**
 * Returns the ward together with the box it was built from — reading the
 * bounds back out of a MultiPolygon is needless indirection in a test.
 */
async function createWard(width = 0.05) {
  const minLng = lngCursor;
  lngCursor += width * 3;
  const bounds = { minLng, minLat: 20, maxLng: minLng + width, maxLat: 20 + width };
  const ward = await stack.wards.create({
    operatorId,
    name: `Ward ${uniqueSuffix()}`,
    wardCode: `W-${uniqueSuffix()}`,
    cityId: TEST_CITY,
    boundary: box(bounds.minLng, bounds.minLat, bounds.maxLng, bounds.maxLat),
  });
  return { ward, bounds };
}

describe("ward boundaries (FR-WARD-02, FR-WARD-05)", () => {
  it("creates a ward and reads its boundary back as GeoJSON", async () => {
    const { ward } = await createWard();
    const fetched = await stack.wards.get(ward.id);
    expect(fetched.boundary.type).toBe("MultiPolygon");
    expect(fetched.status).toBe("active");
  });

  it("rejects a partially overlapping ward", async () => {
    const { bounds } = await createWard();
    const { minLng, minLat } = bounds;

    await expect(
      stack.wards.create({
        operatorId,
        name: "Overlapping",
        wardCode: `W-${uniqueSuffix()}`,
        cityId: TEST_CITY,
        boundary: box(minLng + 0.02, minLat + 0.02, minLng + 0.07, minLat + 0.07),
      }),
    ).rejects.toThrow(/overlaps existing ward/i);
  });

  /**
   * Regression: ST_Overlaps is false when one polygon sits entirely inside
   * another, so a nested ward used to be accepted.
   */
  it("rejects a ward nested entirely inside another", async () => {
    const { bounds } = await createWard();
    const { minLng, minLat } = bounds;

    await expect(
      stack.wards.create({
        operatorId,
        name: "Nested",
        wardCode: `W-${uniqueSuffix()}`,
        cityId: TEST_CITY,
        boundary: box(minLng + 0.01, minLat + 0.01, minLng + 0.02, minLat + 0.02),
      }),
    ).rejects.toThrow(/overlaps existing ward/i);
  });

  it("reports per-feature accept and reject on bulk import (FR-WARD-04)", async () => {
    const good = freshArea();
    const { bounds } = await createWard();
    const { minLng, minLat } = bounds;

    const report = await stack.wards.import({
      operatorId,
      cityId: TEST_CITY,
      featureCollection: {
        type: "FeatureCollection",
        features: [
          {
            type: "Feature",
            properties: { ward_code: `IMP-${uniqueSuffix()}`, name: "Good" },
            geometry: good,
          },
          {
            type: "Feature",
            properties: { ward_code: `IMP-${uniqueSuffix()}`, name: "Clashing" },
            geometry: box(minLng + 0.01, minLat + 0.01, minLng + 0.02, minLat + 0.02),
          },
          { type: "Feature", properties: { name: "No code" }, geometry: freshArea() },
        ],
      },
    });

    expect(report.accepted).toHaveLength(1);
    expect(report.rejected).toHaveLength(2);
    expect(report.rejected.map((r) => r.reason).join(" ")).toMatch(/overlaps|ward_code/i);
  });
});

describe("routes (FR-ROUTE-01, FR-ROUTE-05)", () => {
  async function wardWithRoute() {
    const { ward, bounds } = await createWard();
    const route = await stack.routes.create({
      wardId: ward.id,
      name: "Route A",
      routeCode: `R-${uniqueSuffix()}`,
      serviceableArea: box(
        bounds.minLng + 0.005,
        bounds.minLat + 0.005,
        bounds.minLng + 0.02,
        bounds.minLat + 0.02,
      ),
      collectionDays: [1, 3, 5],
      windowStart: "06:00",
      windowEnd: "10:00",
      passesPerDay: 2,
      wasteTypeSchedule: { "1": ["wet", "dry"], "3": ["wet"] },
    });
    return { ward, route, bounds };
  }

  it("creates a route inside its ward and preserves the waste schedule", async () => {
    const { route } = await wardWithRoute();
    expect(route.passesPerDay).toBe(2);
    expect(route.collectionDays).toEqual([1, 3, 5]);
    expect(route.wasteTypeSchedule["1"]).toEqual(["wet", "dry"]);
    expect(route.windowStart).toBe("06:00");
  });

  it("rejects a route that leaves its ward", async () => {
    const { ward, bounds } = await wardWithRoute();
    await expect(
      stack.routes.create({
        wardId: ward.id,
        name: "Escaping",
        routeCode: `R-${uniqueSuffix()}`,
        serviceableArea: box(bounds.minLng, bounds.minLat, bounds.maxLng + 0.5, bounds.maxLat),
        collectionDays: [2],
        windowStart: "06:00",
        windowEnd: "10:00",
        passesPerDay: 1,
        wasteTypeSchedule: {},
      }),
    ).rejects.toThrow(/inside its ward/i);
  });

  it("rejects a route nested inside a sibling route", async () => {
    const { ward, bounds } = await wardWithRoute();
    await expect(
      stack.routes.create({
        wardId: ward.id,
        name: "Nested",
        routeCode: `R-${uniqueSuffix()}`,
        serviceableArea: box(
          bounds.minLng + 0.008,
          bounds.minLat + 0.008,
          bounds.minLng + 0.012,
          bounds.minLat + 0.012,
        ),
        collectionDays: [2],
        windowStart: "06:00",
        windowEnd: "10:00",
        passesPerDay: 1,
        wasteTypeSchedule: {},
      }),
    ).rejects.toThrow(/overlaps existing route/i);
  });

  it("rejects a collection window that ends before it starts", async () => {
    const { ward, bounds } = await wardWithRoute();
    await expect(
      stack.routes.create({
        wardId: ward.id,
        name: "Backwards",
        routeCode: `R-${uniqueSuffix()}`,
        serviceableArea: box(
          bounds.minLng + 0.03,
          bounds.minLat + 0.03,
          bounds.minLng + 0.04,
          bounds.minLat + 0.04,
        ),
        collectionDays: [2],
        windowStart: "11:00",
        windowEnd: "07:00",
        passesPerDay: 1,
        wasteTypeSchedule: {},
      }),
    ).rejects.toThrow(/end after it starts/i);
  });
});

describe("fleet assignments (FR-FLEET-02, FR-FLEET-04)", () => {
  async function wardRouteAuto() {
    const { ward, bounds } = await createWard();
    const { minLng, minLat } = bounds;
    const route = await stack.routes.create({
      wardId: ward.id,
      name: "R1",
      routeCode: `R-${uniqueSuffix()}`,
      serviceableArea: box(minLng + 0.005, minLat + 0.005, minLng + 0.015, minLat + 0.015),
      collectionDays: [1],
      windowStart: "06:00",
      windowEnd: "10:00",
      passesPerDay: 1,
      wasteTypeSchedule: {},
    });
    const auto = await stack.fleet.createAuto(
      { registrationNumber: randomRegistration(), wardId: ward.id, photos: [] },
      (await stack.db.selectFrom("users").select("id").executeTakeFirstOrThrow()).id,
    );
    return { ward, route, auto, bounds };
  }

  it("only offers available autos for assignment", async () => {
    const { ward, auto } = await wardRouteAuto();
    const available = await stack.fleet.listAutos(ward.id, true);
    expect(available.map((a) => a.id)).toContain(auto.id);

    await stack.fleet.updateAuto(auto.id, { status: "maintenance" });
    const afterMaintenance = await stack.fleet.listAutos(ward.id, true);
    expect(afterMaintenance.map((a) => a.id)).not.toContain(auto.id);
  });

  it("closes the previous assignment instead of rewriting it", async () => {
    const { ward, route, auto, bounds } = await wardRouteAuto();
    const { minLng, minLat } = bounds;
    const second = await stack.routes.create({
      wardId: ward.id,
      name: "R2",
      routeCode: `R-${uniqueSuffix()}`,
      serviceableArea: box(minLng + 0.02, minLat + 0.02, minLng + 0.03, minLat + 0.03),
      collectionDays: [2],
      windowStart: "06:00",
      windowEnd: "10:00",
      passesPerDay: 1,
      wasteTypeSchedule: {},
    });
    const actor = (await stack.db.selectFrom("users").select("id").executeTakeFirstOrThrow()).id;

    await stack.fleet.assignAutoToRoute(auto.id, route.id, actor);
    await stack.fleet.assignAutoToRoute(auto.id, second.id, actor);

    const history = await stack.fleet.assignmentHistory(auto.id);
    expect(history.routes).toHaveLength(2);
    const open = history.routes.filter((r) => r.effective_to === null);
    expect(open).toHaveLength(1);
    expect(open[0].route_id).toBe(second.id);
  });

  it("refuses to assign an auto to a route in another ward", async () => {
    const first = await wardRouteAuto();
    const second = await wardRouteAuto();
    const actor = (await stack.db.selectFrom("users").select("id").executeTakeFirstOrThrow()).id;

    await expect(
      stack.fleet.assignAutoToRoute(first.auto.id, second.route.id, actor),
    ).rejects.toThrow(/different wards/i);
  });

  it("refuses to retire an auto that is mid-trip", async () => {
    const { route, auto } = await wardRouteAuto();
    const driver = await stack.fleet.createDriver({
      wardId: route.wardId,
      fullName: "Trip Driver",
      phone: `9197${Math.floor(Math.random() * 90_000_000 + 10_000_000)}`.slice(0, 12),
      licenseNumber: "KA0100000000001",
    });

    await stack.db
      .insertInto("trips")
      .values({
        auto_id: auto.id,
        driver_id: driver.id,
        route_id: route.id,
        pass_number: 1,
        service_date: new Date().toISOString().slice(0, 10),
      })
      .execute();

    await expect(stack.fleet.updateAuto(auto.id, { status: "retired" })).rejects.toThrow(
      /active trip/i,
    );
  });
});

describe("operator lifecycle (FR-WARD-01)", () => {
  it("blocks retiring an operator that still runs active wards", async () => {
    const operator = await stack.operators.create({
      name: `Retiring ${TEST_CITY}`,
      type: "private",
      config: {},
    });
    await stack.wards.create({
      operatorId: operator.id,
      name: "Held ward",
      wardCode: `W-${uniqueSuffix()}`,
      cityId: TEST_CITY,
      boundary: freshArea(),
    });

    await expect(stack.operators.update(operator.id, { status: "retired" })).rejects.toThrow(
      /active ward/i,
    );
  });
});
