import { z } from "zod";

export const REPORT_CATEGORIES = [
  "illegal_dumping",
  "overflowing_bin",
  "waste_burning",
  "missed_pickup",
  "dead_animal",
  "other",
] as const;

export const REPORT_STATUSES = ["open", "acknowledged", "resolved", "verified"] as const;

export const reportCategorySchema = z.enum(REPORT_CATEGORIES);
export type ReportCategory = z.infer<typeof reportCategorySchema>;

export const reportStatusSchema = z.enum(REPORT_STATUSES);
export type ReportStatus = z.infer<typeof reportStatusSchema>;

// Rough bounding box around Greater Bengaluru; keeps obviously bogus
// coordinates out before the DB does exact ward point-in-polygon.
export const BENGALURU_BOUNDS = {
  minLat: 12.7,
  maxLat: 13.25,
  minLng: 77.3,
  maxLng: 77.9,
} as const;

export const locationSchema = z.object({
  lat: z
    .number()
    .min(BENGALURU_BOUNDS.minLat, "Location is outside Bengaluru")
    .max(BENGALURU_BOUNDS.maxLat, "Location is outside Bengaluru"),
  lng: z
    .number()
    .min(BENGALURU_BOUNDS.minLng, "Location is outside Bengaluru")
    .max(BENGALURU_BOUNDS.maxLng, "Location is outside Bengaluru"),
});
export type Location = z.infer<typeof locationSchema>;

export const newReportSchema = z.object({
  category: reportCategorySchema,
  description: z.string().trim().max(1000).optional(),
  location: locationSchema,
});
export type NewReport = z.infer<typeof newReportSchema>;

export const reportSchema = newReportSchema.extend({
  id: z.string().uuid(),
  reporterId: z.string().uuid().nullable(),
  wardId: z.number().int().nullable(),
  status: reportStatusSchema,
  createdAt: z.coerce.date(),
  resolvedAt: z.coerce.date().nullable(),
  resolutionNote: z.string().nullable(),
});
export type Report = z.infer<typeof reportSchema>;

export const reportPhotoSchema = z.object({
  id: z.string().uuid(),
  reportId: z.string().uuid(),
  url: z.string().url(),
  kind: z.enum(["evidence", "resolution"]),
});
export type ReportPhoto = z.infer<typeof reportPhotoSchema>;

export const wardSchema = z.object({
  id: z.number().int(),
  wardNumber: z.number().int(),
  nameEn: z.string(),
  nameKn: z.string(),
  zone: z.string(),
});
export type Ward = z.infer<typeof wardSchema>;

export const reportEventSchema = z.object({
  id: z.string().uuid(),
  reportId: z.string().uuid(),
  actorId: z.string().uuid().nullable(),
  fromStatus: reportStatusSchema.nullable(),
  toStatus: reportStatusSchema,
  at: z.coerce.date(),
});
export type ReportEvent = z.infer<typeof reportEventSchema>;
