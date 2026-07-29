/**
 * Replays a GPS trail as a real collection run: starts a trip for the seeded
 * driver, publishes pings over MQTT at the cadence a phone would, then ends it.
 *
 * This is the only practical way to exercise ingest, the live map, geofencing
 * and notifications without driving an actual auto around Bengaluru.
 *
 *   pnpm --filter @namma-kasa/api simulate-trip -- --pass 1 --speed 20
 *
 * Flags:
 *   --route <uuid>     route to run (default: the seeded route)
 *   --trail <path>     GeoJSON LineString (default: fixtures/trail-route1.geojson)
 *   --pass <n>         pass number (default: next unstarted pass)
 *   --speed <n>        playback multiplier (default 10; 1 = real time)
 *   --interval <sec>   emit cadence in trail-time seconds (default 5)
 *   --drop-after <n>   stop publishing after n pings, to test tracking-dropped
 *   --keep-open        leave the trip active at the end
 */
import { readFileSync } from "node:fs";
import { join } from "node:path";
import mqtt from "mqtt";
import { Kysely, PostgresDialect } from "kysely";
import { Pool } from "pg";
import { ConfigService } from "@nestjs/config";
import type { Database } from "../src/db/types";
import { MqttTokenService } from "../src/modules/tracking/mqtt-token.service";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

const DATABASE_URL =
  process.env.DATABASE_URL ?? "postgres://nammakasa:devpassword@localhost:5433/nammakasa";
const MQTT_URL = process.env.MQTT_URL ?? "mqtt://localhost:1883";

function flag(name: string): string | undefined {
  const index = process.argv.indexOf(`--${name}`);
  return index === -1 ? undefined : process.argv[index + 1];
}
const hasFlag = (name: string): boolean => process.argv.includes(`--${name}`);

const db = new Kysely<Database>({
  dialect: new PostgresDialect({ pool: new Pool({ connectionString: DATABASE_URL }) }),
});

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/** Walks the trail at a constant speed, emitting a point every `interval`. */
function* walk(
  coordinates: [number, number][],
  intervalSec: number,
  metersPerSecond: number,
): Generator<{ lat: number; lng: number; heading: number }> {
  const step = intervalSec * metersPerSecond;
  let carried = 0;

  for (let i = 0; i < coordinates.length - 1; i += 1) {
    const [lng1, lat1] = coordinates[i];
    const [lng2, lat2] = coordinates[i + 1];
    const segment = haversine(lat1, lng1, lat2, lng2);
    const heading = bearing(lat1, lng1, lat2, lng2);

    let travelled = carried;
    while (travelled <= segment) {
      const t = segment === 0 ? 0 : travelled / segment;
      yield { lat: lat1 + (lat2 - lat1) * t, lng: lng1 + (lng2 - lng1) * t, heading };
      travelled += step;
    }
    carried = travelled - segment;
  }
}

function haversine(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.sin(dLng / 2) ** 2 * Math.cos(toRad(lat1)) * Math.cos(toRad(lat2));
  return 2 * 6_371_000 * Math.asin(Math.sqrt(h));
}

