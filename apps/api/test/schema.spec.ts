import { afterAll, describe, expect, it } from "vitest";
import { sql, type Kysely } from "kysely";
import { createTestDb, inRollback } from "./helpers/db";
import { multiPolygonFromGeoJson, pointFromLatLng } from "../src/db/geo";
import type { Database } from "../src/db/types";

const db = createTestDb();
afterAll(async () => {
  await db.destroy();
});

/** Unique per call so fixtures never collide with seed data or each other. */
function registrationNumber(): string {
  const letters = Array.from({ length: 2 }, () =>
    String.fromCharCode(65 + Math.floor(Math.random() * 26)),
  ).join("");
  const digits = String(Math.floor(Math.random() * 10_000)).padStart(4, "0");
  return `KA${Math.floor(Math.random() * 90 + 10)}${letters}${digits}`;
}

/** Axis-aligned box as a GeoJSON Polygon, for readable fixtures. */
function box(minLng: number, minLat: number, maxLng: number, maxLat: number) {
  return {
    type: "Polygon" as const,
    coordinates: [
      [
        [minLng, minLat],
        [maxLng, minLat],
        [maxLng, maxLat],
        [minLng, maxLat],
        [minLng, minLat],
      ] as [number, number][],
    ],
  };
}

async function seedWard(trx: Kysely<Database>, area = box(77.58, 12.95, 77.62, 12.99)) {
  const operator = await trx
    .insertInto("operators")
    .values({ name: `Op ${crypto.randomUUID()}`, type: "bbmp" })
    .returning("id")
    .executeTakeFirstOrThrow();

  const ward = await trx
    .insertInto("wards")
    .values({
      operator_id: operator.id,
      name: "Test Ward",
      ward_code: `W-${crypto.randomUUID().slice(0, 8)}`,
      boundary: multiPolygonFromGeoJson(area) as unknown as string,
    })
    .returning("id")
    .executeTakeFirstOrThrow();

  return { operatorId: operator.id, wardId: ward.id };
}

async function insertRoute(
  trx: Kysely<Database>,
  wardId: string,
  area: ReturnType<typeof box>,
): Promise<void> {
  await trx
    .insertInto("routes")
    .values({
      ward_id: wardId,
      name: "Route",
      route_code: `R-${crypto.randomUUID().slice(0, 8)}`,
      serviceable_area: multiPolygonFromGeoJson(area) as unknown as string,
      collection_days: sql`ARRAY[1,3,5]::smallint[]` as unknown as number[],
      window_start: "06:00",
      window_end: "10:00",
    })
    .execute();
}

describe("geo invariants", () => {
  it("rejects overlapping ward boundaries (FR-WARD-05)", async () => {
    await inRollback(db, async (trx) => {
      const { operatorId } = await seedWard(trx);
      await expect(
        trx
          .insertInto("wards")
          .values({
            operator_id: operatorId,
            name: "Overlapping",
            ward_code: "W-OVERLAP",
            boundary: multiPolygonFromGeoJson(
              box(77.6, 12.97, 77.64, 13.01),
            ) as unknown as string,
          })
          .execute(),
      ).rejects.toThrow(/overlaps existing ward/i);
    });
  });

  it("accepts a route contained by its ward", async () => {
    await inRollback(db, async (trx) => {
      const { wardId } = await seedWard(trx);
      await expect(
        insertRoute(trx, wardId, box(77.59, 12.96, 77.6, 12.97)),
      ).resolves.toBeUndefined();
    });
  });

  it("rejects a route crossing the ward edge (FR-ROUTE-01)", async () => {
    await inRollback(db, async (trx) => {
      const { wardId } = await seedWard(trx);
      await expect(insertRoute(trx, wardId, box(77.61, 12.98, 77.7, 13.0))).rejects.toThrow(
        /within its ward boundary/i,
      );
    });
  });

  it("rejects routes overlapping a sibling route (FR-ROUTE-05)", async () => {
    await inRollback(db, async (trx) => {
      const { wardId } = await seedWard(trx);
      await insertRoute(trx, wardId, box(77.59, 12.96, 77.6, 12.97));
      await expect(
        insertRoute(trx, wardId, box(77.595, 12.965, 77.605, 12.975)),
      ).rejects.toThrow(/overlaps existing route/i);
    });
  });
});

