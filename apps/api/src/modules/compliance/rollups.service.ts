import { Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type { CityRollup, MissedPickup } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";
import { istDay, serviceDateIST, weekdayIST } from "../tracking/trips.service";

/**
 * City-wide numbers for the Super Admin (FR-DASH-02) and the missed-pickup
 * sweep behind them (FR-DASH-03).
 *
 * "Missed" is defined by household_collections, which the resident service
 * writes when an auto passes within COLLECTION_PROXIMITY_M of a house — so the
 * 75 m rule lives in one place rather than being restated here.
 *
 * These are read-only aggregates computed on demand. There is no rollup table:
 * at ~225 wards the queries are cheap, and a materialised copy would be one
 * more thing to keep honest.
 */
@Injectable()
export class RollupsService {
  constructor(@Inject(DB) private readonly db: Db) {}

  async city(serviceDate = serviceDateIST()): Promise<CityRollup> {
    const [trips, coverage, complaints, issues] = await Promise.all([
      this.db
        .selectFrom("trips")
        .select(({ fn }) => [
          fn.countAll<string>().as("total"),
          sql<string>`count(*) FILTER (WHERE status = 'active')`.as("active"),
          sql<string>`count(*) FILTER (WHERE status = 'completed')`.as("completed"),
        ])
        .where(sql<boolean>`service_date = ${serviceDate}::date`)
        .executeTakeFirstOrThrow(),

      // Coverage is per route, not per trip: a route with three passes still
      // counts once, because the question is whether the street was served.
      sql<{ scheduled: string; served: string }>`
        SELECT count(*)::text AS scheduled,
               count(*) FILTER (WHERE EXISTS (
                 SELECT 1 FROM trips t
                 WHERE t.route_id = r.id
                   AND t.service_date = ${serviceDate}::date
                   AND t.status IN ('active', 'completed')
               ))::text AS served
        FROM routes r
        -- ISODOW gives 1..7 for Mon..Sun, matching collection_days. Derived
        -- from the requested date so a past date is measured against its own
        -- schedule rather than today's.
        WHERE EXTRACT(ISODOW FROM ${serviceDate}::date)::int = ANY (r.collection_days)
      `.execute(this.db),

      this.db
        .selectFrom("complaints")
        .select(({ fn }) => [
          fn.countAll<string>().as("total"),
          sql<string>`count(*) FILTER (WHERE status IN ('open', 'in_review'))`.as("open"),
          sql<string>`count(*) FILTER (
            WHERE status IN ('open', 'in_review')
              AND sla_due_at IS NOT NULL AND sla_due_at < now()
          )`.as("breached"),
        ])
        .where(sql<boolean>`created_at >= now() - interval '30 days'`)
        .executeTakeFirstOrThrow(),

      this.db
        .selectFrom("driver_issues")
        .select(({ fn }) => fn.countAll<string>().as("open"))
        .where("acknowledged_at", "is", null)
        .executeTakeFirstOrThrow(),
    ]);

    const scheduled = Number(coverage.rows[0]?.scheduled ?? 0);
    const served = Number(coverage.rows[0]?.served ?? 0);

    return {
      serviceDate,
      trips: {
        total: Number(trips.total),
        active: Number(trips.active),
        completed: Number(trips.completed),
      },
      routeCoverage: {
        scheduled,
        served,
        // Reported as a whole number; a city with no routes scheduled today is
        // 0% covered rather than a division by zero.
        percent: scheduled === 0 ? 0 : Math.round((served / scheduled) * 100),
      },
      complaints: {
        last30Days: Number(complaints.total),
        open: Number(complaints.open),
        slaBreached: Number(complaints.breached),
      },
      openDriverIssues: Number(issues.open),
    };
  }

  /**
   * Households whose collection window has closed today with no auto having
   * come within 75 m (FR-DASH-03).
   *
   * Only fires after the window ends: before that the auto is simply not there
   * yet, and calling that a missed pickup would generate a complaint for every
   * house every morning.
   */
  async missedPickups(wardId?: string, serviceDate = serviceDateIST()): Promise<MissedPickup[]> {
    const weekday = weekdayIST();

    const rows = await sql<{
      household_id: string;
      full_name: string;
      address_line: string;
      route_id: string;
      route_name: string;
      ward_id: string;
      window_end: string;
    }>`
      SELECT h.id AS household_id,
             h.full_name,
             h.address_line,
             r.id AS route_id,
             r.name AS route_name,
             r.ward_id,
             r.window_end::text AS window_end
      FROM households h
      JOIN routes r ON r.id = h.route_id
      WHERE ${weekday} = ANY (r.collection_days)
        AND (${wardId ?? null}::uuid IS NULL OR r.ward_id = ${wardId ?? null}::uuid)
        -- The window has to have closed in IST before this means anything.
        AND (now() AT TIME ZONE 'Asia/Kolkata')::time > r.window_end
        AND NOT EXISTS (
          SELECT 1 FROM household_collections hc
          WHERE hc.household_id = h.id
            AND ${istDay("hc.detected_at")} = ${serviceDate}::date
        )
      ORDER BY r.ward_id, r.name, h.address_line
      LIMIT 500
    `.execute(this.db);

    return rows.rows.map((row) => ({
      householdId: row.household_id,
      fullName: row.full_name,
      addressLine: row.address_line,
      routeId: row.route_id,
      routeName: row.route_name,
      wardId: row.ward_id,
      windowEnd: row.window_end,
      serviceDate,
    }));
  }

  /** Whether this one household was missed today — drives the app's prefill. */
  async missedForHousehold(householdId: string, serviceDate = serviceDateIST()): Promise<boolean> {
    const row = await sql<{ missed: boolean }>`
      SELECT (
        ${weekdayIST()} = ANY (r.collection_days)
        AND (now() AT TIME ZONE 'Asia/Kolkata')::time > r.window_end
        AND NOT EXISTS (
          SELECT 1 FROM household_collections hc
          WHERE hc.household_id = h.id
            AND ${istDay("hc.detected_at")} = ${serviceDate}::date
        )
      ) AS missed
      FROM households h
      JOIN routes r ON r.id = h.route_id
      WHERE h.id = ${householdId}::uuid
    `.execute(this.db);

    return row.rows[0]?.missed ?? false;
  }
}
