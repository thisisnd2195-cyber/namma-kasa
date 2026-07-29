import { z } from "zod";
import { createDocument, type ZodOpenApiPathsObject } from "zod-openapi";
import {
  authTokensSchema,
  loginRequestSchema,
  otpSendRequestSchema,
  otpSendResponseSchema,
  otpVerifyRequestSchema,
  otpVerifyResponseSchema,
  problemSchema,
  refreshRequestSchema,
  registerRequestSchema,
  // Named so the generated client gets DriverAssignment rather than
  // DriverAssignmentGet200Response.
  adminComplaintSchema,
  cityRollupSchema,
  latLngSchema,
  driverIssueRecordSchema,
  missedPickupSchema,
  autoSchema,
  complaintSchema,
  driverAssignmentSchema,
  driverSchema,
  householdSchema,
  importReportSchema,
  operatorSchema,
  ratingSchema,
  residentHomeSchema,
  reviewQueueItemSchema,
  routeSchema,
  tripSchema,
  wardSchema,
} from "@namma-kasa/shared";
import { apiPaths } from "./paths";

/**
 * The OpenAPI document is derived from the same Zod schemas the runtime
 * validates with, so the published contract cannot drift from behaviour
 * (constitution Principle IV). The Dart client is generated from this file.
 */

const problem = {
  content: { "application/problem+json": { schema: problemSchema } },
} as const;

const json = <T>(schema: T) => ({ content: { "application/json": { schema } } });

/** Locale carries a default; see the note in paths.ts. */
const openApiRegisterRequest = z.union([
  z.object({
    role: z.literal("resident"),
    verificationToken: z.string(),
    credential: z.record(z.unknown()),
    profile: z.object({
      fullName: z.string(),
      addressLine: z.string(),
      landmark: z.string().optional(),
      pin: z.object({ lat: z.number(), lng: z.number() }),
      locale: z.enum(["en", "kn"]).optional(),
      consent: z.boolean(),
    }),
  }),
  z.object({
    role: z.literal("driver"),
    verificationToken: z.string(),
    credential: z.record(z.unknown()),
    profile: z.object({ locale: z.enum(["en", "kn"]).optional(), consent: z.boolean() }),
    deviceId: z.string(),
  }),
]);

const authPaths: ZodOpenApiPathsObject = {
  "/auth/otp/send": {
    post: {
      tags: ["auth"],
      summary: "Send a one-time code to a phone number",
      requestBody: json(otpSendRequestSchema),
      responses: {
        202: { description: "Code sent", ...json(otpSendResponseSchema) },
        429: { description: "Cooldown or hourly cap hit", ...problem },
      },
    },
  },
  "/auth/otp/verify": {
    post: {
      tags: ["auth"],
      summary: "Exchange a one-time code for a verification token",
      requestBody: json(otpVerifyRequestSchema),
      responses: {
        200: { description: "Phone verified", ...json(otpVerifyResponseSchema) },
        401: { description: "Incorrect code", ...problem },
        410: { description: "Code expired or burned", ...problem },
      },
    },
  },
  "/auth/register": {
    post: {
      tags: ["auth"],
      summary: "Create a resident or driver account",
      requestBody: json(openApiRegisterRequest),
      responses: {
        201: { description: "Account created", ...json(authTokensSchema) },
        403: { description: "Driver number not pre-provisioned", ...problem },
        409: { description: "Account already exists", ...problem },
      },
    },
  },
  "/auth/login": {
    post: {
      tags: ["auth"],
      summary: "Sign in with password or Google",
      requestBody: json(loginRequestSchema),
      responses: {
        200: { description: "Signed in", ...json(authTokensSchema) },
        401: { description: "Bad credentials", ...problem },
        428: { description: "Driver new device: re-verify phone", ...problem },
      },
    },
  },
  "/auth/refresh": {
    post: {
      tags: ["auth"],
      summary: "Rotate a refresh token",
      requestBody: json(refreshRequestSchema),
      responses: {
        200: { description: "Rotated", ...json(authTokensSchema) },
        401: { description: "Invalid or reused token", ...problem },
      },
    },
  },
};

export function buildOpenApiDocument(): ReturnType<typeof createDocument> {
  return createDocument({
    openapi: "3.1.0",
    info: {
      title: "Namma Kasa API",
      version: "0.1.0",
      description:
        "Live tracking of door-to-door waste collection. Errors are RFC 9457 problem+json.",
    },
    servers: [{ url: "http://localhost:4000/v1", description: "Local" }],
    components: {
      // Registering these by name keeps the generated Dart models readable
      // (AuthTokens, SessionUser…) instead of anonymous inline structures.
      schemas: {
        Problem: problemSchema,
        AuthTokens: authTokensSchema,
        OtpSendRequest: otpSendRequestSchema,
        OtpSendResponse: otpSendResponseSchema,
        OtpVerifyRequest: otpVerifyRequestSchema,
        OtpVerifyResponse: otpVerifyResponseSchema,
        RegisterRequest: openApiRegisterRequest,
        LoginRequest: loginRequestSchema,
        RefreshRequest: refreshRequestSchema,

        Ward: wardSchema,
        Route: routeSchema.extend({
          wasteTypeSchedule: z.record(z.string(), z.array(z.string())),
        }),
        Operator: operatorSchema,
        Auto: autoSchema,
        Driver: driverSchema,
        ImportReport: importReportSchema,
        ReviewQueueItem: reviewQueueItemSchema,
        DriverAssignment: driverAssignmentSchema,
        Trip: tripSchema,
        ResidentHome: residentHomeSchema,
        Household: householdSchema,
        Complaint: complaintSchema,
        AdminComplaint: adminComplaintSchema,
        Rating: ratingSchema,
        // Named so the Dart generator stops inventing a name from whichever
        // endpoint happens to sort first — adding a route renamed it once.
        GeoPoint: latLngSchema,
        CityRollup: cityRollupSchema,
        MissedPickup: missedPickupSchema,
        DriverIssueRecord: driverIssueRecordSchema,
      },
      securitySchemes: {
        bearer: { type: "http", scheme: "bearer", bearerFormat: "JWT" },
      },
      responses: {
        Problem: {
          description: "RFC 9457 problem document",
          content: { "application/problem+json": { schema: problemSchema } },
        },
      },
    },
    paths: { ...authPaths, ...apiPaths },
  });
}
