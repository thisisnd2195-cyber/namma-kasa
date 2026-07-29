import { z } from "zod";

export const uuidSchema = z.string().uuid();
export type Uuid = z.infer<typeof uuidSchema>;

/** E.164 without the leading +, as stored: country code + subscriber number. */
export const phoneSchema = z
  .string()
  .regex(/^[1-9]\d{7,14}$/, "Phone must be digits in international format");

/** Indian vehicle registration, e.g. KA01AB1234 (FR-FLEET-01). */
export const registrationNumberSchema = z
  .string()
  .trim()
  .toUpperCase()
  .regex(/^[A-Z]{2}\d{1,2}[A-Z]{1,3}\d{4}$/, "Invalid Indian registration number");

/**
 * Coarse Greater Bengaluru envelope. Cheap client-side guard only — the
 * authoritative check is ward point-in-polygon in the database.
 */
export const BENGALURU_BOUNDS = {
  minLat: 12.7,
  maxLat: 13.25,
  minLng: 77.3,
  maxLng: 77.9,
} as const;

export const latLngSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});
export type LatLng = z.infer<typeof latLngSchema>;

export const bengaluruLatLngSchema = z.object({
  lat: z.number().min(BENGALURU_BOUNDS.minLat).max(BENGALURU_BOUNDS.maxLat),
  lng: z.number().min(BENGALURU_BOUNDS.minLng).max(BENGALURU_BOUNDS.maxLng),
});

/** GeoJSON subset used for boundary import/export and area editing. */
export const geoJsonPolygonSchema = z.object({
  type: z.literal("Polygon"),
  coordinates: z.array(z.array(z.tuple([z.number(), z.number()]))).min(1),
});

export const geoJsonMultiPolygonSchema = z.object({
  type: z.literal("MultiPolygon"),
  coordinates: z.array(z.array(z.array(z.tuple([z.number(), z.number()])))).min(1),
});

export const geoJsonAreaSchema = z.union([geoJsonPolygonSchema, geoJsonMultiPolygonSchema]);
export type GeoJsonArea = z.infer<typeof geoJsonAreaSchema>;

/** ISO weekdays, Monday = 1 (routes.collection_days). */
export const weekdaySchema = z.number().int().min(1).max(7);

/** HH:MM in IST — all scheduling is Asia/Kolkata (Clarifications CHK030). */
export const timeOfDaySchema = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, "Expected HH:MM");

export const paginationQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

export function paginatedSchema<T extends z.ZodTypeAny>(item: T) {
  return z.object({
    items: z.array(item),
    nextCursor: z.string().nullable(),
  });
}

/** RFC 9457 problem+json — the single error shape for every endpoint. */
export const problemSchema = z.object({
  type: z.string().default("about:blank"),
  title: z.string(),
  status: z.number().int(),
  detail: z.string().optional(),
  instance: z.string().optional(),
});
export type Problem = z.infer<typeof problemSchema>;
