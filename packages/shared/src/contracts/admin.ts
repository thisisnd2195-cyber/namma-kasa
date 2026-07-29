import { z } from "zod";
import {
  autoStatusSchema,
  complaintCategorySchema,
  driverStatusSchema,
  lifecycleStatusSchema,
  operatorTypeSchema,
  wasteTypeSchema,
} from "./enums";
import {
  geoJsonAreaSchema,
  latLngSchema,
  phoneSchema,
  registrationNumberSchema,
  timeOfDaySchema,
  uuidSchema,
  weekdaySchema,
} from "./common";

// ------------------------------------------------------------------ operators

/**
 * How long an operator has to resolve a complaint, in hours (FR-CMP-03).
 *
 * Kept as a plain number of hours rather than a calendar rule because BBMP and
 * private contractors quote their commitments that way, and because a due
 * timestamp is what the queue actually needs to sort and flag by. The real
 * values are a per-operator policy decision the spec leaves open (§12), so the
 * default below is a working figure, not a mandated one.
 */
export const DEFAULT_COMPLAINT_SLA_HOURS = 24;

export const operatorConfigSchema = z.object({
  /** Overrides by complaint category; anything absent uses the default. */
  complaintSlaHours: z
    .record(complaintCategorySchema, z.number().int().min(1).max(720))
    .default({}),
  defaultComplaintSlaHours: z
    .number()
    .int()
    .min(1)
    .max(720)
    .default(DEFAULT_COMPLAINT_SLA_HOURS),
  /** Escalate to the operator once a complaint is this far past due. */
  escalateAfterHours: z.number().int().min(1).max(720).default(24),
  /** FR-CMP-04: BBMP wards only, and off until an operator turns it on. */
  sahaayaSyncEnabled: z.boolean().default(false),
});
export type OperatorConfig = z.infer<typeof operatorConfigSchema>;

/** Hours allowed for this category, falling back to the operator default. */
export function complaintSlaHours(
  config: OperatorConfig,
  category: z.infer<typeof complaintCategorySchema>,
): number {
  return config.complaintSlaHours[category] ?? config.defaultComplaintSlaHours;
}

export const createOperatorSchema = z.object({
  name: z.string().trim().min(1).max(200),
  type: operatorTypeSchema,
  config: operatorConfigSchema.default({}),
});

export const updateOperatorSchema = createOperatorSchema
  .partial()
  .extend({ status: lifecycleStatusSchema.optional() });

export const operatorSchema = z.object({
  id: uuidSchema,
  name: z.string(),
  type: operatorTypeSchema,
  config: operatorConfigSchema,
  status: lifecycleStatusSchema,
  wardCount: z.number().int().optional(),
});
export type Operator = z.infer<typeof operatorSchema>;

// ---------------------------------------------------------------------- wards

export const createWardSchema = z.object({
  operatorId: uuidSchema,
  name: z.string().trim().min(1).max(200),
  wardCode: z.string().trim().min(1).max(40),
  cityId: z.string().trim().default("blr"),
  boundary: geoJsonAreaSchema,
});

export const updateWardSchema = createWardSchema
  .partial()
  .omit({ operatorId: true })
  .extend({ status: lifecycleStatusSchema.optional() });

export const wardSchema = z.object({
  id: uuidSchema,
  operatorId: uuidSchema,
  cityId: z.string(),
  name: z.string(),
  wardCode: z.string(),
  boundary: geoJsonAreaSchema,
  wardAdminUserId: uuidSchema.nullable(),
  status: lifecycleStatusSchema,
});
export type Ward = z.infer<typeof wardSchema>;

/**
 * A boundary edit can strand households that were mapped under the old shape,
 * so the API reports the blast radius before committing (Clarifications CHK017).
 */
export const wardEditImpactSchema = z.object({
  affectedHouseholds: z.number().int(),
  routesOutsideNewBoundary: z.number().int(),
});

