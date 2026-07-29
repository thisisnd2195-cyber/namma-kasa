import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { sql } from "kysely";
import {
  COMPLAINT_DAILY_LIMIT,
  type AccessClaims,
  type Complaint,
  type ComplaintStatus,
} from "@namma-kasa/shared";
import type {
  createComplaintSchema,
  createRatingSchema,
  updateComplaintSchema,
} from "@namma-kasa/shared";
import type { z } from "zod";
import { DB, type Db } from "../../db/db.module";
import { NotifyService } from "../notify/notify.service";
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
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly notify: NotifyService,
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
      })
      .returning("id")
      .executeTakeFirstOrThrow();

    return this.get(row.id);
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
