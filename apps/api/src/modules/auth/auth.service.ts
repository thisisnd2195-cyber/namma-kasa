import { HttpException, HttpStatus, Inject, Injectable } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import * as argon2 from "argon2";
import { OAuth2Client } from "google-auth-library";
import { sql } from "kysely";
import type { AuthTokens, SessionUser } from "@namma-kasa/shared";
import {
  loginRequestSchema,
  registerRequestSchema,
  type authTokensSchema,
} from "@namma-kasa/shared";
import type { z } from "zod";
import { DB, type Db } from "../../db/db.module";
import { HouseholdMappingService } from "../geo/household-mapping.service";
import { OtpService } from "./otp/otp.service";
import { TokensService } from "./tokens.service";

type RegisterRequest = z.infer<typeof registerRequestSchema>;
type LoginRequest = z.infer<typeof loginRequestSchema>;

@Injectable()
export class AuthService {
  private readonly google: OAuth2Client;

  constructor(
    @Inject(DB) private readonly db: Db,
    private readonly otp: OtpService,
    private readonly tokens: TokensService,
    private readonly mapping: HouseholdMappingService,
    private readonly config: ConfigService,
  ) {
    this.google = new OAuth2Client(this.config.get<string>("GOOGLE_CLIENT_ID"));
  }

  async sendOtp(phone: string): Promise<{ resendAfterSec: number }> {
    return this.otp.send(phone);
  }

  async verifyOtp(phone: string, code: string): Promise<{ verificationToken: string }> {
    await this.otp.verify(phone, code);
    return { verificationToken: this.tokens.signVerification(phone) };
  }

  async register(request: RegisterRequest): Promise<AuthTokens> {
    const phone = this.tokens.readVerification(request.verificationToken);

    const existing = await this.db
      .selectFrom("users")
      .select("id")
      .where("phone", "=", phone)
      .executeTakeFirst();
    if (existing) {
      throw new HttpException("This number already has an account", HttpStatus.CONFLICT);
    }

    // Anti-impersonation: a driver account only exists if a Ward Admin
    // pre-provisioned that exact number (FR-AUTH-05).
    const driverRecord =
      request.role === "driver"
        ? await this.db
            .selectFrom("drivers")
            .select(["id", "user_id"])
            .where("phone", "=", phone)
            .where("status", "=", "active")
            .executeTakeFirst()
        : undefined;

    if (request.role === "driver" && !driverRecord) {
      throw new HttpException(
        "This number is not registered as a driver. Contact your Ward Admin.",
        HttpStatus.FORBIDDEN,
      );
    }
    if (driverRecord?.user_id) {
      throw new HttpException("This driver already has an account", HttpStatus.CONFLICT);
    }

    const credential = await this.resolveCredential(request.credential);

    // The account and its ward/route wiring commit as one unit; the session is
    // built afterwards because refresh tokens are written on another
    // connection and would not see an uncommitted user row.
    const created = await this.db.transaction().execute(async (trx) => {
      const user = await trx
        .insertInto("users")
        .values({
          phone,
          email: credential.email,
          password_hash: credential.passwordHash,
          auth_provider: credential.provider,
          role: request.role,
          locale: request.profile.locale,
          consented_at: new Date(),
        })
        .returningAll()
        .executeTakeFirstOrThrow();

      if (request.role === "resident") {
        const resolved = await this.mapping.resolve(request.profile.pin);
        await trx
          .insertInto("households")
          .values({
            user_id: user.id,
            full_name: request.profile.fullName,
            address_line: request.profile.addressLine,
            landmark: request.profile.landmark ?? null,
            house_geo: sql<string>`ST_SetSRID(ST_MakePoint(${request.profile.pin.lng}, ${request.profile.pin.lat}), 4326)`,
            ward_id: resolved.wardId,
            route_id: resolved.routeId,
            mapping_status: resolved.status,
          })
          .execute();
        return { userId: user.id };
      }

      await trx
        .updateTable("drivers")
        .set({ user_id: user.id })
        .where("id", "=", driverRecord!.id)
        .execute();
      return { userId: user.id };
    });

    const deviceId = request.role === "driver" ? request.deviceId : undefined;
    return this.buildSession(created.userId, deviceId);
  }

  async login(request: LoginRequest): Promise<AuthTokens> {
    const user =
      "password" in request
        ? await this.byPassword(request.phone, request.password)
        : await this.byGoogle(request.googleIdToken);

    if (user.status === "blocked") {
      throw new HttpException("This account is blocked", HttpStatus.FORBIDDEN);
    }

    // A driver's session is bound to one device; signing in elsewhere requires
    // fresh phone verification and kills the old session (FR-AUTH-04, CHK012).
    if (user.role === "driver") {
      const known = await this.db
        .selectFrom("refresh_tokens")
        .select("device_id")
        .where("user_id", "=", user.id)
        .where("revoked_at", "is", null)
        .executeTakeFirst();
      if (known?.device_id && known.device_id !== request.deviceId) {
        await this.tokens.revokeAllFor(user.id);
        throw new HttpException(
          "New device detected. Verify your phone number again.",
          HttpStatus.PRECONDITION_REQUIRED,
        );
      }
    }

    return this.buildSession(user.id, request.deviceId);
  }

