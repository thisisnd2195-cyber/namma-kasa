import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createHash, randomBytes } from "node:crypto";
import jwt from "jsonwebtoken";
import { accessClaimsSchema, type AccessClaims } from "@namma-kasa/shared";
import { DB, type Db } from "../../db/db.module";

const hashToken = (raw: string): string => createHash("sha256").update(raw).digest("hex");

@Injectable()
export class TokensService {
  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly config: ConfigService,
  ) {}

  private get secret(): string {
    return this.config.getOrThrow<string>("JWT_SECRET");
  }

  get accessTtlSec(): number {
    return this.config.get<number>("ACCESS_TOKEN_TTL_MIN", 15) * 60;
  }

  signAccess(claims: AccessClaims): string {
    return jwt.sign(claims, this.secret, { expiresIn: this.accessTtlSec });
  }

  verifyAccess(token: string): AccessClaims {
    try {
      return accessClaimsSchema.parse(jwt.verify(token, this.secret));
    } catch {
      throw new HttpException("Invalid or expired token", HttpStatus.UNAUTHORIZED);
    }
  }

  /** Short-lived proof that a phone number was just OTP-verified. */
  signVerification(phone: string): string {
    return jwt.sign({ phone, purpose: "verification" }, this.secret, { expiresIn: "15m" });
  }

  readVerification(token: string): string {
    try {
      const payload = jwt.verify(token, this.secret) as { phone?: string; purpose?: string };
      if (payload.purpose !== "verification" || !payload.phone) throw new Error("wrong purpose");
      return payload.phone;
    } catch {
      throw new HttpException("Phone verification expired", HttpStatus.UNAUTHORIZED);
    }
  }

  async issueRefresh(userId: string, deviceId?: string, rotatedFrom?: string): Promise<string> {
    const raw = randomBytes(48).toString("base64url");
    const days = this.config.get<number>("REFRESH_TOKEN_TTL_DAYS", 30);
    await this.db
      .insertInto("refresh_tokens")
      .values({
        user_id: userId,
        token_hash: hashToken(raw),
        device_id: deviceId ?? null,
        expires_at: new Date(Date.now() + days * 86_400_000),
        rotated_from: rotatedFrom ?? null,
      })
      .execute();
    return raw;
  }

  /**
   * Rotates a refresh token. Presenting an already-rotated token means the
   * token leaked, so the whole chain for that user is revoked.
   */
  async rotate(rawToken: string): Promise<{ userId: string; refreshToken: string }> {
    const row = await this.db
      .selectFrom("refresh_tokens")
      .selectAll()
      .where("token_hash", "=", hashToken(rawToken))
      .executeTakeFirst();

    if (!row) throw new HttpException("Invalid refresh token", HttpStatus.UNAUTHORIZED);

    if (row.revoked_at || new Date(row.expires_at) < new Date()) {
      await this.revokeAllFor(row.user_id);
      throw new HttpException("Session revoked. Sign in again.", HttpStatus.UNAUTHORIZED);
    }

    await this.db
      .updateTable("refresh_tokens")
      .set({ revoked_at: new Date() })
      .where("id", "=", row.id)
      .execute();

    const refreshToken = await this.issueRefresh(row.user_id, row.device_id ?? undefined, row.id);
    return { userId: row.user_id, refreshToken };
  }

  async revokeAllFor(userId: string): Promise<void> {
    await this.db
      .updateTable("refresh_tokens")
      .set({ revoked_at: new Date() })
      .where("user_id", "=", userId)
      .where("revoked_at", "is", null)
      .execute();
  }
}
