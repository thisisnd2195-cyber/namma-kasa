# Tasks: City Waste Collection Tracking Platform

**Input**: Design documents from `/specs/001-waste-collection-tracking/`

**Prerequisites**: plan.md, spec.md (Clarifications session 2026-07-29 applied), research.md
(R1–R13), data-model.md, contracts/api.md, contracts/realtime.md, quickstart.md

**Tests**: Constitution Principle V requires unit tests for domain logic/schemas and
integration coverage of the critical flow — test tasks are included where mandated, not
blanket-TDD.

**Organization**: Phase 1 setup → Phase 2 foundation → one phase per user story (US1–US5,
priority order) → polish. Each story phase ends independently testable per its spec criteria.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no dependency on incomplete tasks)
- **[US#]**: user story label (story phases only)

## Implementation notes (2026-07-29)

Two deviations from the plan, both forced by the local environment and both
equivalent in capability:

- **T001 uses Colima, not Docker Desktop.** The Docker Desktop cask aborts without an
  interactive sudo password (it symlinks into `/usr/local/bin`). Colima + the `docker`
  and `docker-compose` CLIs give the same daemon and Compose API with no privileged
  helper. Start it with `colima start` before `docker compose up`.
- **Local Postgres is published on 5433, not 5432**, because this machine already runs a
  Homebrew `postgresql@16` on 5432. `POSTGRES_PORT` and `DATABASE_URL` in `.env.example`
  reflect this; the container port is unchanged.
- **T008 tests run against the Compose database** rather than Testcontainers. The stack is
  already required for local work, so a second container runtime inside the test process
  buys nothing; `test/helpers/db.ts` wraps every test in a rolled-back transaction for
  isolation. Point `TEST_DATABASE_URL` at any throwaway database in CI.

- **T011 uses the plain `dart` OpenAPI generator, not `dart-dio`.** dart-dio needs a second
  build_runner pass plus json_serializable and copy_with_extension; the plain generator emits
  self-contained models with no extra toolchain, which is the simpler thing that works at this
  contract size (Principle I). The client is a path-dependency package at
  `apps/mobile/packages/namma_kasa_api`, not inside `lib/`, because a nested package under
  `lib/` breaks Dart's layout rules. Regenerate with `pnpm contracts:generate`; CI guards drift
  with `pnpm contracts:check`. Requires a JDK (`brew install openjdk`).

- **MQTT auth is dev-open.** `docker-compose.yml` sets `EMQX_ALLOW_ANONYMOUS=true` so the
  simulator and local devices can publish without credentials. Production must authenticate
  devices with the driver's access token and restrict publish to their own trip topic, per
  `contracts/realtime.md` — that hook is not built yet and is a prerequisite for the pilot.

- **T030 (driver photo capture) is deferred, not done.** The trip loop and its evidence
  trail work without it; photo proof is an addition to that evidence rather than a
  prerequisite. It needs the S3 presign endpoints plus camera and compression packages,
  and is best done alongside the resident complaint photos in US5 which share the same
  upload path.

- **Push delivery is console-only in development.** `PUSH_SENDER=console` logs what would
  have been sent; `PUSH_SENDER=fcm` with `FCM_SERVICE_ACCOUNT_JSON` uses real FCM. The
  Flutter side registers a token and handles the permission-denied fallback, but wiring
  the `firebase_messaging` plugin and `google-services.json` needs a real Firebase project
  and is a pilot prerequisite.
- **T046 latency is asserted in tests, not measured under load.** The queue-to-drain path
  is verified well inside the 10 s budget with a fake transport; the SC-005 figure under
  real fan-out depends on the load test in T061.

## Phase 1: Setup (environment + repo restructure per research R13)

- [X] T001 Install prerequisites: Docker Desktop and Flutter SDK (stable); verify `docker compose version` and `flutter doctor` pass on this machine
- [X] T002 Retire pre-pivot scaffold: delete Expo app contents of `apps/mobile/`, delete `supabase/` (after copying its trigger SQL patterns aside for T007), remove `@supabase/supabase-js` from `packages/shared/package.json`, delete `packages/shared/src/supabase.ts` and Supabase usages in `apps/web/src/`
- [X] T003 Create `docker-compose.yml` at repo root: timescaledb-ha (Postgres16+PostGIS+Timescale), Redis, EMQX, MinIO, with healthchecks and a `.env.example`
- [X] T004 Scaffold NestJS app in `apps/api/` (strict TS, config module, problem+json error filter per contracts/api.md, pino logging) wired into pnpm workspace + turbo.json
- [X] T005 [P] Scaffold Flutter app in `apps/mobile/` (`flutter create`, package `app.nammakasa`, strict analyzer in `analysis_options.yaml`, riverpod + dio + intl EN/KN skeleton, role-based entry shell)
- [X] T006 [P] Repurpose `packages/shared/src/` as contract source: base Zod schemas (ids, geo point, enums from data-model.md), remove old report schemas; keep `pnpm typecheck` green

## Phase 2: Foundational (blocks all stories)

- [X] T007 Write initial migrations in `apps/api/migrations/`: all data-model.md tables (incl. `route_pass_days`, `household_collections`, `audit_log`), enums, PostGIS/Timescale setup, GiST indexes, partial unique indexes (active assignment/trip), ward-overlap + route-within-ward + route-overlap triggers (port patterns from old supabase SQL)
- [X] T008 Set up Kysely in `apps/api/src/db/` with generated DB types and a Testcontainers harness in `apps/api/test/` proving migrations apply and triggers fire
- [X] T009 Auth module in `apps/api/src/modules/auth/`: OTP send/verify (Redis limits per FR-AUTH-02, console sender + MSG91 `OtpSender` interface), register (resident/driver paths, driver pre-provision check FR-AUTH-05), login (password argon2id / Google ID-token), JWT 15-min access + rotating refresh with reuse revocation, driver single-device rule (Clarifications CHK012)
- [X] T010 Authorization guards in `apps/api/src/modules/auth/guards/`: role guard + ward-scope guard applied globally to `/v1/admin/*` (FR-WARD-06), audit-log interceptor writing admin mutations to `audit_log` table (Clarifications CHK014)
- [X] T011 [P] Contract pipeline: zod-openapi emitter in `apps/api/src/openapi/`, `scripts/generate-dart-client.sh` (openapi-generator dart-dio → `apps/mobile/lib/src/api/`), and `pnpm contracts:check` drift gate wired into turbo
- [X] T012 [P] Rate-limit middleware in `apps/api/src/common/rate-limit/` (per-user/IP defaults, complaint/presign/WS-reconnect limits from Clarifications CHK013)
- [X] T013 [P] Seed script `apps/api/scripts/seed.ts` + fixtures (`fixtures/wards-sample.geojson`, `fixtures/trail-route1.geojson`): operator, ward, route, auto, pre-provisioned driver phone, households per quickstart.md §1
- [X] T014 [P] Flutter core in `apps/mobile/lib/src/core/`: session store (flutter_secure_storage), dio interceptors (auth/refresh), map abstraction widget over maplibre_gl with configurable tile URL (R10 — OpenFreeMap, no osm.org, neutral light style per DS-06), `ThemeData` built from spec Design System tokens (spec Design Tokens v1, DS-01..05), EN/KN ARB scaffolding
- [X] T015 [P] Portal auth in `apps/web/src/`: login page, session handling against `/v1/auth/login`, role-based layout shells for Super Admin and Ward Admin; Tailwind theme mirroring the spec Design System tokens (spec Design Tokens v1, DS-01..05); strip old public-map pages
- [X] T016 Unit tests for shared schemas and auth flows in `apps/api/test/` (OTP limits, refresh rotation/reuse, driver device rule) — Principle V

**Checkpoint**: `docker compose up` + migrate + seed + all quality gates green.

## Phase 3: User Story 1 — Admin sets up the service area (P1) 🎯 MVP

**Goal**: Operators → wards (import/draw) → ward admins → routes → autos/drivers → assignments.
**Independent test**: spec US1 acceptance 1–5 via portal against seeded DB (quickstart §2).

- [X] T017 [P] [US1] Zod contracts for geo + fleet resources in `packages/shared/src/contracts/` (operators, wards incl. GeoJSON boundary, import report, ward-admins, routes incl. waste_type_schedule, autos, drivers, assignments)
- [X] T018 [US1] Geo module in `apps/api/src/modules/geo/`: operators CRUD (retirement blocked with active wards), wards CRUD with `ST_Overlaps` 409 + conflict GeoJSON (FR-WARD-05), GeoJSON/KML import with per-feature accept/reject report (FR-WARD-04, CHK018), ward-admin provisioning (FR-WARD-06), ward boundary edit impact-count + household re-flag (CHK017)
- [X] T019 [US1] Fleet module in `apps/api/src/modules/fleet/`: autos CRUD (registration regex, status transitions per data-model.md), drivers CRUD (pre-provisioning), assignment endpoints closing previous open row (`effective_from/to`, same-ward checks, FR-FLEET-01..04, CHK022)
- [X] T020 [US1] Routes in geo module: CRUD with `ST_Within` ward validation + intra-ward route-overlap rejection (FR-ROUTE-01/05), passes_per_day, waste-type schedule per weekday (FR-ROUTE-03)
- [X] T021 [P] [US1] Portal wards pages in `apps/web/src/app/wards/`: list/map, boundary drawing with mapbox-gl-draw, overlap-conflict visualization, GeoJSON/KML import UI with reject report
- [X] T022 [P] [US1] Portal routes/fleet pages in `apps/web/src/app/routes/` and `apps/web/src/app/fleet/`: route drawing + schedule editor, auto/driver onboarding forms, assignment screens listing only available same-ward autos, assignment history view
- [X] T023 [US1] Integration tests in `apps/api/test/geo-fleet.spec.ts`: US1 acceptance scenarios 1–5 (import, overlap reject, route outside ward, assignment history, ward-scope denial)

**Checkpoint**: US1 demoable end-to-end via portal.

## Phase 4: User Story 2 — Driver runs a collection trip (P2)

**Goal**: Driver registration → trip lifecycle → continuous GPS with offline spool → watchdogs.
**Independent test**: spec US2 acceptance 1–5 using the simulator + a real device (quickstart §3–4).

- [X] T024 [P] [US2] Zod contracts for trips/pings/media/assignment-view in `packages/shared/src/contracts/`; regenerate Dart client
- [X] T025 [US2] Tracking module (trips) in `apps/api/src/modules/tracking/`: start (pass sequencing via `route_pass_days` incl. `skipped` auto-marking scheduler, one-active-per-auto 409), end/abort (driver reason, admin abort, `auto_idle` force-end 45 min per FR-DRV-08), assignment snapshot into trip
- [X] T026 [US2] Ingest in `apps/api/src/modules/tracking/ingest/`: EMQX JWT auth hook + publish ACL, MQTT consumer for `trips/{id}/pings`, HTTPS batch fallback endpoint, validation (accuracy ≤ 100 m, 3-ping rolling speed window per CHK036, seq dedup/ordering per contracts/realtime.md), Redis latest-position write, Timescale append
- [X] T027 [US2] Watchdogs in `apps/api/src/modules/tracking/watchdogs/`: tracking-dropped detector (received_at gap > 3 min, auto-clear on resume, FR-DRV-05), idle auto-end prompt flow (30 min) + unreachable force-end (45 min)
- [X] T028 [P] [US2] Flutter driver registration + home in `apps/mobile/lib/src/driver/`: pre-provisioned phone flow, consent screen (trip-time tracking, EN/KN per CHK009), assigned auto/route area map, window, waste types, pass progress (FR-DRV-01)
- [X] T029 [US2] Flutter trip runner in `apps/mobile/lib/src/driver/trip/`: start/end (56 dp controls), foreground service via flutter_foreground_task + geolocator (5 s / 25 m cadence), MQTT publish with drift-backed unbounded offline spool and ordered replay (FR-DRV-03 as clarified), GPS-quality warning (CHK008), battery-optimization first-run wizard with OEM steps (FR-DRV-04)
- [ ] T030 [P] [US2] Photo capture in `apps/mobile/lib/src/driver/media/`: camera-first, client compression ≤ 500 KB, drift offline queue, presign → PUT → confirm flow (FR-DRV-06); presign/confirm endpoints in `apps/api/src/modules/tracking/media/` with per-trip caps (CHK047)
- [X] T031 [US2] Trip simulator `apps/api/scripts/simulate-trip.ts`: replays `fixtures/trail-route1.geojson` over MQTT as the seeded driver (quickstart §4)
- [X] T032 [US2] Basic ward live dashboard in `apps/web/src/app/live/[wardId]/`: active trips map from Redis positions + tracking-dropped alerts (FR-DASH-01 minimum needed for US2 acceptance 5)
- [X] T033 [US2] Integration tests in `apps/api/test/tracking.spec.ts`: US2 acceptance 1–5 (unprovisioned refusal, offline replay ordering, pass gating, idle auto-end, dropped alert) with Testcontainers (Postgres/Redis/EMQX)

**Checkpoint**: simulator-driven trip visible on portal dashboard; real-device smoke per quickstart.

## Phase 5: User Story 3 — Resident registers and tracks live (P3)

**Goal**: Resident onboarding with pin-drop mapping → live home map via WS.
**Independent test**: spec US3 acceptance 1–5 (quickstart §3–4).

- [X] T034 [P] [US3] Zod contracts for household/resident-home/review-queue in `packages/shared/src/contracts/`; regenerate Dart client
- [X] T035 [US3] Household mapping in `apps/api/src/modules/geo/households/`: point-in-polygon ward+route derivation, route-overlap-free guarantee (FR-ROUTE-05), pending_review path, pin-edit re-mapping with old-route alert cancellation (FR-RES-04, CHK040), review-queue endpoints with 48 h aging flag (CHK020)
- [X] T036 [US3] Resident home endpoint `GET /v1/resident/home` in `apps/api/src/modules/tracking/`: route/schedule/pass info, active trips, last-collected from `household_collections`; collection-event recorder (75 m proximity per Clarifications CHK002, unique per household+trip) in the geofence path
- [X] T037 [US3] WebSocket fan-out in `apps/api/src/modules/tracking/live/`: `/v1/live` upgrade with JWT route-scope check, ≤ 1 update/2 s throttle per auto, trip_status frames, 60-min reauth frame (contracts/realtime.md §2), ward-admin scope for dashboard reuse
- [X] T038 [P] [US3] Flutter resident onboarding in `apps/mobile/lib/src/resident/onboarding/`: OTP → credential (password or google_sign_in) → explicit phone/location consent screen (NFR-04) → house details with pin-drop-first map (FR-AUTH-07), pending-review state UI
- [X] T039 [US3] Flutter resident home in `apps/mobile/lib/src/resident/home/`: live map with all serving autos (registration labels only — FR-RES-07), marker interpolation, waste types/window/pass/last-collected, no-trip empty state with next window (CHK005), WS reconnect + reauth handling
- [X] T040 [P] [US3] Portal review-queue page in `apps/web/src/app/review-queue/`: pending households list with aging flags, manual route assignment (FR-AUTH-08)
- [X] T041 [US3] Integration tests in `apps/api/test/resident.spec.ts`: US3 acceptance 1–5 (OTP limits, auto-mapping, review queue, WS scoping + cadence, PII absence in all resident payloads)

**Checkpoint**: full P1→P3 slice: admin sets up, simulator drives, resident watches live.

## Phase 6: User Story 4 — Proximity alerts (P4)

**Goal**: Geofenced FCM alerts, one per household per pass, ≤ 10 s p95.
**Independent test**: spec US4 acceptance 1–3 via simulator.

- [X] T042 [US4] Geofence evaluator in `apps/api/src/modules/tracking/geofence/`: Redis GEO household sets per route, per-ping radius search, per-pass dedup key (household, route, service-date, pass) per FR-NOTIF-02 as clarified, forward-in-time evaluation only (CHK042)
- [X] T043 [US4] Notify module in `apps/api/src/modules/notify/`: outbox table + worker, firebase-admin FCM sender, EN/KN server-side templates with 50 m distance rounding (CHK026), schedule-change/complaint-status kinds + per-route service advisory broadcast (CHK041), device-token registration endpoint
- [X] T044 [P] [US4] Flutter notification handling in `apps/mobile/lib/src/core/notifications/`: firebase_messaging setup, token registration, permission-denied in-app banner fallback (CHK039), notification radius setting screen (FR-RES-05)
- [X] T045 [US4] Integration test in `apps/api/test/notifications.spec.ts`: US4 acceptance 1–3 (latency budget assertion against fake FCM, re-entry dedup, per-pass alerts) + outbox latency metric export
- [X] T046 [US4] Latency validation run: simulator pass over seeded households measuring geofence→send p95 ≤ 10 s (SC-005); record method+result in `specs/001-waste-collection-tracking/quickstart.md` addendum

## Phase 7: User Story 5 — Complaints & ratings (P5)

**Goal**: Complaint lifecycle with notifications; one rating per household per IST collection day.
**Independent test**: spec US5 acceptance 1–3.

- [X] T047 [P] [US5] Zod contracts for complaints/ratings in `packages/shared/src/contracts/`; regenerate Dart client
- [X] T048 [US5] Complaints module in `apps/api/src/modules/complaints/`: create (category/description/≤ 3 photos, 5-per-day household limit), status transitions with `complaint_events` history, ward-admin queue endpoints, behavior-complaint driver-identity shielding (CHK034), status-change notifications via notify module (FR-NOTIF-04)
- [X] T049 [US5] Ratings in `apps/api/src/modules/complaints/ratings/`: 1–5 stars, unique (household, IST collection_date) with 409, MVP trigger = collection event that day (CHK035)
- [X] T050 [P] [US5] Flutter complaint + rating flows in `apps/mobile/lib/src/resident/feedback/`: complaint form with photos (reuse presign), status history view, rating banner post-collection
- [X] T051 [P] [US5] Portal complaints queue in `apps/web/src/app/complaints/`: filterable queue, status workflow, resolution notes
- [X] T052 [US5] Integration tests in `apps/api/test/complaints.spec.ts`: US5 acceptance 1–3 (status history + notification, duplicate-rating 409, dashboard trip status present)

## Phase 8: Polish & Cross-Cutting

- [ ] T053 [P] Account deletion endpoint + flow (PII anonymization within 30 days per CHK010) in `apps/api/src/modules/auth/deletion/` and settings screens in `apps/mobile/lib/src/core/settings/`
- [ ] T054 [P] Media lifecycle job in `apps/api/src/modules/tracking/media/retention.ts`: 180-day retention, open-complaint hold (CHK015)
- [ ] T055 [P] Accessibility pass per NFR-11: TalkBack labels + ≥ 48 dp audit in `apps/mobile/`, WCAG 2.1 AA sweep of `apps/web/` portal pages
- [ ] T056 [P] Localization completion: full EN/KN ARB coverage for resident + driver surfaces (driver defaults KN per CHK045); fallback-EN lint check
- [ ] T057 [P] Observability per NFR-09: OpenTelemetry traces + Prometheus metrics in `apps/api/`, tracking-health dashboard tiles (per-ward drops %, ping latency, alert queue age per CHK046)
- [ ] T058 Degradation controls (CHK043): live-cadence stretch + WS pause switches in `apps/api/src/modules/tracking/live/`, banner support in resident app
- [X] T059 Rewrite `README.md` for the tracking platform (stack, quickstart pointer, Flutter + docker prerequisites) — closes the v3.0.0 sync-report flag
- [ ] T060 Full quickstart execution (all §1–§5 gates green, contract drift check clean) and record results; initial git commit series on `main`
- [ ] T061 [P] Load test in `apps/api/test/load/`: k6 scenarios for MQTT/HTTPS ingest at 1,000 msg/s and WS fan-out at pilot-representative concurrency; assert NFR-03 latency budgets (SC-006 pre-pilot verification)

## Dependencies

- Phase 1 → Phase 2 → US1 (Phase 3) → US2 (Phase 4) → US3 (Phase 5) → US4 (Phase 6) → US5 (Phase 7) → Polish
- Story-level: US2 depends on US1 data (routes/autos/drivers); US3 depends on US1 (mapping targets) and uses US2 trips for live view; US4 depends on US2 (pings) + US3 (households/radius); US5 depends on US3 (households) and touches US4's notify module for status alerts
- Within stories, [P] tasks may run concurrently; contract tasks (T017, T024, T034, T047) precede their consumers

## Parallel Execution Examples

- Phase 2: T011, T012, T013, T014, T015 in parallel after T009/T010
- US1: T021 + T022 (portal) in parallel with T023 once T018–T020 land
- US2: T028 + T030 (Flutter) in parallel with T026–T027 (backend)
- Polish: T053–T057 all parallel

## Implementation Strategy

MVP = Phases 1–3 (US1) demoable, then vertical increments per story; each checkpoint is a
demo/test gate matching the story's independent-test criteria. Suggested pilot cut: through
Phase 6 (US4) — complaints (US5) can trail into the pilot itself if timeline demands.
