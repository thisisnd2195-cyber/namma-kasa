import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { sql } from "kysely";
import { createTestDb } from "./helpers/db";
import { RollupsService } from "../src/modules/compliance/rollups.service";
import { IssuesService } from "../src/modules/issues/issues.service";
import { NotifyService } from "../src/modules/notify/notify.service";
import type { PushMessage, PushSender } from "../src/modules/notify/push-sender";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

const db = createTestDb();
const rollups = new RollupsService(db);

class SilentPushSender implements PushSender {
  async send(message: PushMessage) {
    return { delivered: message.tokens.length, failedTokens: [] };
  }
}

const issues = new IssuesService(db, new NotifyService(db, new SilentPushSender()));

/**
 * These tests move collection windows around, and the fixtures are shared with
 * every other spec file. Snapshot the routes table first and put it back after,
 * so a run of this file cannot change what tracking.spec.ts sees.
 */
let routeSnapshot: {
  id: string;
  window_start: string;
  window_end: string;
  collection_days: number[];
}[] = [];

beforeAll(async () => {
  routeSnapshot = await db
    .selectFrom("routes")
    .select([
      "id",
      sql<string>`window_start::text`.as("window_start"),
      sql<string>`window_end::text`.as("window_end"),
      "collection_days",
    ])
    .execute();
});

afterAll(async () => {
  for (const route of routeSnapshot) {
    await sql`
      UPDATE routes
      SET window_start = ${route.window_start}::time,
          window_end = ${route.window_end}::time,
          collection_days = ${route.collection_days}::int[]
      WHERE id = ${route.id}::uuid
    `.execute(db);
  }
  await db.destroy();
});

describe("city rollups (FR-DASH-02)", () => {
  it("reports coverage as a percentage of routes scheduled today", async () => {
    const rollup = await rollups.city();

    expect(rollup.serviceDate).toBe(serviceDateIST());
    expect(rollup.routeCoverage.served).toBeLessThanOrEqual(rollup.routeCoverage.scheduled);
    expect(rollup.routeCoverage.percent).toBeGreaterThanOrEqual(0);
    expect(rollup.routeCoverage.percent).toBeLessThanOrEqual(100);
  });

  it("never divides by zero when nothing is scheduled", async () => {
    // A service date with no routes scheduled still has to produce a number.
    const rollup = await rollups.city("1900-01-01");
    expect(Number.isFinite(rollup.routeCoverage.percent)).toBe(true);
    expect(rollup.trips.total).toBe(0);
  });

  it("counts only open complaints as breached", async () => {
    const rollup = await rollups.city();
    expect(rollup.complaints.slaBreached).toBeLessThanOrEqual(rollup.complaints.open);
  });
});

describe("missed-pickup detection (FR-DASH-03)", () => {
  it("does not accuse a route whose window is still open", async () => {
    // Push every route's window to the end of the day: nothing has been missed
    // yet, because the auto still has hours to come.
    await sql`UPDATE routes SET window_start = '00:01', window_end = '23:59'`.execute(db);
    const missed = await rollups.missedPickups();
    expect(missed).toHaveLength(0);
  });

  it("lists a household once its window has closed with no collection", async () => {
    const household = await db
      .selectFrom("households")
      .select(["id", "route_id"])
      .where("route_id", "is not", null)
      .executeTakeFirstOrThrow();

    // Window closed a minute ago, and today is a collection day for it.
    await sql`
      UPDATE routes
      SET window_start = '00:01',
          window_end = ((now() AT TIME ZONE 'Asia/Kolkata') - interval '1 minute')::time,
          collection_days = ARRAY[1,2,3,4,5,6,7]
      WHERE id = ${household.route_id}::uuid
    `.execute(db);
    await db
      .deleteFrom("household_collections")
      .where("household_id", "=", household.id)
      .execute();

    const missed = await rollups.missedPickups();
    expect(missed.map((m) => m.householdId)).toContain(household.id);

    // And the per-household form the app uses agrees with the ward list.
    expect(await rollups.missedForHousehold(household.id)).toBe(true);
  });

  it("clears once a collection is recorded for the day", async () => {
    const household = await db
      .selectFrom("households")
      .select(["id", "route_id"])
      .where("route_id", "is not", null)
      .executeTakeFirstOrThrow();

    const trip = await db.selectFrom("trips").select(["id", "route_id"]).executeTakeFirstOrThrow();
    await db
      .insertInto("household_collections")
      .values({
        household_id: household.id,
        trip_id: trip.id,
        route_id: trip.route_id,
        pass_number: 1,
        detected_at: new Date(),
      })
      .onConflict((oc) => oc.doNothing())
      .execute();

    expect(await rollups.missedForHousehold(household.id)).toBe(false);
  });
});

describe("driver issues (FR-DRV-07)", () => {
  async function seededDriverUser() {
    return db
      .selectFrom("drivers")
      .select(["id", "user_id", "ward_id"])
      .where("user_id", "is not", null)
      .executeTakeFirstOrThrow();
  }

  it("records a report and returns it to the ward queue unacknowledged", async () => {
    const driver = await seededDriverUser();
    const issue = await issues.report(driver.user_id!, {
      kind: "breakdown",
      note: "Rear tyre gone",
    });

    expect(issue.acknowledgedAt).toBeNull();

    const queue = await issues.listForWard(driver.ward_id);
    expect(queue.map((i) => i.id)).toContain(issue.id);
    expect(queue.find((i) => i.id === issue.id)?.note).toBe("Rear tyre gone");
  });

  it("acknowledges an issue in the admin's own ward", async () => {
    const driver = await seededDriverUser();
    const issue = await issues.report(driver.user_id!, { kind: "road_blocked" });

    const acked = await issues.acknowledge(issue.id, driver.ward_id);
    expect(acked.acknowledgedAt).not.toBeNull();
  });

  it("refuses to acknowledge an issue outside the admin's ward", async () => {
    const driver = await seededDriverUser();
    const issue = await issues.report(driver.user_id!, { kind: "other" });

    const otherWard = await db
      .selectFrom("wards")
      .select("id")
      .where("id", "!=", driver.ward_id)
      .executeTakeFirst();
    if (!otherWard) return; // single-ward fixture; nothing to prove

    await expect(issues.acknowledge(issue.id, otherWard.id)).rejects.toThrow(/not found/i);
  });
});