export const importWardsSchema = z.object({
  /** GeoJSON FeatureCollection; each feature needs ward_code and name. */
  featureCollection: z.object({
    type: z.literal("FeatureCollection"),
    features: z
      .array(
        z.object({
          type: z.literal("Feature"),
          properties: z.record(z.unknown()),
          geometry: geoJsonAreaSchema,
        }),
      )
      .min(1),
  }),
  operatorId: uuidSchema,
  cityId: z.string().trim().default("blr"),
});

/** Per-feature accept/reject, never all-or-nothing silence (CHK018). */
export const importReportSchema = z.object({
  accepted: z.array(z.object({ wardCode: z.string(), id: uuidSchema })),
  rejected: z.array(z.object({ wardCode: z.string(), reason: z.string() })),
});
export type ImportReport = z.infer<typeof importReportSchema>;

export const createWardAdminSchema = z.object({
  wardId: uuidSchema,
  phone: phoneSchema,
  password: z.string().min(8),
});

// --------------------------------------------------------------------- routes

/** Weekday (1–7) → waste types collected that day (FR-ROUTE-03). */
export const wasteScheduleSchema = z.record(
  z.string().regex(/^[1-7]$/),
  z.array(wasteTypeSchema).min(1),
);

export const createRouteSchema = z.object({
  wardId: uuidSchema,
  name: z.string().trim().min(1).max(200),
  routeCode: z.string().trim().min(1).max(40),
  serviceableArea: geoJsonAreaSchema,
  collectionDays: z.array(weekdaySchema).min(1),
  windowStart: timeOfDaySchema,
  windowEnd: timeOfDaySchema,
  passesPerDay: z.number().int().min(1).default(1),
  wasteTypeSchedule: wasteScheduleSchema.default({}),
});

export const updateRouteSchema = createRouteSchema.partial().omit({ wardId: true });

/** A driven trail adopted as the route's path (FR-ROUTE-04). */
export const recordedPathSchema = z.object({
  /** GeoJSON LineString; the shape the auto actually drove. */
  geometry: z.object({
    type: z.literal("LineString"),
    coordinates: z.array(z.tuple([z.number(), z.number()])),
  }),
  tripId: uuidSchema.nullable(),
  recordedAt: z.coerce.date(),
});
export type RecordedPath = z.infer<typeof recordedPathSchema>;

export const routeSchema = z.object({
  id: uuidSchema,
  wardId: uuidSchema,
  name: z.string(),
  routeCode: z.string(),
  serviceableArea: geoJsonAreaSchema,
  collectionDays: z.array(weekdaySchema),
  windowStart: z.string(),
  windowEnd: z.string(),
  passesPerDay: z.number().int(),
  wasteTypeSchedule: wasteScheduleSchema,
  /** Null until an admin adopts a completed trip's trail (FR-ROUTE-04). */
  recordedPath: recordedPathSchema.nullable(),
});
export type Route = z.infer<typeof routeSchema>;

// ---------------------------------------------------------------------- fleet

export const createAutoSchema = z.object({
  registrationNumber: registrationNumberSchema,
  capacityKg: z.number().int().positive().optional(),
  wardId: uuidSchema,
  photos: z.array(z.string().url()).default([]),
});

export const updateAutoSchema = z.object({
  capacityKg: z.number().int().positive().optional(),
  photos: z.array(z.string().url()).optional(),
  status: autoStatusSchema.optional(),
});

export const autoSchema = z.object({
  id: uuidSchema,
  registrationNumber: z.string(),
  capacityKg: z.number().int().nullable(),
  wardId: uuidSchema,
  photos: z.array(z.string()),
  status: autoStatusSchema,
});
export type Auto = z.infer<typeof autoSchema>;

export const createDriverSchema = z.object({
  wardId: uuidSchema,
  fullName: z.string().trim().min(1).max(200),
  phone: phoneSchema,
  licenseNumber: z.string().trim().min(1).max(40),
  photoUrl: z.string().url().optional(),
  emergencyContact: phoneSchema.optional(),
});

export const updateDriverSchema = createDriverSchema
  .partial()
  .omit({ wardId: true, phone: true })
  .extend({ status: driverStatusSchema.optional() });

