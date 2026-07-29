import { HttpException, HttpStatus, Inject, Injectable, Logger } from "@nestjs/common";
import { sql } from "kysely";
import {
  COMPLAINT_DAILY_LIMIT,
  complaintSlaHours,
  operatorConfigSchema,
  type AccessClaims,
  type Complaint,
  type ComplaintCategory,
  type ComplaintStatus,
  type OperatorConfig,
} from "@namma-kasa/shared";
import type {
  createComplaintSchema,
  createRatingSchema,
  updateComplaintSchema,
} from "@namma-kasa/shared";
import type { z } from "zod";
import { DB, type Db } from "../../db/db.module";
import { NotifyService } from "../notify/notify.service";
import { SAHAAYA_CLIENT, type SahaayaClient } from "./sahaaya";
import { serviceDateIST } from "../tracking/trips.service";

type CreateComplaint = z.infer<typeof createComplaintSchema>;
type UpdateComplaint = z.infer<typeof updateComplaintSchema>;
type CreateRating = z.infer<typeof createRatingSchema>;

const ALLOWED_TRANSITIONS: Record<ComplaintStatus, ComplaintStatus[]> = {
  open: ["in_review", "resolved", "rejected"],
  in_review: ["resolved", "rejected"],
  resolved: [],
  rejected: [],
};

