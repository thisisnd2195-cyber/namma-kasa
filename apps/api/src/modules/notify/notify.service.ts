import { Inject, Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import type { Locale, NotificationKind, WasteType } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";
import { PUSH_SENDER, type PushSender } from "./push-sender";
import { complaintStatusCopy, proximityCopy, type NotificationCopy } from "./templates";

/** How often the outbox drains. The budget is 10 s p95 end to end (FR-NOTIF-05). */
const DRAIN_INTERVAL_MS = 1_000;
const BATCH_SIZE = 200;

export interface QueuedNotification {
  userId: string;
  kind: NotificationKind;
  copy: NotificationCopy;
  data: Record<string, string>;
  dedupKey?: string;
}

/**
 * Notifications are queued to the database and drained by a worker rather than
 * pushed inline. A push that fails must not fail the GPS ingest that triggered
 * it, and the outbox row is the record that the resident was told.
 */
@Injectable()
export class NotifyService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NotifyService.name);
  private timer?: NodeJS.Timeout;

  constructor(
    @Inject(DB) private readonly db: Db,
    @Inject(PUSH_SENDER) private readonly push: PushSender,
  ) {}

  onModuleInit(): void {
    this.timer = setInterval(() => {
      void this.drain().catch((error: unknown) =>
        this.logger.error(`Outbox drain failed: ${String(error)}`),
      );
    }, DRAIN_INTERVAL_MS);
    this.timer.unref();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  async queue(notification: QueuedNotification): Promise<boolean> {
    const inserted = await this.db
      .insertInto("notifications")
      .values({
        user_id: notification.userId,
        kind: notification.kind,
        payload: {
          title: notification.copy.title,
          body: notification.copy.body,
          ...notification.data,
        },
        dedup_key: notification.dedupKey ?? null,
      })
      // The unique dedup key is the second line of defence behind the Redis
      // claim, and the durable one.
      .onConflict((oc) => oc.column("dedup_key").doNothing())
      .returning("id")
      .executeTakeFirst();

    return inserted !== undefined;
  }

  async queueProximity(params: {
    userId: string;
    locale: Locale;
    distanceM: number;
    wasteTypes: WasteType[];
    routeId: string;
    tripId: string;
    dedupKey: string;
  }): Promise<boolean> {
    return this.queue({
      userId: params.userId,
      kind: "proximity",
      copy: proximityCopy(params.locale, params.distanceM, params.wasteTypes),
      data: { kind: "proximity", routeId: params.routeId, tripId: params.tripId },
      dedupKey: params.dedupKey,
    });
  }

  async queueComplaintStatus(params: {
    userId: string;
    locale: Locale;
    status: string;
    complaintId: string;
  }): Promise<boolean> {
    return this.queue({
      userId: params.userId,
      kind: "complaint_status",
      copy: complaintStatusCopy(params.locale, params.status),
      data: { kind: "complaint_status", complaintId: params.complaintId },
    });
  }

  /** Sends everything unsent. Returns how many were delivered. */
  async drain(): Promise<number> {
    const pending = await this.db
      .selectFrom("notifications")
      .selectAll()
      .where("sent_at", "is", null)
      .orderBy("created_at")
      .limit(BATCH_SIZE)
      .execute();

    if (pending.length === 0) return 0;

    let delivered = 0;
    for (const row of pending) {
      const tokens = await this.db
        .selectFrom("device_tokens")
        .select("fcm_token")
        .where("user_id", "=", row.user_id)
        .execute();

      const payload = row.payload as Record<string, string>;
      const { title, body, ...data } = payload;

      try {
        const result = await this.push.send({
          tokens: tokens.map((t) => t.fcm_token),
          title,
          body,
          data,
        });

        // A rejected token is a dead install; keeping it would retry forever.
        if (result.failedTokens.length > 0) {
          await this.db
            .deleteFrom("device_tokens")
            .where("fcm_token", "in", result.failedTokens)
            .execute();
        }
        delivered += result.delivered;
      } catch (error) {
        this.logger.warn(`Push failed for notification ${row.id}: ${String(error)}`);
        continue; // leave unsent; the next drain retries
      }

      await this.db
        .updateTable("notifications")
        .set({ sent_at: new Date() })
        .where("id", "=", row.id)
        .execute();
    }

    return delivered;
  }

  async registerDevice(userId: string, token: string): Promise<void> {
    await this.db
      .insertInto("device_tokens")
      .values({ user_id: userId, fcm_token: token, platform: "android" })
      .onConflict((oc) =>
        oc.columns(["user_id", "fcm_token"]).doUpdateSet({ updated_at: new Date() }),
      )
      .execute();
  }
}
