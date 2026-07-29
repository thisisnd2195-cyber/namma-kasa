import { z } from "zod";
import { authProviderSchema, localeSchema, userRoleSchema } from "./enums";
import { bengaluruLatLngSchema, phoneSchema, uuidSchema } from "./common";

/** OTP policy from FR-AUTH-02, enforced in Redis. */
export const OTP_POLICY = {
  codeLength: 6,
  ttlSeconds: 5 * 60,
  maxAttempts: 3,
  resendCooldownSeconds: 30,
  maxPerNumberPerHour: 5,
} as const;

export const otpSendRequestSchema = z.object({ phone: phoneSchema });
export const otpSendResponseSchema = z.object({ resendAfterSec: z.number().int() });

export const otpVerifyRequestSchema = z.object({
  phone: phoneSchema,
  code: z.string().regex(/^\d{6}$/, "Enter the 6-digit code"),
});
export const otpVerifyResponseSchema = z.object({ verificationToken: z.string() });

/** Exactly one credential path is set up after phone verification (FR-AUTH-03). */
export const credentialSchema = z.union([
  z.object({ password: z.string().min(8, "Use at least 8 characters") }),
  z.object({ googleIdToken: z.string().min(1) }),
]);

export const householdProfileSchema = z.object({
  fullName: z.string().trim().min(1).max(120),
  addressLine: z.string().trim().min(1).max(300),
  landmark: z.string().trim().max(200).optional(),
  pin: bengaluruLatLngSchema,
  locale: localeSchema.default("en"),
  /** DPDP requires explicit, recorded consent for phone and location (NFR-04). */
  consent: z.literal(true, {
    errorMap: () => ({ message: "Consent is required to create an account" }),
  }),
});

export const driverProfileSchema = z.object({
  locale: localeSchema.default("kn"),
  consent: z.literal(true, {
    errorMap: () => ({ message: "Consent to trip-time tracking is required" }),
  }),
});

export const registerRequestSchema = z.discriminatedUnion("role", [
  z.object({
    role: z.literal("resident"),
    verificationToken: z.string(),
    credential: credentialSchema,
    profile: householdProfileSchema,
  }),
  z.object({
    role: z.literal("driver"),
    verificationToken: z.string(),
    credential: credentialSchema,
    profile: driverProfileSchema,
    deviceId: z.string().min(1),
  }),
]);

export const loginRequestSchema = z.union([
  z.object({
    phone: phoneSchema,
    password: z.string().min(1),
    deviceId: z.string().optional(),
  }),
  z.object({ googleIdToken: z.string().min(1), deviceId: z.string().optional() }),
]);

export const refreshRequestSchema = z.object({ refreshToken: z.string().min(1) });

export const sessionUserSchema = z.object({
  id: uuidSchema,
  role: userRoleSchema,
  locale: localeSchema,
  authProvider: authProviderSchema,
  wardId: uuidSchema.nullable(),
});
export type SessionUser = z.infer<typeof sessionUserSchema>;

export const authTokensSchema = z.object({
  accessToken: z.string(),
  refreshToken: z.string(),
  expiresInSec: z.number().int(),
  user: sessionUserSchema,
});
export type AuthTokens = z.infer<typeof authTokensSchema>;

/** Claims carried by the access token; ward scope is enforced from here. */
export const accessClaimsSchema = z.object({
  sub: uuidSchema,
  role: userRoleSchema,
  wardId: uuidSchema.nullish(),
  routeId: uuidSchema.nullish(),
  deviceId: z.string().nullish(),
});
export type AccessClaims = z.infer<typeof accessClaimsSchema>;
