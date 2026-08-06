import { Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import { DB, type Db } from "../../db/db.module";
import { serviceDateIST } from "../tracking/trips.service";

/**
 * The per-ward tracking-health numbers the spec asks for (NFR-09, CHK046),
 * rendered as Prometheus text. Deliberately computed on scrape rather than
 * maintained in memory: the query is cheap and cannot drift from the data.
 */
@Injectable()
export class MetricsService {
  constructor(@Inject(DB) private readonly db: Db) {}

  async render(now = new Date()): Promise<string> {
    const [wards, alerts, outbox] = await Promise.all([
      this.perWardTripStats(now),
      this.notificationLatency(),
      this.outboxDepth(),
    ]);

    const lines: string[] = [
      "# HELP namma_kasa_active_trips Trips currently running, by ward.",
      "# TYPE namma_kasa_active_trips gauge",
      ...wards.map(
        (w) => `namma_kasa_active_trips{ward="${w.wardCode}"} ${w.activeTrips}`,
      ),
      "",
      "# HELP namma_kasa_trips_today Trips started today, by ward.",
      "# TYPE namma_kasa_trips_today gauge",
      ...wards.map((w) => `namma_kasa_trips_today{ward="${w.wardCode}"} ${w.tripsToday}`),
      "",
      "# HELP namma_kasa_passes_skipped_today Passes whose window elapsed unstarted.",
      "# TYPE namma_kasa_passes_skipped_today gauge",
      ...wards.map(
        (w) => `namma_kasa_passes_skipped_today{ward="${w.wardCode}"} ${w.skippedToday}`,
      ),
      "",
      "# HELP namma_kasa_notification_latency_seconds Queue to send, recent notifications.",
      "# TYPE namma_kasa_notification_latency_seconds gauge",
      `namma_kasa_notification_latency_seconds{quantile="0.5"} ${alerts.p50}`,
      `namma_kasa_notification_latency_seconds{quantile="0.95"} ${alerts.p95}`,
      "",
      "# HELP namma_kasa_notification_outbox_depth Notifications waiting to send.",
      "# TYPE namma_kasa_notification_outbox_depth gauge",
      `namma_kasa_notification_outbox_depth ${outbox}`,
      "",
    ];

    return lines.join("\n");
  }

  private async perWardTripStats(now: Date) {
    // service_date is always written as an IST day, so "today" has to be one
    // too. `current_date` is the server's UTC day, which lags IST until 05:30
    // and would report the previous service day's counts every early morning.
    const today = serviceDateIST(now);

    const rows = await sql<{
      ward_code: string;
      active_trips: number;
      trips_today: number;
      skipped_today: number;
    }>`
      SELECT w.ward_code,
             count(*) FILTER (WHERE t.status = 'active')::int AS active_trips,
             count(t.id) FILTER (WHERE t.service_date = ${today}::date)::int AS trips_today,
             (
               SELECT count(*)::int FROM route_pass_days rpd
               JOIN routes r2 ON r2.id = rpd.route_id
               WHERE r2.ward_id = w.id
                 AND rpd.service_date = ${today}::date
                 AND rpd.status = 'skipped'
             ) AS skipped_today
      FROM wards w
      LEFT JOIN routes r ON r.ward_id = w.id
      LEFT JOIN trips t ON t.route_id = r.id
      WHERE w.status = 'active'
      GROUP BY w.id, w.ward_code
    `.execute(this.db);

    return rows.rows.map((row) => ({
      wardCode: row.ward_code,
      activeTrips: row.active_trips,
      tripsToday: row.trips_today,
      skippedToday: row.skipped_today,
    }));
  }

  private async notificationLatency(): Promise<{ p50: number; p95: number }> {
    const row = await sql<{ p50: number | null; p95: number | null }>`
      SELECT
        percentile_disc(0.5) WITHIN GROUP (
          ORDER BY extract(epoch FROM (sent_at - created_at))
        )::float8 AS p50,
        percentile_disc(0.95) WITHIN GROUP (
          ORDER BY extract(epoch FROM (sent_at - created_at))
        )::float8 AS p95
      FROM notifications
      WHERE sent_at IS NOT NULL AND created_at > now() - interval '1 hour'
    `.execute(this.db);

    return { p50: row.rows[0]?.p50 ?? 0, p95: row.rows[0]?.p95 ?? 0 };
  }

  private async outboxDepth(): Promise<number> {
    const row = await this.db
      .selectFrom("notifications")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .where("sent_at", "is", null)
      .executeTakeFirstOrThrow();
    return Number(row.count);
  }
}
