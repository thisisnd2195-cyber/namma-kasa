import type { ColumnType, Generated } from "kysely";
import type {
  AuthProvider,
  AutoStatus,
  ComplaintCategory,
  ComplaintStatus,
  DriverIssueKind,
  DriverStatus,
  LifecycleStatus,
  Locale,
  MappingStatus,
  MediaType,
  NotificationKind,
  OperatorType,
  PassStatus,
  TripEndReason,
  TripStatus,
  UserRole,
  UserStatus,
} from "@namma-kasa/shared";

type Timestamp = ColumnType<Date, Date | string | undefined, Date | string>;
/** Nullable timestamp that stays assignable when closing an open row. */
type NullableTimestamp = ColumnType<Date | null, Date | string | null, Date | string | null>;
/** PostGIS columns are read as GeoJSON text and written via ST_* expressions. */
type Geometry = ColumnType<string, string, string>;

export interface OperatorsTable {
  id: Generated<string>;
  name: string;
  type: OperatorType;
  config: Generated<Record<string, unknown>>;
  status: Generated<LifecycleStatus>;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface UsersTable {
  id: Generated<string>;
  phone: string;
  email: string | null;
  password_hash: string | null;
  auth_provider: AuthProvider;
  role: UserRole;
  locale: Generated<Locale>;
  status: Generated<UserStatus>;
  consented_at: Timestamp | null;
  deletion_requested_at: Timestamp | null;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface RefreshTokensTable {
  id: Generated<string>;
  user_id: string;
  token_hash: string;
  device_id: string | null;
  expires_at: Timestamp;
  rotated_from: string | null;
  revoked_at: Timestamp | null;
  created_at: Timestamp;
}

export interface DeviceTokensTable {
  user_id: string;
  fcm_token: string;
  platform: Generated<string>;
  updated_at: Timestamp;
}

export interface WardsTable {
  id: Generated<string>;
  operator_id: string;
  city_id: Generated<string>;
  name: string;
  ward_code: string;
  boundary: Geometry;
  ward_admin_user_id: string | null;
  status: Generated<LifecycleStatus>;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface RoutesTable {
  id: Generated<string>;
  ward_id: string;
  name: string;
  route_code: string;
  serviceable_area: Geometry;
  /** Learned from a completed trip's trail rather than drawn (FR-ROUTE-04). */
  recorded_path: Geometry | null;
  recorded_path_trip_id: string | null;
  recorded_path_at: Timestamp | null;
  collection_days: number[];
  window_start: string;
  window_end: string;
  passes_per_day: Generated<number>;
  waste_type_schedule: Generated<Record<string, string[]>>;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface AutosTable {
  id: Generated<string>;
  registration_number: string;
  capacity_kg: number | null;
  ward_id: string;
  photos: Generated<string[]>;
  status: Generated<AutoStatus>;
  onboarded_by: string | null;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface DriversTable {
  id: Generated<string>;
  user_id: string | null;
  ward_id: string;
  full_name: string;
  phone: string;
  license_number: string;
  photo_url: string | null;
  emergency_contact: string | null;
  status: Generated<DriverStatus>;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface AutoRouteAssignmentsTable {
  id: Generated<string>;
  auto_id: string;
  route_id: string;
  assigned_by: string | null;
  effective_from: Timestamp;
  effective_to: NullableTimestamp;
}

export interface DriverAutoAssignmentsTable {
  id: Generated<string>;
  driver_id: string;
  auto_id: string;
  assigned_by: string | null;
  effective_from: Timestamp;
  effective_to: NullableTimestamp;
}

export interface HouseholdsTable {
  id: Generated<string>;
  user_id: string;
  full_name: string;
  address_line: string;
  landmark: string | null;
  house_geo: Geometry;
  ward_id: string | null;
  route_id: string | null;
  mapping_status: Generated<MappingStatus>;
  notification_radius_m: Generated<number>;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface TripsTable {
  id: Generated<string>;
  auto_id: string;
  driver_id: string;
  route_id: string;
  pass_number: number;
  service_date: ColumnType<string, string, string>;
  started_at: Timestamp;
  ended_at: Timestamp | null;
  status: Generated<TripStatus>;
  end_reason: TripEndReason | null;
  distance_covered_m: number | null;
  created_at: Timestamp;
}

export interface RoutePassDaysTable {
  route_id: string;
  service_date: ColumnType<string, string, string>;
  pass_number: number;
  status: Generated<PassStatus>;
  trip_id: string | null;
  updated_at: Timestamp;
}

export interface LocationPingsTable {
  trip_id: string;
  auto_id: string;
  lat: number;
  lng: number;
  speed: number | null;
  heading: number | null;
  accuracy_m: number | null;
  recorded_at: Timestamp;
  received_at: Timestamp;
}

export interface HouseholdCollectionsTable {
  id: Generated<string>;
  household_id: string;
  trip_id: string;
  route_id: string;
  pass_number: number;
  detected_at: Timestamp;
}

export interface MediaUploadsTable {
  id: Generated<string>;
  trip_id: string | null;
  driver_id: string | null;
  type: Generated<MediaType>;
  object_url: string;
  geo: Geometry | null;
  captured_at: Timestamp;
  expires_at: Timestamp;
}

export interface ComplaintsTable {
  id: Generated<string>;
  household_id: string;
  route_id: string | null;
  ward_id: string;
  category: ComplaintCategory;
  description: string | null;
  media_urls: Generated<string[]>;
  status: Generated<ComplaintStatus>;
  assigned_to: string | null;
  sla_due_at: Timestamp | null;
  resolution_note: string | null;
  created_at: Timestamp;
  updated_at: Timestamp;
}

export interface ComplaintEventsTable {
  id: Generated<string>;
  complaint_id: string;
  actor_id: string | null;
  from_status: ComplaintStatus | null;
  to_status: ComplaintStatus;
  note: string | null;
  at: Timestamp;
}

export interface RatingsTable {
  id: Generated<string>;
  household_id: string;
  route_id: string | null;
  trip_id: string | null;
  stars: number;
  comment: string | null;
  collection_date: ColumnType<string, string, string>;
  created_at: Timestamp;
}

export interface NotificationsTable {
  id: Generated<string>;
  user_id: string;
  kind: NotificationKind;
  payload: Record<string, unknown>;
  dedup_key: string | null;
  created_at: Timestamp;
  sent_at: Timestamp | null;
}

export interface AuditLogTable {
  id: Generated<string>;
  actor_id: string | null;
  entity_type: string;
  entity_id: string | null;
  action: string;
  before: Record<string, unknown> | null;
  after: Record<string, unknown> | null;
  at: Timestamp;
}

export interface DriverIssuesTable {
  id: Generated<string>;
  trip_id: string | null;
  driver_id: string;
  route_id: string | null;
  ward_id: string;
  kind: DriverIssueKind;
  note: string | null;
  geo: Geometry | null;
  acknowledged_at: Timestamp | null;
  created_at: Timestamp;
}

export interface Database {
  operators: OperatorsTable;
  users: UsersTable;
  refresh_tokens: RefreshTokensTable;
  device_tokens: DeviceTokensTable;
  wards: WardsTable;
  routes: RoutesTable;
  autos: AutosTable;
  drivers: DriversTable;
  auto_route_assignments: AutoRouteAssignmentsTable;
  driver_auto_assignments: DriverAutoAssignmentsTable;
  households: HouseholdsTable;
  trips: TripsTable;
  route_pass_days: RoutePassDaysTable;
  location_pings: LocationPingsTable;
  household_collections: HouseholdCollectionsTable;
  media_uploads: MediaUploadsTable;
  complaints: ComplaintsTable;
  complaint_events: ComplaintEventsTable;
  ratings: RatingsTable;
  driver_issues: DriverIssuesTable;
  notifications: NotificationsTable;
  audit_log: AuditLogTable;
}
