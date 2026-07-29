import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { ConfigService } from "@nestjs/config";
import Redis from "ioredis";
import { createTestDb } from "./helpers/db";
import { DegradationLevel, DegradationService } from "../src/modules/tracking/degradation";
import { ConsolePushSender } from "../src/modules/notify/push-sender";
import { ConsoleOtpSender } from "../src/modules/auth/otp/otp-sender";
import { LoggingSahaayaClient } from "../src/modules/complaints/sahaaya";
import { MqttTokenService } from "../src/modules/tracking/mqtt-token.service";

/**
 * The small pieces the HTTP suites reach only incidentally: load shedding, the
 * development senders, and the broker token's ACL claim.
 */
const db = createTestDb();
const redis = new Redis(process.env.REDIS_URL ?? "redis://localhost:6379");

afterAll(async () => {
  await db.destroy();
  redis.disconnect();
});

describe("load shedding (Clarifications CHK043)", () => {
  const degradation = new DegradationService(redis);

  beforeEach(async () => {
    await degradation.setLevel(DegradationLevel.normal);
  });

  it("runs at the full cadence when nothing is wrong", async () => {
    expect(await degradation.level()).toBe(DegradationLevel.normal);
    expect(await degradation.liveIntervalMs()).toBe(2_000);
    expect(await degradation.liveStreamEnabled()).toBe(true);
  });

  it("stretches the live cadence before it drops anything", async () => {
    await degradation.setLevel(DegradationLevel.slowLive);

    expect(await degradation.liveIntervalMs()).toBe(10_000);
    // The map is slower, but it is still there.
    expect(await degradation.liveStreamEnabled()).toBe(true);
  });

  it("pauses the live stream at the next level up", async () => {
    await degradation.setLevel(DegradationLevel.pauseLive);
    expect(await degradation.liveStreamEnabled()).toBe(false);
  });

  it("keeps the stream off at the most degraded level", async () => {
    await degradation.setLevel(DegradationLevel.minimal);

    expect(await degradation.liveStreamEnabled()).toBe(false);
    expect(await degradation.liveIntervalMs()).toBe(10_000);
  });

  it("treats an unset level as normal rather than failing closed", async () => {
    await redis.del("degradation:level");
    expect(await degradation.level()).toBe(DegradationLevel.normal);
  });
});

describe("development senders", () => {
  it("the console push sender reports everything delivered", async () => {
    const sender = new ConsolePushSender();
    const result = await sender.send({
      tokens: ["a", "b"],
      title: "Auto is near",
      body: "300 m",
      data: { kind: "proximity" },
    });

    expect(result.delivered).toBe(2);
    // Nothing to prune: a dev sender never rejects a token.
    expect(result.failedTokens).toEqual([]);
  });

  it("the console push sender copes with no devices registered", async () => {
    const result = await new ConsolePushSender().send({
      tokens: [],
      title: "t",
      body: "b",
      data: {},
    });
    expect(result.delivered).toBe(0);
  });

  it("the console OTP sender does not throw, so local dev never blocks", async () => {
    await expect(new ConsoleOtpSender().send("919888800001", "123456")).resolves.toBeUndefined();
  });

  it("the Sahaaya stub reports no reference, because nothing was synced", async () => {
    const reference = await new LoggingSahaayaClient().push({
      complaintId: "c-1",
      category: "missed_pickup",
      description: null,
      wardCode: "W-1",
      addressLine: "1 Test Road",
      raisedAt: new Date(),
    });

    // Null is the honest answer: a stub must not mint a fake reference id.
    expect(reference).toBeNull();
  });
});

describe("broker credentials (FR-DRV-03)", () => {
  const config = {
    get: (key: string, fallback?: unknown) =>
      ({ JWT_SECRET: "test-secret-at-least-16-chars" })[key] ?? fallback,
    getOrThrow: (key: string) => {
      const value = (config.get as (k: string, f?: unknown) => unknown)(key);
      if (value === undefined) throw new Error(`missing ${key}`);
      return value;
    },
  } as unknown as ConfigService;

  const tokens = new MqttTokenService(config);

  it("grants publish on exactly one trip topic", () => {
    const credentials = tokens.issue("driver-1", "trip-9");
    const [, payload] = credentials.password.split(".");
    const claims = JSON.parse(Buffer.from(payload, "base64url").toString()) as {
      acl: { pub: string[]; sub: string[]; all: string[] };
      sub: string;
    };

    // A compromised device can publish to one trip and nothing else.
    expect(claims.acl.pub).toEqual(["trips/trip-9/pings"]);
    expect(claims.acl.sub).toEqual([]);
    expect(claims.acl.all).toEqual([]);
    expect(claims.sub).toBe("driver-1");
  });

  it("issues a token that expires, so a lost device stops publishing", () => {
    const credentials = tokens.issue("driver-1", "trip-9");
    expect(credentials.expiresInSec).toBeGreaterThan(0);

    const [, payload] = credentials.password.split(".");
    const claims = JSON.parse(Buffer.from(payload, "base64url").toString()) as { exp: number };
    expect(claims.exp).toBeGreaterThan(Math.floor(Date.now() / 1000));
  });

  it("names the driver as the broker username, so publishes are attributable", () => {
    expect(tokens.issue("driver-7", "trip-1").username).toBe("driver-7");
  });
});
