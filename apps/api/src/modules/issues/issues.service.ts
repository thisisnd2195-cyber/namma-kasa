import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import type { DriverIssue, DriverIssueRecord } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";
import { NotifyService } from "../notify/notify.service";
import { driverIssueCopy } from "../notify/templates";

/**
 * A driver's one-tap "something is wrong" (FR-DRV-07).
 *
 * The Ward Admin has to hear about a breakdown immediately, because the
 * alternative signal — pings simply stopping — is indistinguishable from a
 * flat battery, and residents are left waiting either way.
 */
@Injectable()
export class IssuesService {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly notify: NotifyService,
  ) {}

  async report(userId: string, input: DriverIssue): Promise<DriverIssueRecord> {
    const driver = await this.db
      .selectFrom("drivers as d")
      .leftJoin("driver_auto_assignments as da", (join) =>
        join.onRef("da.driver_id", "=", "d.id").on("da.effective_to", "is", null),
      )
      .leftJoin("auto_route_assignments as ar", (join) =>
        join.onRef("ar.auto_id", "=", "da.auto_id").on("ar.effective_to", "is", null),
      )
      .leftJoin("trips as t", (join) =>
        join.onRef("t.auto_id", "=", "da.auto_id").on("t.status", "=", "active"),
      )
      .select(["d.id as driverId", "d.ward_id as wardId", "ar.route_id as routeId", "t.id as tripId"])
      .where("d.user_id", "=", userId)
      .executeTakeFirst();

    if (!driver) throw new HttpException("No driver record", HttpStatus.NOT_FOUND);

    const row = await this.db
      .insertInto("driver_issues")
      .values({
        driver_id: driver.driverId,
        ward_id: driver.wardId,
        route_id: driver.routeId,
        trip_id: driver.tripId,
        kind: input.kind,
        note: input.note ?? null,
        geo: input.geo
          ? sql`ST_SetSRID(ST_MakePoint(${input.geo.lng}, ${input.geo.lat}), 4326)::geography`
          : null,
      })
      .returning(["id", "created_at"])
      .executeTakeFirstOrThrow();

    await this.alertWardAdmin(driver.wardId, input, row.id);

    return {
      id: row.id,
      kind: input.kind,
      note: input.note ?? null,
      routeId: driver.routeId,
      acknowledgedAt: null,
      createdAt: row.created_at,
    };
  }

  /**
   * Best effort: the issue is already recorded and visible in the portal queue,
   * so a push that cannot be queued must not fail the driver's report.
   */
  private async alertWardAdmin(
    wardId: string,
    input: DriverIssue,
    issueId: string,
  ): Promise<void> {
    const admin = await this.db
      .selectFrom("wards as w")
      .innerJoin("users as u", "u.id", "w.ward_admin_user_id")
      .select(["u.id as userId", "u.locale"])
      .where("w.id", "=", wardId)
      .where("u.status", "=", "active")
      .executeTakeFirst();
    if (!admin) return;

    await this.notify.queue({
      userId: admin.userId,
      kind: "driver_issue",
      copy: driverIssueCopy(admin.locale, input.kind, input.note),
      data: { kind: "driver_issue", issueId },
    });
  }

  /** Open issues for a ward, newest first — the admin's action list. */
  async listForWard(wardId: string): Promise<DriverIssueRecord[]> {
    const rows = await this.db
      .selectFrom("driver_issues as i")
      .innerJoin("drivers as d", "d.id", "i.driver_id")
      .select([
        "i.id",
        "i.kind",
        "i.note",
        "i.route_id as routeId",
        "i.acknowledged_at as acknowledgedAt",
        "i.created_at as createdAt",
        "d.full_name as driverName",
      ])
      .where("i.ward_id", "=", wardId)
      .orderBy("i.acknowledged_at", sql`asc nulls first`)
      .orderBy("i.created_at", "desc")
      .limit(100)
      .execute();

    return rows.map((row) => ({
      id: row.id,
      kind: row.kind,
      note: row.note,
      routeId: row.routeId,
      driverName: row.driverName,
      acknowledgedAt: row.acknowledgedAt,
      createdAt: row.createdAt,
    }));
  }

  async acknowledge(issueId: string, wardId: string | null): Promise<DriverIssueRecord> {
    let query = this.db
      .updateTable("driver_issues")
      .set({ acknowledged_at: new Date() })
      .where("id", "=", issueId);

    // A Ward Admin may only close their own ward's issues; a Super Admin any.
    if (wardId) query = query.where("ward_id", "=", wardId);

    const row = await query
      .returning(["id", "kind", "note", "route_id", "acknowledged_at", "created_at"])
      .executeTakeFirst();
    if (!row) throw new HttpException("Issue not found", HttpStatus.NOT_FOUND);

    return {
      id: row.id,
      kind: row.kind,
      note: row.note,
      routeId: row.route_id,
      acknowledgedAt: row.acknowledged_at,
      createdAt: row.created_at,
    };
  }
}
