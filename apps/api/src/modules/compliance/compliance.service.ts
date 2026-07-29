import { Inject, Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { sql } from "kysely";
import { DB, type Db } from "../../db/db.module";

/** DPDP: erase within 30 days of the request (NFR-04, Clarifications CHK010). */
const DELETION_GRACE_DAYS = 30;
/** Media retention, extended while attached to an open complaint (CHK015). */
const MEDIA_RETENTION_DAYS = 180;
/** Raw GPS retention; aggregates outlive it (NFR-06). */
const PING_RETENTION_DAYS = 90;

const SWEEP_INTERVAL_MS = 6 * 3_600_000;

@Injectable()
export class ComplianceService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ComplianceService.name);
  private timer?: NodeJS.Timeout;

  constructor(@Inject(DB) private readonly db: Db) {}

  onModuleInit(): void {
    this.timer = setInterval(() => {
      void this.sweep().catch((error: unknown) =>
        this.logger.error(`Retention sweep failed: ${String(error)}`),
      );
    }, SWEEP_INTERVAL_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  /** Marks the account; the sweep erases it once the grace period passes. */
  async requestDeletion(userId: string): Promise<{ erasesAfter: Date }> {
    const erasesAfter = new Date(Date.now() + DELETION_GRACE_DAYS * 86_400_000);
    await this.db
      .updateTable("users")
      .set({ deletion_requested_at: new Date(), status: "blocked", updated_at: new Date() })
      .where("id", "=", userId)
      .execute();
    await this.db.deleteFrom("refresh_tokens").where("user_id", "=", userId).execute();
    await this.db.deleteFrom("device_tokens").where("user_id", "=", userId).execute();
    return { erasesAfter };
  }

  /**
   * Erases identifying fields but keeps the operational record. A deleted
   * resident must not erase the evidence that a street was or was not served —
   * that history belongs to the ward, not to the individual.
   */
  async eraseDueAccounts(now = new Date()): Promise<number> {
    const cutoff = new Date(now.getTime() - DELETION_GRACE_DAYS * 86_400_000);

    const due = await this.db
      .selectFrom("users")
      .select("id")
      .where("deletion_requested_at", "is not", null)
      .where("deletion_requested_at", "<", cutoff)
      .where("phone", "not like", "deleted-%")
      .execute();

    for (const user of due) {
      await this.db.transaction().execute(async (trx) => {
        await trx
          .updateTable("households")
          .set({ full_name: "Deleted resident", address_line: "—", landmark: null })
          .where("user_id", "=", user.id)
          .execute();

        await trx
          .updateTable("users")
          .set({
            phone: sql<string>`'deleted-' || ${user.id}`,
            email: null,
            password_hash: null,
            updated_at: new Date(),
          })
          .where("id", "=", user.id)
          .execute();
      });
    }

    if (due.length > 0) this.logger.log(`Erased ${due.length} account(s) past the grace period`);
    return due.length;
  }

  async expireMedia(now = new Date()): Promise<number> {
    const result = await sql<{ id: string }>`
      DELETE FROM media_uploads m
      WHERE m.expires_at < ${now}
        AND NOT EXISTS (
          SELECT 1 FROM complaints c
          WHERE c.status IN ('open', 'in_review')
            AND m.object_url = ANY (c.media_urls)
        )
      RETURNING m.id
    `.execute(this.db);
    return result.rows.length;
  }

  /** Timescale drops whole chunks, which is far cheaper than row deletes. */
  async expirePings(now = new Date()): Promise<void> {
    const cutoff = new Date(now.getTime() - PING_RETENTION_DAYS * 86_400_000);
    await sql`SELECT drop_chunks('location_pings', ${cutoff}::timestamptz)`.execute(this.db);
  }

  async sweep(now = new Date()): Promise<{ erased: number; media: number }> {
    const erased = await this.eraseDueAccounts(now);
    const media = await this.expireMedia(now);
    try {
      await this.expirePings(now);
    } catch (error) {
      this.logger.warn(`Ping chunk drop skipped: ${String(error)}`);
    }
    return { erased, media };
  }

  get retentionPolicy() {
    return {
      deletionGraceDays: DELETION_GRACE_DAYS,
      mediaRetentionDays: MEDIA_RETENTION_DAYS,
      pingRetentionDays: PING_RETENTION_DAYS,
    };
  }
}
