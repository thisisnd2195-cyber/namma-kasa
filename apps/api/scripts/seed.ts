/**
 * Development seed: the smallest world in which every user story is testable —
 * one operator, two wards, one route with households inside it, one auto, and a
 * pre-provisioned driver. Idempotent: re-running truncates and rebuilds.
 *
 *   pnpm --filter @namma-kasa/api seed
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import * as argon2 from "argon2";
import { Kysely, PostgresDialect, sql } from "kysely";
import { Pool } from "pg";
import type { Database } from "../src/db/types";

const DATABASE_URL =
  process.env.DATABASE_URL ?? "postgres://nammakasa:devpassword@localhost:5433/nammakasa";

const DEV_PASSWORD = "devpassword";
const SUPER_ADMIN_PHONE = "919000000001";
const WARD_ADMIN_PHONE = "919000000002";
const DRIVER_PHONE = "919999900001";
const RESIDENT_PHONES = ["919888800001", "919888800002", "919888800003"];

const db = new Kysely<Database>({
  dialect: new PostgresDialect({ pool: new Pool({ connectionString: DATABASE_URL }) }),
});

function wardFixture(code: string) {
  const collection = JSON.parse(
    readFileSync(join(__dirname, "..", "fixtures", "wards-sample.geojson"), "utf8"),
  ) as {
    features: { properties: { ward_code: string; name: string }; geometry: unknown }[];
  };
  const feature = collection.features.find((f) => f.properties.ward_code === code);
  if (!feature) throw new Error(`Ward fixture ${code} not found`);
  return feature;
}

const multi = (geometry: unknown) =>
  sql<string>`ST_Multi(ST_SetSRID(ST_GeomFromGeoJSON(${JSON.stringify(geometry)}), 4326))`;
const point = (lng: number, lat: number) =>
  sql<string>`ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)`;

async function main(): Promise<void> {
  await sql`TRUNCATE operators, users, wards, routes, autos, drivers,
    auto_route_assignments, driver_auto_assignments, households, trips,
    route_pass_days, location_pings, household_collections, media_uploads,
    complaints, complaint_events, ratings, notifications, audit_log,
    refresh_tokens, device_tokens RESTART IDENTITY CASCADE`.execute(db);

  const passwordHash = await argon2.hash(DEV_PASSWORD, { type: argon2.argon2id });

  const operator = await db
    .insertInto("operators")
    .values({ name: "BBMP Solid Waste Management", type: "bbmp" })
    .returningAll()
    .executeTakeFirstOrThrow();

  const superAdmin = await db
    .insertInto("users")
    .values({
      phone: SUPER_ADMIN_PHONE,
      auth_provider: "password",
      password_hash: passwordHash,
      role: "super_admin",
      consented_at: new Date(),
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  const wardAdmin = await db
    .insertInto("users")
    .values({
      phone: WARD_ADMIN_PHONE,
      auth_provider: "password",
      password_hash: passwordHash,
      role: "ward_admin",
      consented_at: new Date(),
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  const primary = wardFixture("W110");
  const secondary = wardFixture("W154");

  const ward = await db
    .insertInto("wards")
    .values({
      operator_id: operator.id,
      name: primary.properties.name,
      ward_code: primary.properties.ward_code,
      boundary: multi(primary.geometry),
      ward_admin_user_id: wardAdmin.id,
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  await db
    .insertInto("wards")
    .values({
      operator_id: operator.id,
      name: secondary.properties.name,
      ward_code: secondary.properties.ward_code,
      boundary: multi(secondary.geometry),
    })
    .execute();

  // Sits inside W110 and contains the simulate-trip trail.
  const route = await db
    .insertInto("routes")
    .values({
      ward_id: ward.id,
      name: "Shanthala Nagar A",
      route_code: "R110-A",
      serviceable_area: multi({
        type: "Polygon",
        coordinates: [
          [
            [77.588, 12.958],
            [77.6, 12.958],
            [77.6, 12.972],
            [77.588, 12.972],
            [77.588, 12.958],
          ],
        ],
      }),
      collection_days: sql`ARRAY[1,2,3,4,5,6]::smallint[]` as unknown as number[],
      window_start: "06:00",
      window_end: "10:00",
      passes_per_day: 2,
      waste_type_schedule: {
        "1": ["wet", "dry"],
        "2": ["wet"],
        "3": ["wet", "sanitary"],
        "4": ["wet"],
        "5": ["wet", "dry"],
        "6": ["wet"],
      },
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  const auto = await db
    .insertInto("autos")
    .values({
      registration_number: "KA01AB1234",
      capacity_kg: 500,
      ward_id: ward.id,
      status: "assigned",
      onboarded_by: wardAdmin.id,
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  // user_id stays null: the driver claims it by registering with this phone.
  const driver = await db
    .insertInto("drivers")
    .values({
      ward_id: ward.id,
      full_name: "Ramesh Kumar",
      phone: DRIVER_PHONE,
      license_number: "KA0120180001234",
      emergency_contact: "919000000009",
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  await db
    .insertInto("auto_route_assignments")
    .values({ auto_id: auto.id, route_id: route.id, assigned_by: wardAdmin.id })
    .execute();
  await db
    .insertInto("driver_auto_assignments")
    .values({ driver_id: driver.id, auto_id: auto.id, assigned_by: wardAdmin.id })
    .execute();

  // Three households along the trail, plus one outside every route so the
  // review queue has something in it from the first run.
  const homes: [number, number][] = [
    [77.5925, 12.9612],
    [77.5962, 12.964],
    [77.5938, 12.9688],
  ];

  for (const [index, phone] of RESIDENT_PHONES.entries()) {
    const user = await db
      .insertInto("users")
      .values({
        phone,
        auth_provider: "password",
        password_hash: passwordHash,
        role: "resident",
        locale: index === 0 ? "kn" : "en",
        consented_at: new Date(),
      })
      .returningAll()
      .executeTakeFirstOrThrow();

    const [lng, lat] = homes[index];
    await db
      .insertInto("households")
      .values({
        user_id: user.id,
        full_name: `Resident ${index + 1}`,
        address_line: `${index + 1} Sample Cross, Shanthala Nagar`,
        house_geo: point(lng, lat),
        ward_id: ward.id,
        route_id: route.id,
        mapping_status: "auto",
      })
      .execute();
  }

  const unmappedUser = await db
    .insertInto("users")
    .values({
      phone: "919888800009",
      auth_provider: "password",
      password_hash: passwordHash,
      role: "resident",
      consented_at: new Date(),
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  await db
    .insertInto("households")
    .values({
      user_id: unmappedUser.id,
      full_name: "Unmapped Resident",
      address_line: "9 Edge Road",
      house_geo: point(77.6135, 12.9805),
      ward_id: ward.id,
      route_id: null,
      mapping_status: "pending_review",
    })
    .execute();

  console.log(`
Seed complete.

  Ward            ${ward.name} (${ward.id})
  Route           ${route.name} (${route.id}) — 2 passes/day, 06:00–10:00
  Auto            ${auto.registration_number}
  Driver phone    ${DRIVER_PHONE}  (pre-provisioned, no account yet)

  Super admin     ${SUPER_ADMIN_PHONE} / ${DEV_PASSWORD}
  Ward admin      ${WARD_ADMIN_PHONE} / ${DEV_PASSWORD}
  Residents       ${RESIDENT_PHONES.join(", ")} / ${DEV_PASSWORD}
  Review queue    1 household pending route assignment
`);
  await db.destroy();
}

main().catch(async (error) => {
  console.error(error);
  await db.destroy();
  process.exit(1);
});
