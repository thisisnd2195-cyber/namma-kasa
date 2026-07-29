import { z } from "zod";
import { latLngSchema, timeOfDaySchema, uuidSchema, weekdaySchema } from "./common";
import {
  driverIssueKindSchema,
  mediaTypeSchema,
  passStatusSchema,
  tripEndReasonSchema,
  tripStatusSchema,
  wasteTypeSchema,
} from "./enums";

/** Ingest guards from spec §4. Anything outside these is noise, not movement. */
export const PING_LIMITS = {
  maxAccuracyM: 100,
  maxSpeedKmh: 60,
  /** Speed is judged over a rolling window so one GPS jump cannot reject a run. */
  speedWindow: 3,
  maxBatch: 20,
} as const;

export const pingSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  speed: z.number().nonnegative().nullish(),
  heading: z.number().min(0).max(360).nullish(),
  accuracy: z.number().nonnegative().nullish(),
  recordedAt: z.coerce.date(),
  /** Per-trip monotonic counter; lets the server drop QoS-1 duplicates. */
  seq: z.number().int().nonnegative(),
});
export type Ping = z.infer<typeof pingSchema>;

export const pingBatchSchema = z.object({
  pings: z.array(pingSchema).min(1).max(PING_LIMITS.maxBatch),
});

export const pingAcceptedSchema = z.object({
  accepted: z.number().int(),
  rejected: z.number().int(),
});

export const startTripSchema = z.object({
  passNumber: z.number().int().min(1),
});

export const endTripSchema = z.object({
  reason: tripEndReasonSchema.optional(),
  distanceCoveredM: z.number().int().nonnegative().optional(),
});

export const tripSchema = z.object({
  id: uuidSchema,
  autoId: uuidSchema,
  driverId: uuidSchema,
  routeId: uuidSchema,
  passNumber: z.number().int(),
  serviceDate: z.string(),
  startedAt: z.coerce.date(),
  endedAt: z.coerce.date().nullable(),
  status: tripStatusSchema,
  endReason: tripEndReasonSchema.nullable(),
  distanceCoveredM: z.number().int().nullable(),
});
export type Trip = z.infer<typeof tripSchema>;

/** What a driver sees on opening the app (FR-DRV-01). */
export const driverAssignmentSchema = z.object({
  auto: z.object({ id: uuidSchema, registrationNumber: z.string() }),
  route: z.object({
    id: uuidSchema,
    name: z.string(),
    routeCode: z.string(),
    serviceableArea: z.unknown(),
    windowStart: timeOfDaySchema,
    windowEnd: timeOfDaySchema,
    collectionDays: z.array(weekdaySchema),
  }),
  today: z.object({
    wasteTypes: z.array(wasteTypeSchema),
    passesTotal: z.number().int(),
    passesCompleted: z.number().int(),
    nextPassNumber: z.number().int().nullable(),
    isCollectionDay: z.boolean(),
  }),
  activeTrip: tripSchema.nullable(),
});
export type DriverAssignment = z.infer<typeof driverAssignmentSchema>;

export const passStateSchema = z.object({
  passNumber: z.number().int(),
  status: passStatusSchema,
  tripId: uuidSchema.nullable(),
});

export const presignRequestSchema = z.object({
  contentType: z.string().regex(/^image\/(jpeg|png|webp)$/),
  type: mediaTypeSchema.default("collection_proof"),
});

export const presignResponseSchema = z.object({
  uploadUrl: z.string().url(),
  objectUrl: z.string().url(),
  /** Echoed back to confirm; the server keys the pending upload on it. */
  uploadId: z.string(),
});

export const confirmMediaSchema = z.object({
  uploadId: z.string(),
  objectUrl: z.string().url(),
  type: mediaTypeSchema.default("collection_proof"),
  geo: latLngSchema.optional(),
  capturedAt: z.coerce.date().optional(),
});

export const driverIssueSchema = z.object({
  kind: driverIssueKindSchema,
  note: z.string().trim().max(500).optional(),
});

/** Live positions for the ward dashboard (FR-DASH-01). */
export const livePositionSchema = z.object({
  tripId: uuidSchema,
  autoId: uuidSchema,
  registrationNumber: z.string(),
  routeId: uuidSchema,
  routeName: z.string(),
  passNumber: z.number().int(),
  lat: z.number(),
  lng: z.number(),
  heading: z.number().nullable(),
  at: z.coerce.date(),
  /** No ping for over 3 minutes: the phone has stopped reporting (FR-DRV-05). */
  trackingDropped: z.boolean(),
});
export type LivePosition = z.infer<typeof livePositionSchema>;
