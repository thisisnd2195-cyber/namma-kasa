import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { OTP_POLICY } from "@namma-kasa/shared";
import { buildAuthStack, randomPhone, verifiedPhone } from "./helpers/services";

const stack = buildAuthStack();
afterAll(async () => {
  await stack.close();
});

async function clearOtpState(phone: string): Promise<void> {
  await stack.redis.del(
    `otp:${phone}`,
    `otp:attempts:${phone}`,
    `otp:cooldown:${phone}`,
    `otp:hourly:${phone}`,
  );
}

describe("OTP policy (FR-AUTH-02)", () => {
  let phone: string;
  beforeEach(async () => {
    phone = randomPhone();
    await clearOtpState(phone);
  });

  it("issues a six digit code and reports the resend cooldown", async () => {
    const result = await stack.auth.sendOtp(phone);
    expect(result.resendAfterSec).toBe(OTP_POLICY.resendCooldownSeconds);
    expect(stack.sender.lastCodeFor(phone)).toMatch(/^\d{6}$/);
  });

  it("refuses a resend inside the cooldown window", async () => {
    await stack.auth.sendOtp(phone);
    await expect(stack.auth.sendOtp(phone)).rejects.toThrow(/Wait \d+s/);
  });

  it("caps codes per number per hour", async () => {
    for (let i = 0; i < OTP_POLICY.maxPerNumberPerHour; i += 1) {
      await stack.redis.del(`otp:cooldown:${phone}`);
      await stack.auth.sendOtp(phone);
    }
    await stack.redis.del(`otp:cooldown:${phone}`);
    await expect(stack.auth.sendOtp(phone)).rejects.toThrow(/Too many codes/);
  });

  it("burns the code after three wrong attempts", async () => {
    await stack.auth.sendOtp(phone);
    const wrong = stack.sender.lastCodeFor(phone) === "000000" ? "111111" : "000000";

    await expect(stack.auth.verifyOtp(phone, wrong)).rejects.toThrow(/Incorrect code/);
    await expect(stack.auth.verifyOtp(phone, wrong)).rejects.toThrow(/Incorrect code/);
    await expect(stack.auth.verifyOtp(phone, wrong)).rejects.toThrow(/Too many wrong attempts/);

    // Even the correct code is now useless — the code was consumed.
    await expect(
      stack.auth.verifyOtp(phone, stack.sender.lastCodeFor(phone)),
    ).rejects.toThrow(/expired/i);
  });

  it("consumes the code on success so it cannot be replayed", async () => {
    await stack.auth.sendOtp(phone);
    const code = stack.sender.lastCodeFor(phone);
    await expect(stack.auth.verifyOtp(phone, code)).resolves.toHaveProperty("verificationToken");
    await expect(stack.auth.verifyOtp(phone, code)).rejects.toThrow(/expired/i);
  });
});

