import { z } from "zod";
import type { ZodOpenApiPathsObject } from "zod-openapi";
import {
  adminComplaintSchema,
  assignAutoToDriverSchema,
  assignRouteToAutoSchema,
  autoRouteAssignmentSchema,
  autoSchema,
  driverAutoAssignmentSchema,
  livePositionSchema,
  complaintSchema,
  confirmMediaSchema,
  createAutoSchema,
  createComplaintSchema,
  createDriverSchema,
  createOperatorSchema,
  createRatingSchema,
  createRouteSchema,
  createWardAdminSchema,
  createWardSchema,
  driverAssignmentSchema,
  driverSchema,
  endTripSchema,
  geoJsonAreaSchema,
  householdSchema,
  importReportSchema,
  importWardsSchema,
  operatorSchema,
  pingAcceptedSchema,
  pingBatchSchema,
  presignRequestSchema,
  presignResponseSchema,
  ratingSchema,
  residentHomeSchema,
  residentSettingsSchema,
  reviewQueueItemSchema,
  routeSchema,
  startTripSchema,
  tripSchema,
  updateAutoSchema,
  updateComplaintSchema,
  updateDriverSchema,
  updateHouseholdSchema,
  updateOperatorSchema,
  updateRouteSchema,
  updateWardSchema,
  wardEditImpactSchema,
  wardSchema,
} from "@namma-kasa/shared";

/**
 * Every route the API serves, beyond the auth endpoints in document.ts.
 *
 * `pnpm contracts:coverage` compares this against the routes the router
 * actually exposes, so an endpoint added without a contract fails the build.
 */

const json = <T>(schema: T) => ({ content: { "application/json": { schema } } });
const problem = { $ref: "#/components/responses/Problem" } as const;

const ok = <T>(description: string, schema: T) => ({ description, ...json(schema) });
const noContent = (description: string) => ({ description });

/** Every non-auth route carries a bearer token. */
const secured = [{ bearer: [] as string[] }];

/**
 * The waste schedule is a record keyed "1".."7". The Dart generator emits
 * uncompilable code for a record of enum arrays, so the published contract
 * describes it as a plain map of string arrays. Runtime validation in
 * packages/shared is unchanged and still enforces the weekday keys and the
 * waste-type enum.
 */
const openApiWasteSchedule = z.record(z.string(), z.array(z.string()));

const openApiRouteSchema = routeSchema.extend({
  wasteTypeSchedule: openApiWasteSchedule,
});
const openApiCreateRoute = createRouteSchema.extend({
  wasteTypeSchedule: openApiWasteSchedule.optional(),
});
const openApiUpdateRoute = updateRouteSchema.extend({
  wasteTypeSchedule: openApiWasteSchedule.optional(),
});

/** Same generator limitation as the waste schedule: enum + default is unsafe. */
const mediaKind = z.enum(["collection_proof", "issue", "other"]);
const openApiPresign = presignRequestSchema.extend({ type: mediaKind.optional() });
const openApiConfirmMedia = confirmMediaSchema.extend({ type: mediaKind.optional() });

const idParam = z.object({ id: z.string().uuid() });
const wardIdParam = z.object({ wardId: z.string().uuid() });

