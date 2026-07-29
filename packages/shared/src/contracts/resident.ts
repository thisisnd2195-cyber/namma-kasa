import { z } from "zod";
import { bengaluruLatLngSchema, latLngSchema, timeOfDaySchema, uuidSchema } from "./common";
import { localeSchema, mappingStatusSchema, wasteTypeSchema } from "./enums";

/** Distance at which a passing auto counts as having served the house (CHK002). */
export const COLLECTION_PROXIMITY_M = 75;

export const householdSchema = z.object({
  id: uuidSchema,
  fullName: z.string(),
  addressLine: z.string(),
  landmark: z.string().nullable(),
  pin: latLngSchema,
  wardId: uuidSchema.nullable(),
  routeId: uuidSchema.nullable(),
  mappingStatus: mappingStatusSchema,
  notificationRadiusM: z.number().int(),
});
export type Household = z.infer<typeof householdSchema>;

export const updateHouseholdSchema = z.object({
  fullName: z.string().trim().min(1).max(120).optional(),
  addressLine: z.string().trim().min(1).max(300).optional(),
  landmark: z.string().trim().max(200).nullish(),
  /** Moving the pin re-runs ward and route derivation (FR-RES-04). */
  pin: bengaluruLatLngSchema.optional(),
});

export const residentSettingsSchema = z.object({
  notificationRadiusM: z.number().int().min(100).max(1000).optional(),
  locale: localeSchema.optional(),
});

/** One auto on the resident's route. Never carries driver identity (FR-RES-07). */
export const servingAutoSchema = z.object({
  tripId: uuidSchema,
  registrationNumber: z.string(),
  passNumber: z.number().int(),
  lat: z.number(),
  lng: z.number(),
  heading: z.number().nullable(),
  at: z.coerce.date(),
  distanceM: z.number().int(),
});

export const residentHomeSchema = z.object({
  household: householdSchema,
  route: z
    .object({
      id: uuidSchema,
      name: z.string(),
      windowStart: timeOfDaySchema,
      windowEnd: timeOfDaySchema,
      passesPerDay: z.number().int(),
      todayWasteTypes: z.array(wasteTypeSchema),
      isCollectionDay: z.boolean(),
    })
    .nullable(),
  /** All autos running the resident's route right now (FR-RES-01 as clarified). */
  servingAutos: z.array(servingAutoSchema),
  currentPass: z.number().int().nullable(),
  lastCollectedAt: z.coerce.date().nullable(),
  /** Set once today's collection has happened, so the app can offer a rating. */
  canRateToday: z.boolean(),
});
export type ResidentHome = z.infer<typeof residentHomeSchema>;

/** Frames pushed over the resident's WebSocket (contracts/realtime.md §2). */
export const liveFrameSchema = z.discriminatedUnion("type", [
  z.object({
    type: z.literal("position"),
    tripId: uuidSchema,
    registrationNumber: z.string(),
    passNumber: z.number().int(),
    lat: z.number(),
    lng: z.number(),
    heading: z.number().nullable(),
    at: z.coerce.date(),
  }),
  z.object({
    type: z.literal("trip_status"),
    tripId: uuidSchema,
    status: z.enum(["completed", "aborted"]),
    passNumber: z.number().int(),
  }),
  /** Sockets outlive the 15-minute access token; this asks for a fresh one. */
  z.object({ type: z.literal("reauth") }),
]);
export type LiveFrame = z.infer<typeof liveFrameSchema>;
