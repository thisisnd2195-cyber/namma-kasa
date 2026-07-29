import { z } from "zod";
import { paginationQuerySchema, uuidSchema } from "./common";
import { complaintCategorySchema, complaintStatusSchema } from "./enums";

export const createComplaintSchema = z.object({
  category: complaintCategorySchema,
  description: z.string().trim().max(2000).optional(),
  /** Three is enough to show a problem; more is a moderation burden. */
  mediaUrls: z.array(z.string().url()).max(3).default([]),
});

export const complaintEventSchema = z.object({
  fromStatus: complaintStatusSchema.nullable(),
  toStatus: complaintStatusSchema,
  note: z.string().nullable(),
  at: z.coerce.date(),
});

export const complaintSchema = z.object({
  id: uuidSchema,
  category: complaintCategorySchema,
  description: z.string().nullable(),
  mediaUrls: z.array(z.string()),
  status: complaintStatusSchema,
  routeId: uuidSchema.nullable(),
  wardId: uuidSchema,
  slaDueAt: z.coerce.date().nullable(),
  resolutionNote: z.string().nullable(),
  createdAt: z.coerce.date(),
  history: z.array(complaintEventSchema),
});
export type Complaint = z.infer<typeof complaintSchema>;

/**
 * Admin view. Carries the collection evidence alongside the complaint, because
 * a missed-pickup dispute is settled by whether the auto actually came, and
 * making the admin go and look it up separately is how that gets skipped.
 */
export const adminComplaintSchema = complaintSchema.extend({
  household: z.object({
    id: uuidSchema,
    fullName: z.string(),
    addressLine: z.string(),
  }),
  evidence: z.object({
    servedOnComplaintDay: z.boolean(),
    lastCollectedAt: z.coerce.date().nullable(),
  }),
});

export type AdminComplaint = z.infer<typeof adminComplaintSchema>;

export const updateComplaintSchema = z.object({
  status: complaintStatusSchema,
  resolutionNote: z.string().trim().max(2000).optional(),
});

export const complaintQuerySchema = paginationQuerySchema.extend({
  status: complaintStatusSchema.optional(),
});

export const createRatingSchema = z.object({
  stars: z.number().int().min(1).max(5),
  comment: z.string().trim().max(1000).optional(),
});

export const ratingSchema = z.object({
  id: uuidSchema,
  stars: z.number().int(),
  comment: z.string().nullable(),
  collectionDate: z.string(),
  createdAt: z.coerce.date(),
});

/** Complaints are capped per household per day to keep the queue usable. */
export const COMPLAINT_DAILY_LIMIT = 5;