@Injectable()
export class ComplaintsService {
  private readonly logger = new Logger(ComplaintsService.name);

  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly notify: NotifyService,
    @Inject(SAHAAYA_CLIENT) private readonly sahaaya: SahaayaClient,
  ) {}

  private async householdFor(
    userId: string,
  ): Promise<{ id: string; ward_id: string; route_id: string | null }> {
    const household = await this.db
      .selectFrom("households")
      .select(["id", "ward_id", "route_id"])
      .where("user_id", "=", userId)
      .executeTakeFirst();
    if (!household) throw new HttpException("No household registered", HttpStatus.NOT_FOUND);
    if (!household.ward_id) {
      throw new HttpException(
        "Your address is still being confirmed. Try again once it is mapped.",
        HttpStatus.CONFLICT,
      );
    }
    return { id: household.id, ward_id: household.ward_id, route_id: household.route_id };
  }

  async create(userId: string, input: CreateComplaint): Promise<Complaint> {
    const household = await this.householdFor(userId);

    const todayCount = await this.db
      .selectFrom("complaints")
      .select(({ fn }) => fn.countAll<string>().as("count"))
      .where("household_id", "=", household.id)
      .where(sql<boolean>`created_at::date = ${serviceDateIST()}::date`)
      .executeTakeFirstOrThrow();

    if (Number(todayCount.count) >= COMPLAINT_DAILY_LIMIT) {
      throw new HttpException(
        `You can raise up to ${COMPLAINT_DAILY_LIMIT} complaints a day.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const row = await this.db
      .insertInto("complaints")
      .values({
        household_id: household.id,
        ward_id: household.ward_id,
        route_id: household.route_id,
        category: input.category,
        description: input.description ?? null,
        media_urls: input.mediaUrls,
        sla_due_at: await this.slaDueAt(household.ward_id, input.category),
      })
      .returning("id")
      .executeTakeFirstOrThrow();

    await this.syncToSahaaya(row.id, household.ward_id, input);

    return this.get(row.id);
  }

  /**
   * Mirror the complaint into Sahaaya 2.0 when the operator has turned it on
   * and the ward is actually BBMP's (FR-CMP-04). A private contractor has no
   * Sahaaya presence, so the flag alone is not enough.
   *
   * Failure here is logged and swallowed: the complaint is already recorded
   * with us, and losing it because a third party is down would be worse.
   */
  private async syncToSahaaya(
    complaintId: string,
    wardId: string,
    input: CreateComplaint,
  ): Promise<void> {
    const ward = await this.db
      .selectFrom("wards as w")
      .innerJoin("operators as o", "o.id", "w.operator_id")
      .select(["w.ward_code as wardCode", "o.type as operatorType", "o.config"])
      .where("w.id", "=", wardId)
      .executeTakeFirst();
    if (!ward || ward.operatorType !== "bbmp") return;

    const config = operatorConfigSchema.safeParse(ward.config ?? {});
    if (!config.success || !config.data.sahaayaSyncEnabled) return;

    const household = await this.db
      .selectFrom("complaints as c")
      .innerJoin("households as h", "h.id", "c.household_id")
      .select("h.address_line as addressLine")
      .where("c.id", "=", complaintId)
      .executeTakeFirst();

    try {
      await this.sahaaya.push({
        complaintId,
        category: input.category,
        description: input.description ?? null,
        wardCode: ward.wardCode,
        addressLine: household?.addressLine ?? "",
        raisedAt: new Date(),
      });
    } catch (error) {
      this.logger.warn(`Sahaaya sync failed for complaint ${complaintId}: ${String(error)}`);
    }
  }

  /**
   * When this complaint is due, from the owning operator's configured SLA
   * (FR-CMP-03). Stamped at creation rather than derived on read so that a
   * later change to the operator's policy cannot silently re-date complaints
   * that were already raised under the old one.
   */
  private async slaDueAt(wardId: string, category: ComplaintCategory): Promise<Date> {
    const hours = complaintSlaHours(await this.configFor(wardId), category);
    return new Date(Date.now() + hours * 60 * 60 * 1000);
  }

  /**
   * The operator policy governing a ward. A malformed or absent config must
   * never block a resident's complaint, so this falls back to the defaults the
   * schema already declares rather than throwing.
   */
  private async configFor(wardId: string): Promise<OperatorConfig> {
    const operator = await this.db
      .selectFrom("wards")
      .innerJoin("operators", "operators.id", "wards.operator_id")
      .select("operators.config")
      .where("wards.id", "=", wardId)
      .executeTakeFirst();

    const parsed = operatorConfigSchema.safeParse(operator?.config ?? {});
    return parsed.success ? parsed.data : operatorConfigSchema.parse({});
  }

  async get(complaintId: string): Promise<Complaint> {
    const row = await this.db
      .selectFrom("complaints")
      .selectAll()
      .where("id", "=", complaintId)
      .executeTakeFirst();
    if (!row) throw new HttpException("Complaint not found", HttpStatus.NOT_FOUND);

    const history = await this.db
      .selectFrom("complaint_events")
      .select(["from_status", "to_status", "note", "at"])
      .where("complaint_id", "=", complaintId)
      .orderBy("at")
      .execute();

    return {
      id: row.id,
      category: row.category,
      description: row.description,
      mediaUrls: row.media_urls,
      status: row.status,
      routeId: row.route_id,
      wardId: row.ward_id,
      slaDueAt: row.sla_due_at,
      resolutionNote: row.resolution_note,
      createdAt: row.created_at,
      history: history.map((event) => ({
        fromStatus: event.from_status,
        toStatus: event.to_status,
        note: event.note,
        at: event.at,
      })),
    };
  }

  async listForResident(userId: string): Promise<Complaint[]> {
    const household = await this.householdFor(userId);
    const rows = await this.db
      .selectFrom("complaints")
      .select("id")
      .where("household_id", "=", household.id)
      .orderBy("created_at", "desc")
      .limit(50)
      .execute();
    return Promise.all(rows.map((row) => this.get(row.id)));
  }

  /**
   * The admin queue. Each complaint arrives with the collection record for the
   * day it was raised, so "we did come" is answered by the GPS trail rather
   * than by argument.
   */
  async listForWard(wardId: string, status?: ComplaintStatus) {
    const { escalateAfterHours } = await this.configFor(wardId);

    let query = this.db
      .selectFrom("complaints as c")
      .innerJoin("households as h", "h.id", "c.household_id")
      .select([
        "c.id",
        "c.category",
        "c.description",
        "c.media_urls",
        "c.status",
        "c.route_id",
        "c.ward_id",
        "c.sla_due_at",
        "c.resolution_note",
        "c.created_at",
        "h.id as householdId",
        "h.full_name as householdName",
        "h.address_line as householdAddress",
        sql<boolean>`EXISTS (
          SELECT 1 FROM household_collections hc
          WHERE hc.household_id = h.id
            AND hc.detected_at::date = c.created_at::date
        )`.as("servedOnComplaintDay"),
        sql<number | null>`(
          SELECT (extract(epoch from max(hc.detected_at)) * 1000)::float8
          FROM household_collections hc WHERE hc.household_id = h.id
        )`.as("lastCollectedMs"),
        // Only an open complaint can breach: once it is resolved or rejected
        // the clock has stopped, whatever the due time says (FR-CMP-03).
        sql<boolean>`c.sla_due_at IS NOT NULL
          AND c.status IN ('open', 'in_review')
          AND c.sla_due_at < now()`.as("slaBreached"),
        sql<boolean>`c.sla_due_at IS NOT NULL
          AND c.status IN ('open', 'in_review')
          AND c.sla_due_at + make_interval(hours => ${sql.lit(escalateAfterHours)}) < now()`.as(
          "slaEscalated",
        ),
      ])
      .where("c.ward_id", "=", wardId)
      .orderBy("c.created_at", "desc")
      .limit(100);

    if (status) query = query.where("c.status", "=", status);

    const rows = await query.execute();
    return rows.map((row) => ({
      id: row.id,
      category: row.category,
      description: row.description,
      mediaUrls: row.media_urls,
      status: row.status,
      routeId: row.route_id,
      wardId: row.ward_id,
      slaDueAt: row.sla_due_at,
      slaBreached: row.slaBreached,
      slaEscalated: row.slaEscalated,
      resolutionNote: row.resolution_note,
      createdAt: row.created_at,
      history: [],
      household: {
        id: row.householdId,
        fullName: row.householdName,
        addressLine: row.householdAddress,
      },
      evidence: {
        servedOnComplaintDay: row.servedOnComplaintDay,
        lastCollectedAt: row.lastCollectedMs ? new Date(row.lastCollectedMs) : null,
      },
    }));
  }

  async updateStatus(
    complaintId: string,
    input: UpdateComplaint,
    actor: AccessClaims,
  ): Promise<Complaint> {
    const complaint = await this.db
      .selectFrom("complaints as c")
      .innerJoin("households as h", "h.id", "c.household_id")
      .select(["c.id", "c.status", "c.ward_id", "h.user_id as residentUserId"])
      .where("c.id", "=", complaintId)
      .executeTakeFirst();
    if (!complaint) throw new HttpException("Complaint not found", HttpStatus.NOT_FOUND);

    if (actor.role === "ward_admin" && complaint.ward_id !== actor.wardId) {
      throw new HttpException("Outside your ward", HttpStatus.FORBIDDEN);
    }

    if (!ALLOWED_TRANSITIONS[complaint.status].includes(input.status)) {
      throw new HttpException(
        `Cannot move a ${complaint.status} complaint to ${input.status}`,
        HttpStatus.CONFLICT,
      );
    }

    // The status trigger journals the transition; this only sets the fields.
    await this.db
      .updateTable("complaints")
      .set({
        status: input.status,
        assigned_to: actor.sub,
        resolution_note: input.resolutionNote ?? null,
        updated_at: new Date(),
      })
      .where("id", "=", complaintId)
      .execute();

    const resident = await this.db
      .selectFrom("users")
      .select("locale")
      .where("id", "=", complaint.residentUserId)
      .executeTakeFirst();

    await this.notify.queueComplaintStatus({
      userId: complaint.residentUserId,
      locale: resident?.locale ?? "en",
      status: input.status,
      complaintId,
    });

    return this.get(complaintId);
  }

  /**
   * One rating per household per IST collection day, and only once the auto has
   * actually been past — otherwise it is a rating of nothing (FR-CMP-05).
   */
  async rate(userId: string, input: CreateRating) {
    const household = await this.householdFor(userId);
    const today = serviceDateIST();

    const collection = await this.db
      .selectFrom("household_collections")
      .select(["trip_id", "route_id"])
      .where("household_id", "=", household.id)
      .where(sql<boolean>`detected_at::date = ${today}::date`)
      .orderBy("detected_at", "desc")
      .executeTakeFirst();

    if (!collection) {
      throw new HttpException(
        "You can rate once the auto has been past today.",
        HttpStatus.CONFLICT,
      );
    }

    try {
      const row = await this.db
        .insertInto("ratings")
        .values({
          household_id: household.id,
          route_id: collection.route_id,
          trip_id: collection.trip_id,
          stars: input.stars,
          comment: input.comment ?? null,
          collection_date: today,
        })
        .returningAll()
        .executeTakeFirstOrThrow();

      return {
        id: row.id,
        stars: row.stars,
        comment: row.comment,
        collectionDate: today,
        createdAt: row.created_at,
      };
    } catch (error) {
      if (error instanceof Error && /duplicate key/i.test(error.message)) {
        throw new HttpException("You have already rated today's collection.", HttpStatus.CONFLICT);
      }
      throw error;
    }
  }
}
