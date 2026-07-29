# API Contract: REST `/v1`

**Source of truth**: Zod schemas in `packages/shared/src/contracts/` → OpenAPI 3.1 emitted at
build (`pnpm --filter @namma-kasa/api openapi`) → committed to `contracts/openapi.json` →
Dart client regenerated via `scripts/generate-dart-client.sh`. This document is the
human-readable summary; the OpenAPI file is the machine contract.

Conventions: JSON bodies; errors are RFC 9457 `application/problem+json`; auth via
`Authorization: Bearer <access-jwt>` unless marked public. Role scoping in brackets.
Ward Admin calls are hard-scoped server-side to their ward (FR-WARD-06).

## Auth (public)

| Endpoint | Request → Response | Notes |
|---|---|---|
| `POST /v1/auth/otp/send` | `{phone}` → `202 {resendAfterSec}` | limits: 5/hour/number, resend ≥ 30 s (FR-AUTH-02) |
| `POST /v1/auth/otp/verify` | `{phone, code}` → `{verificationToken}` | 3 attempts, 5-min expiry |
| `POST /v1/auth/register` | `{verificationToken, role: resident\|driver, credential: {password} \| {googleIdToken}, profile}` → `{accessToken, refreshToken, user}` | driver phone must be pre-provisioned (FR-AUTH-05); resident profile includes household fields + `pin {lat,lng}` (FR-AUTH-07) |
| `POST /v1/auth/login` | `{phone, password}` or `{googleIdToken}` → tokens | driver new-device ⇒ `428` requiring OTP re-verify (FR-AUTH-04) |
| `POST /v1/auth/refresh` | `{refreshToken}` → rotated tokens | reuse of a rotated token revokes the chain |

## Resident [resident]

| Endpoint | Response shape (summary) | Notes |
|---|---|---|
| `GET /v1/resident/home` | `{household, route {name, todayWasteTypes, window, passesPerDay}, activeTrip {autoRegistration, passNumber, lastPosition} \| null, lastCollectedAt}` | never contains driver PII (FR-RES-07) |
| `PATCH /v1/resident/household` | updated household incl. new `mappingStatus` | pin change re-runs mapping (FR-RES-04) |
| `PATCH /v1/resident/settings` | `{notificationRadiusM, locale}` | 100–1000 m (FR-RES-05) |
| `POST /v1/resident/complaints` | `{category, description, mediaUrls ≤ 3}` → complaint | FR-CMP-01 |
| `GET /v1/resident/complaints` | list w/ status history | FR-CMP-02 |
| `POST /v1/resident/ratings` | `{stars 1..5, comment?}` → `201` or `409` if already rated today | FR-CMP-05 |
| `POST /v1/resident/media/presign` | `{contentType}` → `{uploadUrl, objectUrl}` | complaint photos |

## Driver [driver]

| Endpoint | Response / behavior | Notes |
|---|---|---|
| `GET /v1/driver/assignment` | `{auto, route {area GeoJSON, window, wasteTypes}, today {passesCompleted, passesTotal}}` | FR-DRV-01 |
| `POST /v1/driver/trips` | `{passNumber}` → trip; `409` if previous pass incomplete or auto already on active trip | FR-DRV-02 |
| `PATCH /v1/driver/trips/{id}/end` | `{reason?}` → completed trip | |
| `POST /v1/driver/trips/{id}/pings` | `{pings: [{lat,lng,speed,heading,accuracy,recordedAt}] ≤ 20}` → `{accepted, rejected}` | HTTPS fallback to MQTT (R4) |
| `POST /v1/driver/media/presign` → PUT → `POST /v1/driver/media/confirm` | presigned flow | FR-DRV-06 |
| `POST /v1/driver/issues` | `{kind: breakdown\|road_blocked\|other, note?}` → `201`, notifies Ward Admin | FR-DRV-07 (v1.1) |

## Admin [super = Super Admin, ward = Ward Admin]

| Endpoint | Notes |
|---|---|
| `POST/PATCH /v1/admin/operators` [super] | FR-WARD-01 |
| `POST/PATCH /v1/admin/wards` [super] | body includes `boundary` GeoJSON; `409 + conflict GeoJSON` on overlap (FR-WARD-05) |
| `POST /v1/admin/wards/import` [super] | GeoJSON/KML FeatureCollection; per-feature accept/reject report (FR-WARD-04) |
| `POST /v1/admin/ward-admins` [super] | user + ward binding (FR-WARD-06) |
| `POST/PATCH /v1/admin/routes` [ward] | `422` if area not within ward (FR-ROUTE-01) |
| `POST /v1/admin/autos` · `POST /v1/admin/autos/{id}/assign-route` [ward] | assignment closes previous (`effectiveFrom`), same-ward enforced (FR-FLEET-02/04) |
| `POST /v1/admin/drivers` · `POST /v1/admin/drivers/{id}/assign-auto` [ward] | FR-FLEET-03 |
| `GET /v1/admin/households/review-queue` · `PATCH /v1/admin/households/{id}/route` [ward] | FR-AUTH-08 |
| `GET/PATCH /v1/admin/complaints` [ward] | status transitions append events (FR-CMP-02) |
| `GET /v1/admin/live/wards/{id}` [ward/super] | active trips + latest positions + tracking-dropped flags (FR-DASH-01, FR-DRV-05) |

## Cross-cutting

- All list endpoints: cursor pagination `?cursor=&limit=` (default 50, max 200).
- Mutations by admins append to an `audit_log` (NFR-05).
- Localizable strings (waste types, notification texts) resolved server-side by `locale`.
