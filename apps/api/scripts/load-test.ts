/**
 * Drives synthetic GPS load through the real ingest path to check the SC-006
 * figure: roughly 1,000 pings/second is Bengaluru's worst case (~5,000 autos
 * emitting every 5 seconds).
 *
 *   pnpm --filter @namma-kasa/api load-test -- --autos 200 --seconds 30
 *
 * Reports accepted throughput and ingest latency percentiles. It measures the
 * server's ability to absorb pings, not end-to-end device latency, which needs
 * real handsets.
 */
import { Kysely, PostgresDialect, sql } from "kysely";
import { Pool } from "pg";
import Redis from "ioredis";
import type { Database } from "../src/db/types";
import { IngestService } from "../src/modules/tracking/ingest.service";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

const DATABASE_URL =
  process.env.DATABASE_URL ?? "postgres://nammakasa:devpassword@localhost:5433/nammakasa";

const flag = (name: string, fallback: number): number => {
  const index = process.argv.indexOf(`--${name}`);
  return index === -1 ? fallback : Number(process.argv[index + 1]);
};

const db = new Kysely<Database>({
  dialect: new PostgresDialect({ pool: new Pool({ connectionString: DATABASE_URL, max: 40 }) }),
});
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");
const ingest = new IngestService(db, redis);

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  return sorted[Math.min(sorted.length - 1, Math.floor(sorted.length * p))];
}

async function main(): Promise<void> {
  const autoCount = flag("autos", 100);
  const seconds = flag("seconds", 20);
  const cadenceMs = flag("cadence", 5000);

  const route = await db.selectFrom("routes").selectAll().executeTakeFirstOrThrow();
  const driver = await db.selectFrom("drivers").select("id").executeTakeFirstOrThrow();

  console.log(`Preparing ${autoCount} synthetic autos on ${route.name}…`);

  // Synthetic fleet, torn down afterwards so the seed stays clean.
  const contexts = [];
  for (let i = 0; i < autoCount; i += 1) {
    const registration = `KA99LT${String(i).padStart(4, "0")}`;
    const auto = await db
      .insertInto("autos")
      .values({ registration_number: registration, ward_id: route.ward_id, status: "assigned" })
      .returning("id")
      .executeTakeFirstOrThrow();

    const trip = await db
      .insertInto("trips")
      .values({
        auto_id: auto.id,
        driver_id: driver.id,
        route_id: route.id,
        pass_number: 1,
        service_date: serviceDateIST(),
      })
      .returning("id")
      .executeTakeFirstOrThrow();

    const context = await ingest.contextFor(trip.id);
    if (context) contexts.push(context);
  }

  console.log(`Running ${seconds}s at ${cadenceMs}ms cadence…\n`);

  const latencies: number[] = [];
  let accepted = 0;
  let rejected = 0;
  let seq = 0;
  const startedAt = Date.now();

  while (Date.now() - startedAt < seconds * 1000) {
    const tick = Date.now();
    const batch = contexts.map(async (context, index) => {
      const began = Date.now();
      const result = await ingest.ingest(context, [
        {
          lat: 12.96 + (index % 50) / 10_000 + seq / 100_000,
          lng: 77.59 + (index % 50) / 10_000,
          speed: 3,
          heading: 90,
          accuracy: 8,
          recordedAt: new Date(),
          seq,
        },
      ]);
      latencies.push(Date.now() - began);
      accepted += result.accepted;
      rejected += result.rejected;
    });

    await Promise.all(batch);
    seq += 1;

    const elapsed = Date.now() - tick;
    if (elapsed < cadenceMs) await new Promise((r) => setTimeout(r, cadenceMs - elapsed));
  }

  const totalSeconds = (Date.now() - startedAt) / 1000;
  latencies.sort((a, b) => a - b);

  console.log("Results");
  console.log(`  autos              ${contexts.length}`);
  console.log(`  accepted pings     ${accepted}`);
  console.log(`  rejected pings     ${rejected}`);
  console.log(`  throughput         ${(accepted / totalSeconds).toFixed(1)} pings/sec`);
  console.log(`  ingest p50         ${percentile(latencies, 0.5)} ms`);
  console.log(`  ingest p95         ${percentile(latencies, 0.95)} ms`);
  console.log(`  ingest p99         ${percentile(latencies, 0.99)} ms`);
  console.log("\n  SC-006 target is ~1000 pings/sec; extrapolate from the per-ping cost above.");

  console.log("\nCleaning up synthetic fleet…");
  await sql`DELETE FROM trips WHERE auto_id IN (
    SELECT id FROM autos WHERE registration_number LIKE 'KA99LT%'
  )`.execute(db);
  await sql`DELETE FROM autos WHERE registration_number LIKE 'KA99LT%'`.execute(db);

  await db.destroy();
  redis.disconnect();
}

main().catch(async (error: unknown) => {
  console.error(error);
  await db.destroy();
  redis.disconnect();
  process.exit(1);
});