export const apiPaths: ZodOpenApiPathsObject = {
  // ------------------------------------------------------------ admin: geo
  "/admin/operators": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "List operators with their ward counts",
      responses: { 200: ok("Operators", z.array(operatorSchema)), 403: problem },
    },
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Create an operator",
      requestBody: json(createOperatorSchema),
      responses: { 201: ok("Created", operatorSchema), 403: problem },
    },
  },
  "/admin/operators/{id}": {
    patch: {
      tags: ["admin"],
      security: secured,
      summary: "Update or retire an operator",
      requestParams: { path: idParam },
      requestBody: json(updateOperatorSchema),
      responses: {
        200: ok("Updated", operatorSchema),
        409: problem, // still owns active wards
      },
    },
  },
  "/admin/wards": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "List wards visible to the caller",
      responses: { 200: ok("Wards", z.array(wardSchema)) },
    },
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Create a ward",
      requestBody: json(createWardSchema),
      responses: {
        201: ok("Created", wardSchema),
        409: problem, // boundary overlaps an existing ward
      },
    },
  },
  "/admin/wards/{wardId}": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "Fetch one ward",
      requestParams: { path: wardIdParam },
      responses: { 200: ok("Ward", wardSchema), 403: problem, 404: problem },
    },
    patch: {
      tags: ["admin"],
      security: secured,
      summary: "Update a ward, including reshaping its boundary",
      requestParams: { path: wardIdParam },
      requestBody: json(updateWardSchema),
      responses: { 200: ok("Updated", wardSchema), 409: problem },
    },
  },
  "/admin/wards/{wardId}/edit-impact": {
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Preview what reshaping a boundary would strand",
      requestParams: { path: wardIdParam },
      requestBody: json(geoJsonAreaSchema),
      responses: { 200: ok("Impact", wardEditImpactSchema), 404: problem },
    },
  },
  "/admin/wards/import": {
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Bulk import boundaries, accepting or rejecting each feature",
      requestBody: json(importWardsSchema),
      responses: { 201: ok("Per-feature report", importReportSchema) },
    },
  },
  "/admin/ward-admins": {
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Provision a ward admin account",
      requestBody: json(createWardAdminSchema),
      responses: {
        201: ok("Created", z.object({ userId: z.string().uuid() })),
        409: problem,
      },
    },
  },
  "/admin/routes": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "List routes in a ward",
      requestParams: { query: z.object({ wardId: z.string().uuid().optional() }) },
      responses: { 200: ok("Routes", z.array(openApiRouteSchema)) },
    },
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Create a route",
      requestBody: json(openApiCreateRoute),
      responses: {
        201: ok("Created", openApiRouteSchema),
        409: problem, // overlaps a sibling route
        422: problem, // area leaves the ward
      },
    },
  },
  "/admin/routes/{id}": {
    patch: {
      tags: ["admin"],
      security: secured,
      summary: "Update a route",
      requestParams: { path: idParam },
      requestBody: json(openApiUpdateRoute),
      responses: { 200: ok("Updated", openApiRouteSchema), 409: problem, 422: problem },
    },
  },
  "/admin/households/review-queue": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "Households awaiting manual route assignment",
      responses: { 200: ok("Queue", z.array(reviewQueueItemSchema)) },
    },
  },
  "/admin/households/{id}/route": {
    patch: {
      tags: ["admin"],
      security: secured,
      summary: "Place a household on a route by hand",
      requestParams: { path: idParam },
      requestBody: json(z.object({ routeId: z.string().uuid() })),
      responses: {
        200: ok(
          "Assigned",
          z.object({
            id: z.string().uuid(),
            routeId: z.string().uuid(),
            mappingStatus: z.literal("admin_corrected"),
          }),
        ),
        403: problem,
      },
    },
  },

  // ---------------------------------------------------------- admin: fleet
  "/admin/autos": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "List autos in a ward",
      requestParams: {
        query: z.object({
          wardId: z.string().uuid().optional(),
          available: z.enum(["true", "false"]).optional(),
        }),
      },
      responses: { 200: ok("Autos", z.array(autoSchema)) },
    },
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Onboard an auto",
      requestBody: json(createAutoSchema),
      responses: { 201: ok("Created", autoSchema), 409: problem },
    },
  },
  "/admin/autos/{id}": {
    patch: {
      tags: ["admin"],
      security: secured,
      summary: "Update an auto or change its status",
      requestParams: { path: idParam },
      requestBody: json(updateAutoSchema),
      responses: {
        200: ok("Updated", autoSchema),
        409: problem, // mid-trip
      },
    },
  },
  "/admin/autos/{id}/assign-route": {
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Assign an auto to a route, closing any open assignment",
      requestParams: { path: idParam },
      requestBody: json(assignRouteToAutoSchema),
      responses: { 204: noContent("Assigned"), 409: problem },
    },
  },
  "/admin/autos/{id}/assignments": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "Append-only assignment history for an auto",
      requestParams: { path: idParam },
      responses: {
        200: ok(
          "History",
          z.object({
            routes: z.array(autoRouteAssignmentSchema),
            drivers: z.array(driverAutoAssignmentSchema),
          }),
        ),
      },
    },
  },
  "/admin/drivers": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "List drivers in a ward",
      requestParams: { query: z.object({ wardId: z.string().uuid().optional() }) },
      responses: { 200: ok("Drivers", z.array(driverSchema)) },
    },
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Pre-provision a driver so that number can register",
      requestBody: json(createDriverSchema),
      responses: { 201: ok("Created", driverSchema), 409: problem },
    },
  },
  "/admin/drivers/{id}": {
    patch: {
      tags: ["admin"],
      security: secured,
      summary: "Update a driver or deactivate them",
      requestParams: { path: idParam },
      requestBody: json(updateDriverSchema),
      responses: { 200: ok("Updated", driverSchema), 409: problem },
    },
  },
  "/admin/drivers/{id}/assign-auto": {
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Assign a driver to an auto",
      requestParams: { path: idParam },
      requestBody: json(assignAutoToDriverSchema),
      responses: { 204: noContent("Assigned"), 409: problem },
    },
  },

  // ------------------------------------------------- admin: live, complaints
  "/admin/live/wards/{wardId}": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "Active autos and tracking-dropped alerts for a ward",
      requestParams: { path: wardIdParam },
      responses: {
        200: ok(
          "Live view",
          z.object({
            positions: z.array(livePositionSchema),
            alerts: z.array(
              z.object({
                tripId: z.string().uuid(),
                registrationNumber: z.string(),
                routeName: z.string(),
                silentForMin: z.number().int(),
              }),
            ),
          }),
        ),
      },
    },
  },
  "/admin/complaints": {
    get: {
      tags: ["admin"],
      security: secured,
      summary: "Ward complaint queue, with the collection evidence for each",
      requestParams: {
        query: z.object({
          wardId: z.string().uuid().optional(),
          status: z.string().optional(),
        }),
      },
      responses: { 200: ok("Complaints", z.array(adminComplaintSchema)) },
    },
  },
  "/admin/complaints/{id}": {
    patch: {
      tags: ["admin"],
      security: secured,
      summary: "Move a complaint through its status workflow",
      requestParams: { path: idParam },
      requestBody: json(updateComplaintSchema),
      responses: {
        200: ok("Updated", complaintSchema),
        409: problem, // illegal transition
        403: problem,
      },
    },
  },
  "/admin/advisories": {
    post: {
      tags: ["admin"],
      security: secured,
      summary: "Broadcast a schedule change to a route's residents",
      requestBody: json(z.object({ routeId: z.string().uuid(), note: z.string() })),
      responses: {
        202: ok("Queued", z.object({ notified: z.number().int() })),
        403: problem,
      },
    },
  },

  // ---------------------------------------------------------------- driver
  "/driver/assignment": {
    get: {
      tags: ["driver"],
      security: secured,
      summary: "Today's auto, route, waste types and pass progress",
      responses: { 200: ok("Assignment", driverAssignmentSchema), 404: problem },
    },
  },
  "/driver/trips": {
    post: {
      tags: ["driver"],
      security: secured,
      summary: "Start a pass",
      requestBody: json(startTripSchema),
      responses: {
        201: ok("Trip started", tripSchema),
        409: problem, // previous pass unsettled, or auto already on a trip
      },
    },
  },
  "/driver/trips/{id}/end": {
    patch: {
      tags: ["driver"],
      security: secured,
      summary: "End a trip",
      requestParams: { path: idParam },
      requestBody: json(endTripSchema),
      responses: { 200: ok("Trip ended", tripSchema), 403: problem, 409: problem },
    },
  },
  "/driver/trips/{id}/pings": {
    post: {
      tags: ["driver"],
      security: secured,
      summary: "HTTPS fallback for position batches when MQTT is unreachable",
      requestParams: { path: idParam },
      requestBody: json(pingBatchSchema),
      responses: { 202: ok("Accepted", pingAcceptedSchema), 403: problem },
    },
  },
  "/driver/trips/{id}/mqtt-token": {
    post: {
      tags: ["driver"],
      security: secured,
      summary: "Broker credentials scoped to this trip's topic",
      requestParams: { path: idParam },
      responses: {
        201: ok(
          "Credentials",
          z.object({
            username: z.string(),
            password: z.string(),
            expiresInSec: z.number().int(),
          }),
        ),
        403: problem,
      },
    },
  },
  "/driver/trips/{id}/media/presign": {
    post: {
      tags: ["driver"],
      security: secured,
      summary: "Presigned URL for a collection-proof photo",
      requestParams: { path: idParam },
      requestBody: json(openApiPresign),
      responses: { 201: ok("Presigned", presignResponseSchema), 409: problem },
    },
  },
  "/driver/trips/{id}/media/confirm": {
    post: {
      tags: ["driver"],
      security: secured,
      summary: "Record a photo once its upload succeeded",
      requestParams: { path: idParam },
      requestBody: json(openApiConfirmMedia),
      responses: { 201: ok("Recorded", z.object({ id: z.string().uuid() })) },
    },
  },

  // -------------------------------------------------------------- resident
  "/resident/home": {
    get: {
      tags: ["resident"],
      security: secured,
      summary: "Route, schedule, serving autos and last collection",
      responses: { 200: ok("Home", residentHomeSchema), 404: problem },
    },
  },
  "/resident/household": {
    patch: {
      tags: ["resident"],
      security: secured,
      summary: "Edit house details; moving the pin re-runs route mapping",
      requestBody: json(updateHouseholdSchema),
      responses: { 200: ok("Updated", householdSchema) },
    },
  },
  "/resident/settings": {
    patch: {
      tags: ["resident"],
      security: secured,
      summary: "Alert radius and language",
      requestBody: json(residentSettingsSchema),
      responses: { 200: ok("Updated", householdSchema) },
    },
  },
  "/resident/complaints": {
    get: {
      tags: ["resident"],
      security: secured,
      summary: "Complaints raised by this household",
      responses: { 200: ok("Complaints", z.array(complaintSchema)) },
    },
    post: {
      tags: ["resident"],
      security: secured,
      summary: "Raise a complaint",
      requestBody: json(createComplaintSchema),
      responses: {
        201: ok("Created", complaintSchema),
        429: problem, // daily cap
      },
    },
  },
  "/resident/ratings": {
    post: {
      tags: ["resident"],
      security: secured,
      summary: "Rate today's collection, once per day",
      requestBody: json(createRatingSchema),
      responses: {
        201: ok("Recorded", ratingSchema),
        409: problem, // already rated, or nothing collected yet
      },
    },
  },

  // ------------------------------------------------ notifications, account
  "/notifications/devices": {
    post: {
      tags: ["notifications"],
      security: secured,
      summary: "Register this device for push",
      requestBody: json(z.object({ fcmToken: z.string() })),
      responses: { 204: noContent("Registered") },
    },
  },
  "/me": {
    delete: {
      tags: ["account"],
      security: secured,
      summary: "Request account deletion; personal data is erased after 30 days",
      responses: {
        202: ok(
          "Scheduled",
          z.object({ erasesAfter: z.string().datetime(), note: z.string() }),
        ),
      },
    },
  },
  "/me/retention-policy": {
    get: {
      tags: ["account"],
      security: secured,
      summary: "How long each kind of data is kept",
      responses: {
        200: ok(
          "Policy",
          z.object({
            deletionGraceDays: z.number().int(),
            mediaRetentionDays: z.number().int(),
            pingRetentionDays: z.number().int(),
          }),
        ),
      },
    },
  },
};
