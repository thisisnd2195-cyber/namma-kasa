import { ConfigService } from "@nestjs/config";
import Redis from "ioredis";
import { createTestDb } from "./db";
import { AuthService } from "../../src/modules/auth/auth.service";
import { OtpService } from "../../src/modules/auth/otp/otp.service";
import { TokensService } from "../../src/modules/auth/tokens.service";
import { HouseholdMappingService } from "../../src/modules/geo/household-mapping.service";
import type { OtpSender } from "../../src/modules/auth/otp/otp-sender";

const TEST_ENV: Record<string, unknown> = {
  JWT_SECRET: "test-secret-value-long-enough",
  ACCESS_TOKEN_TTL_MIN: 15,
  REFRESH_TOKEN_TTL_DAYS: 30,
};

/** Captures codes instead of sending them, so tests can complete the flow. */
export class CapturingOtpSender implements OtpSender {
  readonly sent: { phone: string; code: string }[] = [];

  async send(phone: string, code: string): Promise<void> {
    this.sent.push({ phone, code });
  }

  lastCodeFor(phone: string): string {
    const entry = [...this.sent].reverse().find((s) => s.phone === phone);
    if (!entry) throw new Error(`No OTP captured for ${phone}`);
    return entry.code;
  }
}

export function buildAuthStack() {
  const db = createTestDb();
  const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");
  const config = new ConfigService(TEST_ENV);
  const sender = new CapturingOtpSender();

  const otp = new OtpService(redis, sender);
  const tokens = new TokensService(db, config);
  const mapping = new HouseholdMappingService(db);
  const auth = new AuthService(db, otp, tokens, mapping, config);

  return {
    db,
    redis,
    otp,
    tokens,
    auth,
    sender,
    async close(): Promise<void> {
      await db.destroy();
      redis.disconnect();
    },
  };
}

/** Completes OTP send + verify and returns the verification token. */
export async function verifiedPhone(
  stack: ReturnType<typeof buildAuthStack>,
  phone: string,
): Promise<string> {
  await stack.redis.del(
    `otp:${phone}`,
    `otp:attempts:${phone}`,
    `otp:cooldown:${phone}`,
    `otp:hourly:${phone}`,
  );
  await stack.auth.sendOtp(phone);
  const { verificationToken } = await stack.auth.verifyOtp(phone, stack.sender.lastCodeFor(phone));
  return verificationToken;
}

export const randomPhone = (): string =>
  `9198${Math.floor(Math.random() * 90_000_000 + 10_000_000)}`.slice(0, 12);