/** Driver identity is admin-only; resident payloads never carry these fields. */
export const driverSchema = z.object({
  id: uuidSchema,
  wardId: uuidSchema,
  fullName: z.string(),
  phone: z.string(),
  licenseNumber: z.string(),
  photoUrl: z.string().nullable(),
  emergencyContact: z.string().nullable(),
  status: driverStatusSchema,
  hasAccount: z.boolean(),
});
export type Driver = z.infer<typeof driverSchema>;

/** Reassignment closes the open row and opens a new one; history is never rewritten. */
export const assignRouteToAutoSchema = z.object({
  routeId: uuidSchema,
  effectiveFrom: z.coerce.date().optional(),
});

export const assignAutoToDriverSchema = z.object({
  autoId: uuidSchema,
  effectiveFrom: z.coerce.date().optional(),
});

export const assignmentBaseSchema = z.object({
  effectiveFrom: z.coerce.date().optional(),
});

export const assignmentSchema = z.object({
  id: uuidSchema,
  effectiveFrom: z.coerce.date(),
  effectiveTo: z.coerce.date().nullable(),
});

export const autoRouteAssignmentSchema = assignmentSchema.extend({
  autoId: uuidSchema,
  routeId: uuidSchema,
  routeName: z.string().optional(),
});

export const driverAutoAssignmentSchema = assignmentSchema.extend({
  driverId: uuidSchema,
  autoId: uuidSchema,
  driverName: z.string().optional(),
  registrationNumber: z.string().optional(),
});

// ----------------------------------------------------------- household review

export const reviewQueueItemSchema = z.object({
  id: uuidSchema,
  fullName: z.string(),
  addressLine: z.string(),
  landmark: z.string().nullable(),
  pin: latLngSchema,
  wardId: uuidSchema.nullable(),
  createdAt: z.coerce.date(),
  /** Flagged once it has waited more than 48 h (Clarifications CHK020). */
  aging: z.boolean(),
});

export type ReviewQueueItem = z.infer<typeof reviewQueueItemSchema>;
export type WardEditImpact = z.infer<typeof wardEditImpactSchema>;
export type AutoRouteAssignment = z.infer<typeof autoRouteAssignmentSchema>;
export type DriverAutoAssignment = z.infer<typeof driverAutoAssignmentSchema>;

export const assignHouseholdRouteSchema = z.object({ routeId: uuidSchema });

// --------------------------------------------------------------- dashboards

/** Super Admin city rollup (FR-DASH-02). */
export const cityRollupSchema = z.object({
  serviceDate: z.string(),
  trips: z.object({
    total: z.number().int(),
    active: z.number().int(),
    completed: z.number().int(),
  }),
  routeCoverage: z.object({
    scheduled: z.number().int(),
    served: z.number().int(),
    percent: z.number().int(),
  }),
  complaints: z.object({
    last30Days: z.number().int(),
    open: z.number().int(),
    slaBreached: z.number().int(),
  }),
  openDriverIssues: z.number().int(),
});
export type CityRollup = z.infer<typeof cityRollupSchema>;

/** A household whose window closed today with no auto within 75 m (FR-DASH-03). */
export const missedPickupSchema = z.object({
  householdId: uuidSchema,
  fullName: z.string(),
  addressLine: z.string(),
  routeId: uuidSchema,
  routeName: z.string(),
  wardId: uuidSchema,
  windowEnd: z.string(),
  serviceDate: z.string(),
});
export type MissedPickup = z.infer<typeof missedPickupSchema>;

/** Adopting a driven trip's trail as the route's path (FR-ROUTE-04). */
export const recordRoutePathSchema = z.object({ tripId: uuidSchema });

/**
 * Completed trips an admin can adopt a path from. Carries the position count
 * because a trip with two pings makes a straight line, not a route.
 */
export const recordableTripSchema = z.object({
  id: uuidSchema,
  serviceDate: z.string(),
  passNumber: z.number().int(),
  registrationNumber: z.string(),
  positionCount: z.number().int(),
  endedAt: z.coerce.date().nullable(),
});
export type RecordableTrip = z.infer<typeof recordableTripSchema>;
