import { z } from "zod";

/**
 * Domain enums. These mirror the Postgres enum types created in
 * apps/api/migrations — changing one without the other is a defect.
 */

export const OPERATOR_TYPES = ["bbmp", "private"] as const;
export const operatorTypeSchema = z.enum(OPERATOR_TYPES);
export type OperatorType = z.infer<typeof operatorTypeSchema>;

export const LIFECYCLE_STATUSES = ["active", "retired"] as const;
export const lifecycleStatusSchema = z.enum(LIFECYCLE_STATUSES);
export type LifecycleStatus = z.infer<typeof lifecycleStatusSchema>;

export const USER_ROLES = ["resident", "driver", "ward_admin", "super_admin"] as const;
export const userRoleSchema = z.enum(USER_ROLES);
export type UserRole = z.infer<typeof userRoleSchema>;

export const AUTH_PROVIDERS = ["password", "google"] as const;
export const authProviderSchema = z.enum(AUTH_PROVIDERS);
export type AuthProvider = z.infer<typeof authProviderSchema>;

export const USER_STATUSES = ["active", "blocked"] as const;
export const userStatusSchema = z.enum(USER_STATUSES);
export type UserStatus = z.infer<typeof userStatusSchema>;

export const LOCALES = ["en", "kn"] as const;
export const localeSchema = z.enum(LOCALES);
export type Locale = z.infer<typeof localeSchema>;

export const AUTO_STATUSES = ["available", "assigned", "maintenance", "retired"] as const;
export const autoStatusSchema = z.enum(AUTO_STATUSES);
export type AutoStatus = z.infer<typeof autoStatusSchema>;

export const DRIVER_STATUSES = ["active", "inactive"] as const;
export const driverStatusSchema = z.enum(DRIVER_STATUSES);
export type DriverStatus = z.infer<typeof driverStatusSchema>;

export const MAPPING_STATUSES = ["auto", "admin_corrected", "pending_review"] as const;
export const mappingStatusSchema = z.enum(MAPPING_STATUSES);
export type MappingStatus = z.infer<typeof mappingStatusSchema>;

export const TRIP_STATUSES = ["active", "completed", "aborted"] as const;
export const tripStatusSchema = z.enum(TRIP_STATUSES);
export type TripStatus = z.infer<typeof tripStatusSchema>;

export const TRIP_END_REASONS = ["driver", "auto_idle", "admin"] as const;
export const tripEndReasonSchema = z.enum(TRIP_END_REASONS);
export type TripEndReason = z.infer<typeof tripEndReasonSchema>;

export const PASS_STATUSES = ["pending", "active", "completed", "aborted", "skipped"] as const;
export const passStatusSchema = z.enum(PASS_STATUSES);
export type PassStatus = z.infer<typeof passStatusSchema>;

export const WASTE_TYPES = ["wet", "dry", "sanitary", "hazardous", "ewaste"] as const;
export const wasteTypeSchema = z.enum(WASTE_TYPES);
export type WasteType = z.infer<typeof wasteTypeSchema>;

export const MEDIA_TYPES = ["collection_proof", "issue", "other"] as const;
export const mediaTypeSchema = z.enum(MEDIA_TYPES);
export type MediaType = z.infer<typeof mediaTypeSchema>;

export const COMPLAINT_CATEGORIES = [
  "missed_pickup",
  "late",
  "behavior",
  "segregation",
  "other",
] as const;
export const complaintCategorySchema = z.enum(COMPLAINT_CATEGORIES);
export type ComplaintCategory = z.infer<typeof complaintCategorySchema>;

export const COMPLAINT_STATUSES = ["open", "in_review", "resolved", "rejected"] as const;
export const complaintStatusSchema = z.enum(COMPLAINT_STATUSES);
export type ComplaintStatus = z.infer<typeof complaintStatusSchema>;

export const NOTIFICATION_KINDS = [
  "proximity",
  "arrival",
  "schedule_change",
  "complaint_status",
  "driver_issue",
] as const;
export const notificationKindSchema = z.enum(NOTIFICATION_KINDS);
export type NotificationKind = z.infer<typeof notificationKindSchema>;

export const DRIVER_ISSUE_KINDS = ["breakdown", "road_blocked", "other"] as const;
export const driverIssueKindSchema = z.enum(DRIVER_ISSUE_KINDS);
export type DriverIssueKind = z.infer<typeof driverIssueKindSchema>;
