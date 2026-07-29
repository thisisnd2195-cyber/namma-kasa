import { afterAll, describe, expect, it } from "vitest";
import Redis from "ioredis";
import { COLLECTION_PROXIMITY_M } from "@namma-kasa/shared";
import { createTestDb } from "./helpers/db";
import { ResidentService } from "../src/modules/resident/resident.service";
import { HouseholdMappingService } from "../src/modules/geo/household-mapping.service";
import { IngestService } from "../src/modules/tracking/ingest.service";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

const db = createTestDb();
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");
const mapping = new HouseholdMappingService(db);
const ingest = new IngestService(db, redis);
const resident = new ResidentService(db, mapping, ingest);

afterAll(async () => {
  await db.destroy();
  redis.disconnect();
});

async function seededResident() {
  const row = await db
    .selectFrom("households as h")
    .innerJoin("users as u", "u.id", "h.user_id")
    .select(["h.id as householdId", "u.id as userId", "h.route_id as routeId"])
    .where("h.route_id", "is not", null)
    .executeTakeFirstOrThrow();
  return row;
}

async function activeTripOnRoute(routeId: string) {
  const assignment = await db
    .selectFrom("auto_route_assignments as ar")
    .innerJoin("autos as a", "a.id", "ar.auto_id")
    .innerJoin("driver_auto_assignments as da", (join) =>
      join.onRef("da.auto_id", "=", "a.id").on("da.effective_to", "is", null),
    )
    .select(["a.id as autoId", "da.driver_id as driverId"])
    .where("ar.route_id", "=", routeId)
    .where("ar.effective_to", "is", null)
    .executeTakeFirstOrThrow();

  await db
    .updateTable("trips")
    .set({ status: "aborted", ended_at: new Date(), end_reason: "admin" })
    .where("auto_id", "=", assignment.autoId)
    .where("status", "=", "active")
    .execute();

  return db
    .insertInto("trips")
    .values({
      auto_id: assignment.autoId,
      driver_id: assignment.driverId,
      route_id: routeId,
      pass_number: 1,
      service_date: serviceDateIST(),
    })
    .returningAll()
    .executeTakeFirstOrThrow();
}

describe("resident home (FR-RES-01, FR-RES-02)", () => {
  it("reports the route, schedule and mapping status", async () => {
    const { userId } = await seededResident();
    const home = await resident.home(userId);

    expect(home.household.mappingStatus).toBe("auto");
    expect(home.route).not.toBeNull();
    expect(home.route!.passesPerDay).toBeGreaterThanOrEqual(1);
    expect(home.route!.windowStart).toMatch(/^\d{2}:\d{2}$/);
  });

  /**
   * The one privacy rule the resident surface cannot get wrong: an auto is
   * identified by its plate, never by the person driving it.
   */
  it("never exposes driver identity", async () => {
    const { userId } = await seededResident();
    const serialised = JSON.stringify(await resident.home(userId)).toLowerCase();

    for (const forbidden of ["driverid", "licensenumber", "emergencycontact"]) {
      expect(serialised).not.toContain(forbidden);
    }
  });

  it("puts an unmapped household in a pending state rather than guessing", async () => {
    const pending = await db
      .selectFrom("households as h")
      .innerJoin("users as u", "u.id", "h.user_id")
      .select("u.id as userId")
      .where("h.route_id", "is", null)
      .executeTakeFirst();
    if (!pending) return;

    const home = await resident.home(pending.userId);
    expect(home.route).toBeNull();
    expect(home.servingAutos).toEqual([]);
    expect(home.household.mappingStatus).toBe("pending_review");
  });
});

describe("collection events (Clarifications CHK002)", () => {
  it("records a household once when the auto passes within range", async () => {
    const { householdId, routeId } = await seededResident();
    const trip = await activeTripOnRoute(routeId!);

    const house = await db
      .selectFrom("households")
      .select([
        (eb) => eb.fn<number>("ST_Y", ["house_geo"]).as("lat"),
        (eb) => eb.fn<number>("ST_X", ["house_geo"]).as("lng"),
      ])
      .where("id", "=", householdId)
      .executeTakeFirstOrThrow();

    const served = await resident.recordCollectionsNear(trip.id, routeId!, 1, {
      lat: house.lat,
      lng: house.lng,
    });
    expect(served).toContain(householdId);

    // Passing the same house again during one trip is still one collection.
    const again = await resident.recordCollectionsNear(trip.id, routeId!, 1, {
      lat: house.lat,
      lng: house.lng,
    });
    expect(again).not.toContain(householdId);
  });

  it("ignores a pass that stays outside the proximity radius", async () => {
    const { householdId, routeId } = await seededResident();
    const trip = await activeTripOnRoute(routeId!);

    const house = await db
      .selectFrom("households")
      .select([
        (eb) => eb.fn<number>("ST_Y", ["house_geo"]).as("lat"),
        (eb) => eb.fn<number>("ST_X", ["house_geo"]).as("lng"),
      ])
      .where("id", "=", householdId)
      .executeTakeFirstOrThrow();

    // ~1.1 km north: well beyond the 75 m threshold.
    const served = await resident.recordCollectionsNear(trip.id, routeId!, 1, {
      lat: house.lat + 0.01,
      lng: house.lng,
    });
    expect(served).not.toContain(householdId);
    expect(COLLECTION_PROXIMITY_M).toBe(75);
  });

  it("surfaces the collection as last-collected on the home screen", async () => {
    const { userId, householdId, routeId } = await seededResident();
    const trip = await activeTripOnRoute(routeId!);
    const house = await db
      .selectFrom("households")
      .select([
        (eb) => eb.fn<number>("ST_Y", ["house_geo"]).as("lat"),
        (eb) => eb.fn<number>("ST_X", ["house_geo"]).as("lng"),
      ])
      .where("id", "=", householdId)
      .executeTakeFirstOrThrow();

    await resident.recordCollectionsNear(trip.id, routeId!, 1, {
      lat: house.lat,
      lng: house.lng,
    });

    const home = await resident.home(userId);
    // Regression: pg returns numeric as a string, which produced an Invalid
    // Date here and a home screen that claimed a collection with no timestamp.
    expect(home.lastCollectedAt).toBeInstanceOf(Date);
    expect(Number.isNaN(home.lastCollectedAt!.getTime())).toBe(false);
  });
});

describe("household edits (FR-RES-04)", () => {
  it("re-maps the household when the pin moves outside every route", async () => {
    const { userId } = await seededResident();
    const before = await resident.householdFor(userId);

    const moved = await resident.updateHousehold(userId, {
      pin: { lat: 13.2, lng: 77.85 }, // inside Bengaluru, outside any route
    });
    expect(moved.routeId).toBeNull();
    expect(moved.mappingStatus).toBe("pending_review");

    // Put it back so the seed stays usable for other suites.
    const restored = await resident.updateHousehold(userId, { pin: before.pin });
    expect(restored.routeId).toBe(before.routeId);
    expect(restored.mappingStatus).toBe("auto");
  });

  it("keeps the notification radius inside the allowed range", async () => {
    const { userId } = await seededResident();
    const updated = await resident.updateSettings(userId, { notificationRadiusM: 500 });
    expect(updated.notificationRadiusM).toBe(500);
    await resident.updateSettings(userId, { notificationRadiusM: 300 });
  });
});
