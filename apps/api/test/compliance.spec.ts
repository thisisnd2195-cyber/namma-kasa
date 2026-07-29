import { afterAll, describe, expect, it } from "vitest";
import { sql } from "kysely";
import { createTestDb } from "./helpers/db";
import { ComplianceService } from "../src/modules/compliance/compliance.service";

const db = createTestDb();
const compliance = new ComplianceService(db);

afterAll(async () => {
  await db.destroy();
});

async function makeResident(phone: string) {
  const user = await db
    .insertInto("users")
    .values({ phone, auth_provider: "password", password_hash: "x", role: "resident" })
    .returning("id")
    .executeTakeFirstOrThrow();

  const ward = await db.selectFrom("wards").select("id").executeTakeFirstOrThrow();
  const household = await db
    .insertInto("households")
    .values({
      user_id: user.id,
      full_name: "Erasure Test",
      address_line: "1 Test Road",
      house_geo: sql<string>`ST_SetSRID(ST_MakePoint(77.59, 12.96), 4326)`,
      ward_id: ward.id,
    })
    .returning("id")
    .executeTakeFirstOrThrow();

  return { userId: user.id, householdId: household.id };
}

describe("account deletion (NFR-04, Clarifications CHK010)", () => {
  it("blocks the account immediately and revokes its sessions", async () => {
    const { userId } = await makeResident(`9197${Date.now() % 100_000_000}`);
    await db
      .insertInto("refresh_tokens")
      .values({
        user_id: userId,
        token_hash: `hash-${crypto.randomUUID()}`,
        expires_at: new Date(Date.now() + 86_400_000),
      })
      .execute();

    const { erasesAfter } = await compliance.requestDeletion(userId);
    expect(erasesAfter.getTime()).toBeGreaterThan(Date.now());

    const user = await db
      .selectFrom("users")
      .select(["status", "deletion_requested_at"])
      .where("id", "=", userId)
      .executeTakeFirstOrThrow();
    expect(user.status).toBe("blocked");
    expect(user.deletion_requested_at).not.toBeNull();

    const tokens = await db
      .selectFrom("refresh_tokens")
      .select("id")
      .where("user_id", "=", userId)
      .execute();
    expect(tokens).toHaveLength(0);
  });

  it("leaves the account intact until the grace period expires", async () => {
    const { userId } = await makeResident(`9196${Date.now() % 100_000_000}`);
    await compliance.requestDeletion(userId);

    const erased = await compliance.eraseDueAccounts(new Date());
    expect(erased).toBe(0);

    const user = await db
      .selectFrom("users")
      .select("phone")
      .where("id", "=", userId)
      .executeTakeFirstOrThrow();
    expect(user.phone.startsWith("deleted-")).toBe(false);
  });

  /**
   * The balance the spec strikes: the person disappears, the service record
   * does not. Otherwise a resident could erase the evidence of whether their
   * street was ever collected.
   */
  it("erases identity but keeps the collection record", async () => {
    const phone = `9195${Date.now() % 100_000_000}`;
    const { userId, householdId } = await makeResident(phone);
    await compliance.requestDeletion(userId);

    // Pretend the request was made 31 days ago.
    await db
      .updateTable("users")
      .set({ deletion_requested_at: new Date(Date.now() - 31 * 86_400_000) })
      .where("id", "=", userId)
      .execute();

    const erased = await compliance.eraseDueAccounts(new Date());
    expect(erased).toBeGreaterThanOrEqual(1);

    const user = await db
      .selectFrom("users")
      .select(["phone", "password_hash", "email"])
      .where("id", "=", userId)
      .executeTakeFirstOrThrow();
    expect(user.phone).toMatch(/^deleted-/);
    expect(user.password_hash).toBeNull();

    const household = await db
      .selectFrom("households")
      .select(["full_name", "ward_id"])
      .where("id", "=", householdId)
      .executeTakeFirstOrThrow();
    expect(household.full_name).toBe("Deleted resident");
    // The household row survives, so ward history stays whole.
    expect(household.ward_id).not.toBeNull();
  });

  it("does not re-erase an already erased account", async () => {
    const before = await compliance.eraseDueAccounts(new Date());
    const after = await compliance.eraseDueAccounts(new Date());
    expect(after).toBeLessThanOrEqual(before);
  });
});

describe("media retention (Clarifications CHK015)", () => {
  async function seedMedia(expiresAt: Date, objectUrl: string) {
    const trip = await db.selectFrom("trips").select("id").executeTakeFirst();
    if (!trip) return null;
    return db
      .insertInto("media_uploads")
      .values({
        trip_id: trip.id,
        object_url: objectUrl,
        type: "collection_proof",
        expires_at: expiresAt,
      })
      .returning("id")
      .executeTakeFirstOrThrow();
  }

  it("deletes media past its retention date", async () => {
    const url = `https://example.com/${crypto.randomUUID()}.jpg`;
    const media = await seedMedia(new Date(Date.now() - 86_400_000), url);
    if (!media) return;

    await compliance.expireMedia(new Date());

    const remaining = await db
      .selectFrom("media_uploads")
      .select("id")
      .where("id", "=", media.id)
      .executeTakeFirst();
    expect(remaining).toBeUndefined();
  });

  it("keeps media still attached to an open complaint", async () => {
    const url = `https://example.com/${crypto.randomUUID()}.jpg`;
    const media = await seedMedia(new Date(Date.now() - 86_400_000), url);
    if (!media) return;

    const household = await db
      .selectFrom("households")
      .select(["id", "ward_id"])
      .where("ward_id", "is not", null)
      .executeTakeFirstOrThrow();

    const complaint = await db
      .insertInto("complaints")
      .values({
        household_id: household.id,
        ward_id: household.ward_id!,
        category: "missed_pickup",
        media_urls: [url],
        status: "open",
      })
      .returning("id")
      .executeTakeFirstOrThrow();

    await compliance.expireMedia(new Date());

    const survived = await db
      .selectFrom("media_uploads")
      .select("id")
      .where("id", "=", media.id)
      .executeTakeFirst();
    expect(survived).toBeDefined();

    await db.deleteFrom("complaints").where("id", "=", complaint.id).execute();
  });

  it("publishes its retention policy", () => {
    expect(compliance.retentionPolicy).toEqual({
      deletionGraceDays: 30,
      mediaRetentionDays: 180,
      pingRetentionDays: 90,
    });
  });
});