  async refresh(rawToken: string): Promise<AuthTokens> {
    const { userId, refreshToken } = await this.tokens.rotate(rawToken);
    return this.buildSession(userId, undefined, refreshToken);
  }

  private async resolveCredential(
    credential: RegisterRequest["credential"],
  ): Promise<{ provider: "password" | "google"; passwordHash: string | null; email: string | null }> {
    if ("password" in credential) {
      return {
        provider: "password",
        passwordHash: await argon2.hash(credential.password, { type: argon2.argon2id }),
        email: null,
      };
    }
    const email = await this.verifyGoogleToken(credential.googleIdToken);
    const taken = await this.db
      .selectFrom("users")
      .select("id")
      .where(sql<boolean>`lower(email) = lower(${email})`)
      .executeTakeFirst();
    if (taken) {
      throw new HttpException(
        "This Google account is already linked to another number",
        HttpStatus.CONFLICT,
      );
    }
    return { provider: "google", passwordHash: null, email };
  }

  private async verifyGoogleToken(idToken: string): Promise<string> {
    const clientId = this.config.get<string>("GOOGLE_CLIENT_ID");
    if (!clientId) {
      throw new HttpException("Google sign-in is not configured", HttpStatus.NOT_IMPLEMENTED);
    }
    try {
      const ticket = await this.google.verifyIdToken({ idToken, audience: clientId });
      const email = ticket.getPayload()?.email;
      if (!email) throw new Error("no email claim");
      return email;
    } catch {
      throw new HttpException("Google sign-in failed", HttpStatus.UNAUTHORIZED);
    }
  }

  private async byPassword(phone: string, password: string) {
    const user = await this.db
      .selectFrom("users")
      .selectAll()
      .where("phone", "=", phone)
      .executeTakeFirst();

    // Burn comparable CPU when the number is unknown, so response timing does
    // not reveal which numbers are registered.
    if (!user?.password_hash) {
      await argon2.hash(password, { type: argon2.argon2id });
      throw new HttpException("Incorrect phone or password", HttpStatus.UNAUTHORIZED);
    }
    const ok = await argon2.verify(user.password_hash, password).catch(() => false);
    if (!ok) {
      throw new HttpException("Incorrect phone or password", HttpStatus.UNAUTHORIZED);
    }
    return user;
  }

  private async byGoogle(idToken: string) {
    const email = await this.verifyGoogleToken(idToken);
    const user = await this.db
      .selectFrom("users")
      .selectAll()
      .where(sql<boolean>`lower(email) = lower(${email})`)
      .where("auth_provider", "=", "google")
      .executeTakeFirst();
    if (!user) throw new HttpException("No account for this Google user", HttpStatus.UNAUTHORIZED);
    return user;
  }

  private async buildSession(
    userId: string,
    deviceId?: string,
    existingRefresh?: string,
  ): Promise<AuthTokens> {
    const user = await this.db
      .selectFrom("users")
      .selectAll()
      .where("id", "=", userId)
      .executeTakeFirstOrThrow();

    const wardId = await this.wardIdFor(user.id, user.role);
    const routeId =
      user.role === "resident"
        ? ((
            await this.db
              .selectFrom("households")
              .select("route_id")
              .where("user_id", "=", user.id)
              .executeTakeFirst()
          )?.route_id ?? null)
        : null;

    return {
      accessToken: this.tokens.signAccess({
        sub: user.id,
        role: user.role,
        wardId,
        routeId,
        deviceId,
      }),
      refreshToken: existingRefresh ?? (await this.tokens.issueRefresh(user.id, deviceId)),
      expiresInSec: this.tokens.accessTtlSec,
      user: {
        id: user.id,
        role: user.role,
        locale: user.locale,
        authProvider: user.auth_provider,
        wardId,
      },
    };
  }

  private async wardIdFor(userId: string, role: SessionUser["role"]): Promise<string | null> {
    if (role === "ward_admin") {
      const ward = await this.db
        .selectFrom("wards")
        .select("id")
        .where("ward_admin_user_id", "=", userId)
        .executeTakeFirst();
      return ward?.id ?? null;
    }
    if (role === "driver") {
      const driver = await this.db
        .selectFrom("drivers")
        .select("ward_id")
        .where("user_id", "=", userId)
        .executeTakeFirst();
      return driver?.ward_id ?? null;
    }
    if (role === "resident") {
      const household = await this.db
        .selectFrom("households")
        .select("ward_id")
        .where("user_id", "=", userId)
        .executeTakeFirst();
      return household?.ward_id ?? null;
    }
    return null;
  }
}