describe("assignment history", () => {
  it("allows only one open auto-route assignment per auto (FR-FLEET-02)", async () => {
    await inRollback(db, async (trx) => {
      const { wardId } = await seedWard(trx);
      await insertRoute(trx, wardId, box(77.59, 12.96, 77.6, 12.97));
      const route = await trx
        .selectFrom("routes")
        .select("id")
        .where("ward_id", "=", wardId)
        .executeTakeFirstOrThrow();
      const auto = await trx
        .insertInto("autos")
        .values({ registration_number: registrationNumber(), ward_id: wardId })
        .returning("id")
        .executeTakeFirstOrThrow();

      await trx
        .insertInto("auto_route_assignments")
        .values({ auto_id: auto.id, route_id: route.id })
        .execute();

      await expect(
        trx
          .insertInto("auto_route_assignments")
          .values({ auto_id: auto.id, route_id: route.id })
          .execute(),
      ).rejects.toThrow(/duplicate key|auto_route_active_idx/i);
    });
  });

  it("rejects assigning an auto to a route in another ward", async () => {
    await inRollback(db, async (trx) => {
      const first = await seedWard(trx);
      const second = await seedWard(trx, box(78.1, 13.5, 78.2, 13.6));
      await insertRoute(trx, second.wardId, box(78.12, 13.52, 78.15, 13.55));
      const route = await trx
        .selectFrom("routes")
        .select("id")
        .where("ward_id", "=", second.wardId)
        .executeTakeFirstOrThrow();
      const auto = await trx
        .insertInto("autos")
        .values({ registration_number: registrationNumber(), ward_id: first.wardId })
        .returning("id")
        .executeTakeFirstOrThrow();

      await expect(
        trx
          .insertInto("auto_route_assignments")
          .values({ auto_id: auto.id, route_id: route.id })
          .execute(),
      ).rejects.toThrow(/same ward/i);
    });
  });
});

describe("resident-facing constraints", () => {
  it("enforces one rating per household per collection day (FR-CMP-05)", async () => {
    await inRollback(db, async (trx) => {
      const { wardId } = await seedWard(trx);
      const user = await trx
        .insertInto("users")
        .values({
          phone: `9199${Math.floor(Math.random() * 10_000_000)}`,
          auth_provider: "password",
          password_hash: "x",
          role: "resident",
        })
        .returning("id")
        .executeTakeFirstOrThrow();
      const household = await trx
        .insertInto("households")
        .values({
          user_id: user.id,
          full_name: "Resident",
          address_line: "1 Main Rd",
          house_geo: pointFromLatLng({ lat: 12.96, lng: 77.59 }) as unknown as string,
          ward_id: wardId,
        })
        .returning("id")
        .executeTakeFirstOrThrow();

      await trx
        .insertInto("ratings")
        .values({ household_id: household.id, stars: 5, collection_date: "2026-07-29" })
        .execute();

      await expect(
        trx
          .insertInto("ratings")
          .values({ household_id: household.id, stars: 1, collection_date: "2026-07-29" })
          .execute(),
      ).rejects.toThrow(/duplicate key/i);
    });
  });

  it("journals complaint status transitions automatically (FR-CMP-02)", async () => {
    await inRollback(db, async (trx) => {
      const { wardId } = await seedWard(trx);
      const user = await trx
        .insertInto("users")
        .values({
          phone: `9198${Math.floor(Math.random() * 10_000_000)}`,
          auth_provider: "password",
          password_hash: "x",
          role: "resident",
        })
        .returning("id")
        .executeTakeFirstOrThrow();
      const household = await trx
        .insertInto("households")
        .values({
          user_id: user.id,
          full_name: "Resident",
          address_line: "1 Main Rd",
          house_geo: pointFromLatLng({ lat: 12.96, lng: 77.59 }) as unknown as string,
          ward_id: wardId,
        })
        .returning("id")
        .executeTakeFirstOrThrow();

      const complaint = await trx
        .insertInto("complaints")
        .values({ household_id: household.id, ward_id: wardId, category: "missed_pickup" })
        .returning("id")
        .executeTakeFirstOrThrow();

      await trx
        .updateTable("complaints")
        .set({ status: "in_review" })
        .where("id", "=", complaint.id)
        .execute();

      const events = await trx
        .selectFrom("complaint_events")
        .select(["from_status", "to_status"])
        .where("complaint_id", "=", complaint.id)
        .orderBy("at")
        .execute();

      expect(events).toEqual([
        { from_status: null, to_status: "open" },
        { from_status: "open", to_status: "in_review" },
      ]);
    });
  });
});
