import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { randomInt } from "node:crypto";
import type Redis from "ioredis";
import { OTP_POLICY } from "@namma-kasa/shared";
import { REDIS } from "../../../redis/redis.module";
import { OTP_SENDER, type OtpSender } from "./otp-sender";

const codeKey = (phone: string): string => `otp:${phone}`;
const attemptsKey = (phone: string): string => `otp:attempts:${phone}`;
const cooldownKey = (phone: string): string => `otp:cooldown:${phone}`;
const hourlyKey = (phone: string): string => `otp:hourly:${phone}`;

@Injectable()
export class OtpService {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(OTP_SENDER) private readonly sender: OtpSender,
  ) {}

  /** FR-AUTH-02: 5-minute expiry, 30 s resend cooldown, 5 per number per hour. */
  async send(phone: string): Promise<{ resendAfterSec: number }> {
    const cooldown = await this.redis.ttl(cooldownKey(phone));
    if (cooldown > 0) {
      throw new HttpException(
        `Wait ${cooldown}s before requesting another code`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const hourly = await this.redis.incr(hourlyKey(phone));
    if (hourly === 1) await this.redis.expire(hourlyKey(phone), 3600);
    if (hourly > OTP_POLICY.maxPerNumberPerHour) {
      throw new HttpException(
        "Too many codes requested for this number. Try again later.",
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const code = String(randomInt(0, 1_000_000)).padStart(OTP_POLICY.codeLength, "0");
    await this.redis
      .multi()
      .set(codeKey(phone), code, "EX", OTP_POLICY.ttlSeconds)
      .del(attemptsKey(phone))
      .set(cooldownKey(phone), "1", "EX", OTP_POLICY.resendCooldownSeconds)
      .exec();

    await this.sender.send(phone, code);
    return { resendAfterSec: OTP_POLICY.resendCooldownSeconds };
  }

  /**
   * Consumes the code on success. Three wrong guesses burn the code so an
   * attacker cannot keep trying against one issued OTP.
   */
  async verify(phone: string, code: string): Promise<void> {
    const stored = await this.redis.get(codeKey(phone));
    if (!stored) {
      throw new HttpException("Code expired. Request a new one.", HttpStatus.GONE);
    }

    if (stored !== code) {
      const attempts = await this.redis.incr(attemptsKey(phone));
      await this.redis.expire(attemptsKey(phone), OTP_POLICY.ttlSeconds);
      if (attempts >= OTP_POLICY.maxAttempts) {
        await this.redis.del(codeKey(phone), attemptsKey(phone));
        throw new HttpException("Too many wrong attempts. Request a new code.", HttpStatus.GONE);
      }
      throw new HttpException("Incorrect code", HttpStatus.UNAUTHORIZED);
    }

    await this.redis.del(codeKey(phone), attemptsKey(phone));
  }
}