describe("registration", () => {
  it("refuses a driver whose number was never pre-provisioned (FR-AUTH-05)", async () => {
    const phone = randomPhone();
    const verificationToken = await verifiedPhone(stack, phone);

    await expect(
      stack.auth.register({
        role: "driver",
        verificationToken,
        credential: { password: "drivepass1" },
        profile: { locale: "kn", consent: true },
        deviceId: "device-1",
      }),
    ).rejects.toThrow(/not registered as a driver/i);
  });

  it("maps a resident to ward and route from the house pin (FR-AUTH-08)", async () => {
    const phone = randomPhone();
    const verificationToken = await verifiedPhone(stack, phone);

    const session = await stack.auth.register({
      role: "resident",
      verificationToken,
      credential: { password: "residentpass1" },
      profile: {
        fullName: "Test Resident",
        addressLine: "1 Sample Cross",
        pin: { lat: 12.9612, lng: 77.5925 }, // inside the seeded route
        locale: "en",
        consent: true,
      },
    });

    expect(session.user.role).toBe("resident");
    expect(session.user.wardId).not.toBeNull();

    const household = await stack.db
      .selectFrom("households")
      .select(["route_id", "mapping_status"])
      .where("user_id", "=", session.user.id)
      .executeTakeFirstOrThrow();
    expect(household.route_id).not.toBeNull();
    expect(household.mapping_status).toBe("auto");
  });

  it("sends a pin outside every route to the review queue (FR-AUTH-08)", async () => {
    const phone = randomPhone();
    const verificationToken = await verifiedPhone(stack, phone);

    const session = await stack.auth.register({
      role: "resident",
      verificationToken,
      credential: { password: "residentpass1" },
      profile: {
        fullName: "Edge Resident",
        addressLine: "9 Edge Road",
        pin: { lat: 12.9805, lng: 77.6135 }, // in the ward, in no route
        locale: "en",
        consent: true,
      },
    });

    const household = await stack.db
      .selectFrom("households")
      .select(["route_id", "mapping_status"])
      .where("user_id", "=", session.user.id)
      .executeTakeFirstOrThrow();
    expect(household.route_id).toBeNull();
    expect(household.mapping_status).toBe("pending_review");
  });

  it("rejects a second account for the same number", async () => {
    const phone = randomPhone();
    const first = await verifiedPhone(stack, phone);
    await stack.auth.register({
      role: "resident",
      verificationToken: first,
      credential: { password: "residentpass1" },
      profile: {
        fullName: "First",
        addressLine: "1 Road",
        pin: { lat: 12.9612, lng: 77.5925 },
        locale: "en",
        consent: true,
      },
    });

    const second = await verifiedPhone(stack, phone);
    await expect(
      stack.auth.register({
        role: "resident",
        verificationToken: second,
        credential: { password: "residentpass1" },
        profile: {
          fullName: "Second",
          addressLine: "2 Road",
          pin: { lat: 12.9612, lng: 77.5925 },
          locale: "en",
          consent: true,
        },
      }),
    ).rejects.toThrow(/already has an account/i);
  });
});

describe("sessions", () => {
  async function newResident() {
    const phone = randomPhone();
    const verificationToken = await verifiedPhone(stack, phone);
    const session = await stack.auth.register({
      role: "resident",
      verificationToken,
      credential: { password: "residentpass1" },
      profile: {
        fullName: "Session Tester",
        addressLine: "3 Road",
        pin: { lat: 12.9612, lng: 77.5925 },
        locale: "en",
        consent: true,
      },
    });
    return { phone, session };
  }

  it("rejects a wrong password", async () => {
    const { phone } = await newResident();
    await expect(stack.auth.login({ phone, password: "nope-not-it" })).rejects.toThrow(
      /Incorrect phone or password/,
    );
  });

  it("rotates refresh tokens and revokes the chain on reuse (FR-AUTH-06)", async () => {
    const { session } = await newResident();

    const rotated = await stack.auth.refresh(session.refreshToken);
    expect(rotated.refreshToken).not.toBe(session.refreshToken);

    // Replaying the original token means it leaked: kill every live session.
    await expect(stack.auth.refresh(session.refreshToken)).rejects.toThrow(/revoked/i);
    await expect(stack.auth.refresh(rotated.refreshToken)).rejects.toThrow(/revoked/i);
  });

  it("carries ward scope in the access token for a ward admin", async () => {
    const admin = await stack.auth.login({ phone: "919000000002", password: "devpassword" });
    const claims = stack.tokens.verifyAccess(admin.accessToken);
    expect(claims.role).toBe("ward_admin");
    expect(claims.wardId).toBeTruthy();
  });

  it("requires phone re-verification when a driver signs in on a new device (CHK012)", async () => {
    const driverPhone = "919999900001";
    await stack.db.updateTable("drivers").set({ user_id: null }).where("phone", "=", driverPhone).execute();
    await stack.db.deleteFrom("users").where("phone", "=", driverPhone).execute();

    const verificationToken = await verifiedPhone(stack, driverPhone);
    await stack.auth.register({
      role: "driver",
      verificationToken,
      credential: { password: "drivepass1" },
      profile: { locale: "kn", consent: true },
      deviceId: "device-known",
    });

    await expect(
      stack.auth.login({ phone: driverPhone, password: "drivepass1", deviceId: "device-other" }),
    ).rejects.toThrow(/Verify your phone number again/i);

    // The rejected attempt also revoked the old device's session.
    await expect(
      stack.auth.login({ phone: driverPhone, password: "drivepass1", deviceId: "device-known" }),
    ).resolves.toHaveProperty("accessToken");
  });
});
