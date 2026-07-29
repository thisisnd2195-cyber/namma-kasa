import { z } from "zod";
import {
  autoStatusSchema,
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

export const createOperatorSchema = z.object({
  name: z.string().trim().min(1).max(200),
  type: operatorTypeSchema,
  config: z.record(z.unknown()).default({}),
});

export const updateOperatorSchema = createOperatorSchema
  .partial()
  .extend({ status: lifecycleStatusSchema.optional() });

export const operatorSchema = z.object({
  id: uuidSchema,
  name: z.string(),
  type: operatorTypeSchema,
  config: z.record(z.unknown()),
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

export const assignHouseholdRouteSchema = z.object({ routeId: uuidSchema });