function bearing(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const y = Math.sin(toRad(lng2 - lng1)) * Math.cos(toRad(lat2));
  const x =
    Math.cos(toRad(lat1)) * Math.sin(toRad(lat2)) -
    Math.sin(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.cos(toRad(lng2 - lng1));
  return (((Math.atan2(y, x) * 180) / Math.PI) + 360) % 360;
}

async function main(): Promise<void> {
  const intervalSec = Number(flag("interval") ?? 5);
  const speedup = Number(flag("speed") ?? 10);
  const dropAfter = flag("drop-after") ? Number(flag("drop-after")) : Infinity;
  const kmh = 12; // a collection auto crawls

  const trailPath = flag("trail") ?? join(__dirname, "..", "fixtures", "trail-route1.geojson");
  const trail = JSON.parse(readFileSync(trailPath, "utf8")) as {
    geometry: { coordinates: [number, number][] };
  };

  const route = flag("route")
    ? await db
        .selectFrom("routes")
        .selectAll()
        .where("id", "=", flag("route") as string)
        .executeTakeFirstOrThrow()
    : await db.selectFrom("routes").selectAll().orderBy("route_code").executeTakeFirstOrThrow();

  const assignment = await db
    .selectFrom("auto_route_assignments as ar")
    .innerJoin("autos as a", "a.id", "ar.auto_id")
    .innerJoin("driver_auto_assignments as da", (join) =>
      join.onRef("da.auto_id", "=", "a.id").on("da.effective_to", "is", null),
    )
    .select(["a.id as autoId", "a.registration_number as reg", "da.driver_id as driverId"])
    .where("ar.route_id", "=", route.id)
    .where("ar.effective_to", "is", null)
    .executeTakeFirst();

  if (!assignment) {
    throw new Error(`Route ${route.route_code} has no auto with a driver assigned.`);
  }

  const serviceDate = serviceDateIST();
  const settled = await db
    .selectFrom("route_pass_days")
    .select(["pass_number", "status"])
    .where("route_id", "=", route.id)
    .where("service_date", "=", serviceDate)
    .execute();

  const passNumber = flag("pass")
    ? Number(flag("pass"))
    : (Array.from({ length: route.passes_per_day }, (_, i) => i + 1).find(
        (n) => !settled.some((s) => s.pass_number === n && s.status !== "pending"),
      ) ?? 1);

  // Clear any trip left active by a previous run, so the simulator is re-runnable.
  await db
    .updateTable("trips")
    .set({ status: "aborted", end_reason: "admin", ended_at: new Date() })
    .where("auto_id", "=", assignment.autoId)
    .where("status", "=", "active")
    .execute();

  const trip = await db
    .insertInto("trips")
    .values({
      auto_id: assignment.autoId,
      driver_id: assignment.driverId,
      route_id: route.id,
      pass_number: passNumber,
      service_date: serviceDate,
    })
    .returningAll()
    .executeTakeFirstOrThrow();

  await db
    .insertInto("route_pass_days")
    .values({
      route_id: route.id,
      service_date: serviceDate,
      pass_number: passNumber,
      status: "active",
      trip_id: trip.id,
    })
    .onConflict((oc) =>
      oc
        .columns(["route_id", "service_date", "pass_number"])
        .doUpdateSet({ status: "active", trip_id: trip.id, updated_at: new Date() }),
    )
    .execute();

  console.log(
    `Trip ${trip.id}\n  route ${route.name} (${route.route_code}) pass ${passNumber}\n  auto  ${assignment.reg}\n  mqtt  ${MQTT_URL} topic trips/${trip.id}/pings\n`,
  );

  // The broker rejects anonymous publishers, so the simulator authenticates
  // exactly as a real device does: a per-trip token whose ACL grants publish to
  // this trip's topic and nothing else.
  const credentials = new MqttTokenService(
    new ConfigService({ JWT_SECRET: process.env.JWT_SECRET ?? "dev-only-change-me" }),
  ).issue(assignment.driverId, trip.id);

  const client = await mqtt.connectAsync(MQTT_URL, {
    clientId: `simulate-trip-${process.pid}`,
    username: credentials.username,
    password: credentials.password,
  });

  const points = [...walk(trail.geometry.coordinates, intervalSec, (kmh * 1000) / 3600)];
  const startedAt = Date.now();
  let seq = 0;

  for (const point of points) {
    if (seq >= dropAfter) {
      console.log(`\nStopped publishing after ${seq} pings (--drop-after).`);
      console.log("The ward dashboard should raise a tracking-dropped alert within 3 minutes.");
      break;
    }

    const payload = {
      lat: Number(point.lat.toFixed(6)),
      lng: Number(point.lng.toFixed(6)),
      speed: kmh / 3.6,
      heading: Math.round(point.heading),
      accuracy: 6 + Math.random() * 4,
      recordedAt: new Date(startedAt + seq * intervalSec * 1000).toISOString(),
      seq,
    };

    await client.publishAsync(`trips/${trip.id}/pings`, JSON.stringify(payload), { qos: 1 });
    seq += 1;
    process.stdout.write(`\r  published ${seq}/${points.length} pings`);
    await sleep((intervalSec * 1000) / speedup);
  }

  console.log();

  if (!hasFlag("keep-open") && seq >= points.length) {
    await db
      .updateTable("trips")
      .set({ status: "completed", end_reason: "driver", ended_at: new Date() })
      .where("id", "=", trip.id)
      .execute();
    await db
      .updateTable("route_pass_days")
      .set({ status: "completed", updated_at: new Date() })
      .where("route_id", "=", route.id)
      .where("service_date", "=", serviceDate)
      .where("pass_number", "=", passNumber)
      .execute();
    console.log("Trip completed.");
  } else {
    console.log("Trip left active.");
  }

  await client.endAsync();
  await db.destroy();
}

main().catch(async (error: unknown) => {
  console.error(error);
  await db.destroy();
  process.exit(1);
});
