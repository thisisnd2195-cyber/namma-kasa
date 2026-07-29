import { afterAll, describe, expect, it } from "vitest";
import { COMPLAINT_DAILY_LIMIT, type AccessClaims } from "@namma-kasa/shared";
import { createTestDb } from "./helpers/db";
import { ComplaintsService } from "../src/modules/complaints/complaints.service";
import { NotifyService } from "../src/modules/notify/notify.service";
import type { PushMessage, PushSender } from "../src/modules/notify/push-sender";
import { serviceDateIST } from "../src/modules/tracking/trips.service";

const db = createTestDb();

class SilentPushSender implements PushSender {
  async send(message: PushMessage) {
    return { delivered: message.tokens.length, failedTokens: [] };
  }
}

const notify = new NotifyService(db, new SilentPushSender());
const complaints = new ComplaintsService(db, notify);

afterAll(async () => {
  await db.destroy();
});

async function seededResident() {
  const row = await db
    .selectFrom("households as h")
    .innerJoin("users as u", "u.id", "h.user_id")
    .select(["h.id as householdId", "u.id as userId", "h.ward_id as wardId", "h.route_id as routeId"])
    .where("h.route_id", "is not", null)
    .executeTakeFirstOrThrow();
  await db.deleteFrom("complaints").where("household_id", "=", row.householdId).execute();
  return row;
}

/** A real admin row: assigned_to carries a foreign key to users. */
async function wardAdmin(wardId: string): Promise<AccessClaims> {
  const admin = await db
    .selectFrom("users")
    .select("id")
    .where("role", "in", ["ward_admin", "super_admin"])
    .executeTakeFirstOrThrow();
  return { sub: admin.id, role: "ward_admin", wardId, routeId: null, deviceId: null };
}

describe("complaints (FR-CMP-01, FR-CMP-02)", () => {
  it("files a complaint and opens its history", async () => {
    const resident = await seededResident();
    const complaint = await complaints.create(resident.userId, {
      category: "missed_pickup",
      description: "Auto did not come",
      mediaUrls: [],
    });

    expect(complaint.status).toBe("open");
    expect(complaint.history).toHaveLength(1);
    expect(complaint.history[0].toStatus).toBe("open");
  });

  it("rejects more than three photos", async () => {
    const resident = await seededResident();
    await expect(
      complaints.create(resident.userId, {
        category: "other",
        mediaUrls: Array.from({ length: 4 }, (_, i) => `https://example.com/${i}.jpg`),
      } as never),
    ).rejects.toBeDefined();
  });

  it("caps complaints per household per day", async () => {
    const resident = await seededResident();
    for (let i = 0; i < COMPLAINT_DAILY_LIMIT; i += 1) {
      await complaints.create(resident.userId, { category: "late", mediaUrls: [] });
    }
    await expect(
      complaints.create(resident.userId, { category: "late", mediaUrls: [] }),
    ).rejects.toThrow(/up to 5 complaints/i);
  });

  it("journals each transition and notifies the resident", async () => {
    const resident = await seededResident();
    const complaint = await complaints.create(resident.userId, {
      category: "missed_pickup",
      mediaUrls: [],
    });
    const admin = await wardAdmin(resident.wardId!);

    await complaints.updateStatus(complaint.id, { status: "in_review" }, admin);
    const resolved = await complaints.updateStatus(
      complaint.id,
      { status: "resolved", resolutionNote: "Checked the GPS trail" },
      admin,
    );

    expect(resolved.status).toBe("resolved");
    expect(resolved.history.map((h) => h.toStatus)).toEqual(["open", "in_review", "resolved"]);

    const queued = await db
      .selectFrom("notifications")
      .select("kind")
      .where("user_id", "=", resident.userId)
      .where("kind", "=", "complaint_status")
      .execute();
    expect(queued.length).toBeGreaterThanOrEqual(2);
  });

  it("refuses to reopen a closed complaint", async () => {
    const resident = await seededResident();
    const complaint = await complaints.create(resident.userId, {
      category: "other",
      mediaUrls: [],
    });
    const admin = await wardAdmin(resident.wardId!);

    await complaints.updateStatus(complaint.id, { status: "rejected" }, admin);
    await expect(
      complaints.updateStatus(complaint.id, { status: "in_review" }, admin),
    ).rejects.toThrow(/cannot move a rejected/i);
  });

  it("blocks a ward admin from touching another ward's complaint", async () => {
    const resident = await seededResident();
    const complaint = await complaints.create(resident.userId, {
      category: "other",
      mediaUrls: [],
    });

    await expect(
      complaints.updateStatus(
        complaint.id,
        { status: "in_review" },
        await wardAdmin("aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"),
      ),
    ).rejects.toThrow(/outside your ward/i);
  });

  /**
   * The point of the whole system: a "you never came" complaint is answered by
   * the GPS record, not by argument.
   */
  it("carries collection evidence into the admin queue", async () => {
    const resident = await seededResident();
    await complaints.create(resident.userId, { category: "missed_pickup", mediaUrls: [] });

    const queue = await complaints.listForWard(resident.wardId!);
    const mine = queue.find((c) => c.household.id === resident.householdId);

    expect(mine).toBeDefined();
    expect(mine!.evidence).toHaveProperty("servedOnComplaintDay");
    expect(typeof mine!.evidence.servedOnComplaintDay).toBe("boolean");
  });
});

describe("ratings (FR-CMP-05)", () => {
  async function withCollectionToday() {
    const resident = await seededResident();
    await db.deleteFrom("ratings").where("household_id", "=", resident.householdId).execute();
    await db
      .deleteFrom("household_collections")
      .where("household_id", "=", resident.householdId)
      .execute();

    const trip = await db
      .selectFrom("trips")
      .select(["id", "route_id"])
      .where("route_id", "=", resident.routeId!)
      .orderBy("started_at", "desc")
      .executeTakeFirst();
    if (!trip) return null;

    await db
      .insertInto("household_collections")
      .values({
        household_id: resident.householdId,
        trip_id: trip.id,
        route_id: trip.route_id,
        pass_number: 1,
      })
      .execute();
    return resident;
  }

  it("refuses a rating before the auto has been past", async () => {
    const resident = await seededResident();
    await db
      .deleteFrom("household_collections")
      .where("household_id", "=", resident.householdId)
      .execute();

    await expect(complaints.rate(resident.userId, { stars: 5 })).rejects.toThrow(
      /once the auto has been past/i,
    );
  });

  it("accepts one rating for the day and refuses a second", async () => {
    const resident = await withCollectionToday();
    if (!resident) return;

    const rating = await complaints.rate(resident.userId, { stars: 4, comment: "On time" });
    expect(rating.stars).toBe(4);
    expect(rating.collectionDate).toBe(serviceDateIST());

    await expect(complaints.rate(resident.userId, { stars: 1 })).rejects.toThrow(
      /already rated/i,
    );
  });
});
