# Data Model: City Waste Collection Tracking Platform

**Feature**: 001-waste-collection-tracking · **Date**: 2026-07-29
**Store**: PostgreSQL 16 + PostGIS + TimescaleDB, SRID 4326. All ids `uuid` (gen_random_uuid)
unless noted. All tables carry `created_at timestamptz default now()`; mutable tables carry
`updated_at`. Zod mirrors of every API-visible shape live in `packages/shared` (Principle IV).

## Entities

### operators
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| name | text | unique, non-empty |
| type | enum `bbmp` \| `private` | |
| config | jsonb | complaint SLA/escalation (deferred policy, spec §12) |
| status | enum `active` \| `retired` | retired operators block new ward attachment |

### users
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| phone | text unique | E.164; verified before credential setup (FR-AUTH-02/03) |
| email | text nullable | set when auth_provider = google |
| password_hash | text nullable | argon2id; exactly one of password_hash / google linkage required |
| auth_provider | enum `password` \| `google` | |
| role | enum `resident` \| `driver` \| `ward_admin` \| `super_admin` | |
| locale | enum `en` \| `kn` | default `en` |
| status | enum `active` \| `blocked` | |

Related: `refresh_tokens(id, user_id FK, token_hash, device_id, expires_at, rotated_from
nullable, revoked_at nullable)` — rotation chain, revocable (FR-AUTH-06).
`otp_codes` live in Redis only (5-min TTL, attempt/rate counters) — never in Postgres.
`device_tokens(user_id FK, fcm_token, platform, updated_at)` for push.

### wards
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| operator_id | FK operators | exactly one operator per ward (FR-WARD-01) |
| city_id | text | `blr` for launch; multi-city ready |
| name / ward_code | text | ward_code unique per city |
| boundary | geometry(MultiPolygon, 4326) | GiST index; INSERT/UPDATE rejected if `ST_Overlaps` any sibling ward (FR-WARD-05) |
| ward_admin_user_id | FK users nullable | role must be ward_admin; one ward per admin (FR-WARD-06) |
| status | enum `active` \| `retired` | |

### routes
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| ward_id | FK wards | |
| name / route_code | text | route_code unique per ward |
| serviceable_area | geometry(MultiPolygon, 4326) | must satisfy `ST_Within(area, ward.boundary)` (FR-ROUTE-01) |
| path | geometry(LineString, 4326) nullable | v1.1: auto-recorded from a trip trail (FR-ROUTE-04) |
| collection_days | int[] | ISO weekday numbers 1–7, non-empty |
| window_start / window_end | time | start < end |
| passes_per_day | int | ≥ 1, default 1 (FR-ROUTE-02) |
| waste_type_schedule | jsonb | map weekday → waste types (`wet`,`dry`,`sanitary`,`hazardous`,`ewaste`) (FR-ROUTE-03) |

### autos
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| registration_number | text unique | Indian format regex (e.g., `KA01AB1234`) (FR-FLEET-01) |
| capacity_kg | int nullable | > 0 |
| ward_id | FK wards | auto's ward must equal its route's ward (enforced on assignment) |
| photos | text[] | object-store URLs |
| status | enum `available` \| `assigned` \| `maintenance` \| `retired` | transitions: available↔assigned (via assignment create/close), available↔maintenance, any→retired (terminal) |
| onboarded_by | FK users | audit |

### drivers
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| user_id | FK users nullable | set when the driver registers on the app; phone match required (FR-AUTH-05) |
| full_name / phone | text | phone unique — the pre-provisioning key |
| license_number | text | |
| photo_url / emergency_contact | text | |
| status | enum `active` \| `inactive` | |

### auto_route_assignments / driver_auto_assignments
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| auto_id / route_id (or driver_id / auto_id) | FK | same-ward check on create |
| assigned_by | FK users | |
| effective_from | timestamptz | |
| effective_to | timestamptz nullable | NULL = active; **partial unique index** on the subject (auto_id or driver_id... resp. auto_id) `WHERE effective_to IS NULL` enforces one active assignment (FR-FLEET-02/03) |

History is append-only: reassignment closes the open row (sets `effective_to`) and inserts a
new one; UPDATE of historical rows forbidden (FR-FLEET-04).

### households
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| user_id | FK users | one household per resident user (v1, D-3) |
| full_name / address_line / landmark | text | |
| house_geo | geometry(Point, 4326) | GiST index |
| ward_id | FK wards nullable | derived: `ST_Contains(ward.boundary, house_geo)` |
| route_id | FK routes nullable | derived: `ST_Contains(route.serviceable_area, house_geo)`; NULL ⇒ review queue (FR-AUTH-08) |
| mapping_status | enum `auto` \| `admin_corrected` \| `pending_review` | pin edit re-runs derivation and resets to `auto`/`pending_review` (FR-RES-04) |
| notification_radius_m | int | 100–1000, default 300 (FR-RES-05) |

### trips
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| auto_id / driver_id / route_id | FK | snapshot of active assignments at start |
| pass_number | int | 1..route.passes_per_day; starting pass n requires pass n−1 of the same route+date completed/aborted (FR-DRV-02) |
| started_at / ended_at | timestamptz | |
| status | enum `active` \| `completed` \| `aborted` | transitions: active→completed (driver end / auto-end FR-DRV-08), active→aborted (driver/admin) — terminal states |
| end_reason | enum `driver` \| `auto_idle` \| `admin` nullable | |
| distance_covered_m | int nullable | computed from trail at end |

Partial unique index: one `active` trip per auto.

### location_pings *(Timescale hypertable, 90-day raw retention → NFR-06)*
| Field | Type | Rules |
|---|---|---|
| trip_id / auto_id | FK | |
| lat / lng | double | ingest-rejected if accuracy > 100 m or implied speed > 60 km/h (spec §4 integrity) |
| speed / heading / accuracy_m | real | |
| recorded_at | timestamptz | device clock; ordering key within trip |
| received_at | timestamptz | server clock (authoritative for gap detection FR-DRV-05) |

The transport-level `seq` counter (contracts/realtime.md §1) is used only for duplicate
drop and ordering at ingest; it is not persisted.

### media_uploads
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| trip_id / driver_id | FK | |
| type | enum `collection_proof` \| `issue` \| `other` | |
| object_url | text | confirmed after presigned PUT (FR-DRV-06) |
| geo | geometry(Point, 4326) nullable | |
| captured_at | timestamptz | |

### complaints
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| household_id / route_id / ward_id | FK | ward/route snapshotted at filing |
| category | enum `missed_pickup` \| `late` \| `behavior` \| `segregation` \| `other` | |
| description | text | ≤ 2000 chars |
| media_urls | text[] | ≤ 3 (FR-CMP-01) |
| status | enum `open` \| `in_review` \| `resolved` \| `rejected` | open→in_review→resolved/rejected; every transition appended to `complaint_events(complaint_id, actor_id, from, to, note, at)` (FR-CMP-02) |
| assigned_to | FK users nullable | |
| sla_due_at | timestamptz nullable | from operator config (v1.1, FR-CMP-03) |
| resolution_note | text nullable | |

### ratings
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| household_id / route_id | FK | |
| trip_id | FK nullable | |
| stars | int | 1–5 |
| comment | text nullable | |
| collection_date | date | **unique (household_id, collection_date)** (FR-CMP-05) |

### route_pass_days *(pass state per route per service day — resolves skipped-pass storage)*
| Field | Type | Rules |
|---|---|---|
| route_id | FK routes | |
| service_date | date | IST calendar date |
| pass_number | int | 1..passes_per_day |
| status | enum `pending` \| `active` \| `completed` \| `aborted` \| `skipped` | `skipped` auto-set by a scheduler when the window elapses with no trip started (FR-DRV-02); PK (route_id, service_date, pass_number) |
| trip_id | FK trips nullable | the trip that served this pass |

### household_collections *(collection events — drives last-collected + rating trigger)*
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| household_id / trip_id / route_id | FK | |
| pass_number | int | |
| detected_at | timestamptz | first accepted ping of the trip within 75 m of house_geo (Clarifications CHK002); unique (household_id, trip_id) |

### audit_log *(append-only, 2-year retention — Clarifications CHK014)*
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| actor_id | FK users | |
| entity_type / entity_id | text / uuid | |
| action | text | create/update/status-change etc. |
| before / after | jsonb | snapshot diff |
| at | timestamptz | Super Admin read-only; no UPDATE/DELETE grants |

### notifications (outbox)
| Field | Type | Rules |
|---|---|---|
| id | uuid PK | |
| user_id | FK | |
| kind | enum `proximity` \| `arrival` \| `schedule_change` \| `complaint_status` | |
| payload | jsonb | localized server-side (EN/KN) |
| dedup_key | text unique nullable | proximity: `prox:{household_id}:{trip_id}` (FR-NOTIF-02) |
| sent_at | timestamptz nullable | outbox worker → FCM; latency budget 10 s p95 (FR-NOTIF-05) |

## Derived / runtime state (Redis, not Postgres)

- `auto:pos:{auto_id}` — latest position hash + city GEO set, TTL 60 s (live maps).
- `route:households:{route_id}` — GEO set of household points (geofence evaluator).
- `notif:sent:{trip_id}` — SET of household_ids already alerted this trip (dedup).
- `otp:{phone}` — code + attempt counters (expiry/attempt/resend/hourly caps FR-AUTH-02).
- `trip:lastping:{trip_id}` — last received_at (3-min gap alert FR-DRV-05; 30-min idle FR-DRV-08).

## Invariants (enforced in DB where possible, service layer otherwise)

1. Ward boundaries never overlap (trigger with `ST_Overlaps` check).
2. Route serviceable areas lie within their ward (trigger with `ST_Within`).
2b. Route serviceable areas within a ward never overlap each other (trigger with
   `ST_Overlaps`, FR-ROUTE-05) — guarantees deterministic household→route mapping.
3. Auto.ward == Route.ward for any active auto_route_assignment (service check + FK design).
4. At most one active assignment per auto and per driver (partial unique indexes).
5. At most one active trip per auto (partial unique index).
6. Assignment and complaint histories are append-only.
7. Driver PII never appears in any resident-facing response shape (`packages/shared` has no
   driver fields in resident schemas — enforced by contract, FR-RES-07).
