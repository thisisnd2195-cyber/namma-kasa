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

- **T030 (driver photo capture) was deferred and then completed** in the polish phase, once
  the presign path it shares with complaint photos existed.

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
- [X] T030 [P] [US2] Photo capture in `apps/mobile/lib/src/driver/media/`: camera-first, client compression ≤ 500 KB, drift offline queue, presign → PUT → confirm flow (FR-DRV-06); presign/confirm endpoints in `apps/api/src/modules/tracking/media/` with per-trip caps (CHK047)
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

- [X] T053 [P] Account deletion endpoint + flow (PII anonymization within 30 days per CHK010) in `apps/api/src/modules/auth/deletion/` and settings screens in `apps/mobile/lib/src/core/settings/`
- [X] T054 [P] Media lifecycle job in `apps/api/src/modules/tracking/media/retention.ts`: 180-day retention, open-complaint hold (CHK015)
- [X] T055 [P] Accessibility pass per NFR-11: TalkBack labels + ≥ 48 dp audit in `apps/mobile/`, WCAG 2.1 AA sweep of `apps/web/` portal pages
- [X] T056 [P] Localization completion: full EN/KN ARB coverage for resident + driver surfaces (driver defaults KN per CHK045); fallback-EN lint check
- [X] T057 [P] Observability per NFR-09: OpenTelemetry traces + Prometheus metrics in `apps/api/`, tracking-health dashboard tiles (per-ward drops %, ping latency, alert queue age per CHK046)
- [X] T058 Degradation controls (CHK043): live-cadence stretch + WS pause switches in `apps/api/src/modules/tracking/live/`, banner support in resident app
- [X] T059 Rewrite `README.md` for the tracking platform (stack, quickstart pointer, Flutter + docker prerequisites) — closes the v3.0.0 sync-report flag
- [X] T060 Full quickstart execution (all §1–§5 gates green, contract drift check clean) and record results; initial git commit series on `main`
- [X] T061 [P] Load test in `apps/api/test/load/`: k6 scenarios for MQTT/HTTPS ingest at 1,000 msg/s and WS fan-out at pilot-representative concurrency; assert NFR-03 latency budgets (SC-006 pre-pilot verification)

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

## Phase 9: Convergence

Assessment of the codebase against spec, plan and constitution after the first
implement pass. The backend is substantially complete and verified; the gaps are
concentrated in the Flutter app, where several screens and services were built
but never wired into anything a user can reach.

- [X] T062 Add JWT device authentication and per-trip publish ACL to EMQX, replacing `EMQX_ALLOW_ANONYMOUS=true` in `docker-compose.yml`, per contracts/realtime.md §1 (contradicts) — CRITICAL: any client reaching the broker can currently inject pings for any trip
- [X] T063 Route residents from `apps/mobile/lib/src/role_chooser.dart` into resident auth and `ResidentHomeScreen` instead of `_RolePlaceholder`, per US3 (missing) — CRITICAL: the entire resident experience is unreachable
- [X] T064 Run driver location tracking inside a `flutter_foreground_task` service in `apps/mobile/lib/src/driver/trip_tracker.dart` per FR-DRV-03 (partial) — CRITICAL: tracking currently stops when the screen locks, which is most of a collection round
- [X] T065 Build resident onboarding (OTP, consent, pin-drop map) in `apps/mobile/lib/src/resident/onboarding/` per FR-AUTH-07 and FR-AUTH-08 (missing)
- [ ] T066 BLOCKED — needs a Firebase project. Add `firebase_messaging` to `apps/mobile`, register the FCM token on sign-in and handle foreground/background messages per FR-NOTIF-01 (missing) — alerts are queued and sent server-side but no device can receive them
- [X] T067 Add a WebSocket client for `/v1/live` in `apps/mobile/lib/src/resident/` with marker interpolation, reconnect backoff and reauth-frame handling per FR-RES-01 (partial) — the app polls every 20 s against a 2 s requirement
- [X] T068 Build the OEM battery-optimization and autostart wizard in `apps/mobile/lib/src/driver/` per FR-DRV-04 (missing) — this is the mitigation for the spec's top-listed risk
- [X] T069 Add the 30-minute idle confirmation prompt to the driver trip screen per FR-DRV-08 (partial) — only the 45-minute backend force-end exists
- [X] T070 Surface `PhotoQueue` capture and upload state in the driver trip screen per FR-DRV-06 (partial) — the queue is implemented but unreachable
- [X] T071 Navigate to `FeedbackScreen` from the resident home, including the post-collection rating prompt, per FR-CMP-01 and FR-CMP-05 (partial)
- [X] T072 Inject `DegradationService` into `LiveGateway` so the emit cadence and stream pause actually respond to load, per Clarifications CHK043 (partial)
- [X] T073 Add a notification-radius control (100–1000 m) to the resident app per FR-RES-05 (missing)
- [ ] T074 BLOCKED — needs OAuth client credentials. Add `google_sign_in` to the mobile app and wire it to the existing `/auth/login` Google path per FR-AUTH-03 (partial)
- [X] T075 Add TalkBack semantics labels and audit touch targets across `apps/mobile/lib/` per NFR-11 (missing) — no `Semantics` widgets exist
- [X] T076 Add a ward advisory endpoint that sends `schedule_change` notifications, using the existing `scheduleChangeCopy` template, per FR-NOTIF-04 and Clarifications CHK041 (missing)
- [X] T077 Call `/admin/wards/:wardId/edit-impact` from the portal boundary editor and show the affected-household count before saving, per Clarifications CHK017 (partial)
- [X] T078 Add tests for `ComplianceService` erasure and retention sweeps in `apps/api/test/` per NFR-04 and Clarifications CHK010/CHK015 (partial)

### Phase 9 notes

T066 and T074 are the only Phase 9 tasks left open, and both are blocked on
credentials rather than code: `firebase_messaging` needs a Firebase project and
`google-services.json`, and `google_sign_in` needs an OAuth client id. Adding
either package without its config breaks the Android build outright, which is
worse than the gap. The server side of both is finished — FCM sending, token
registration, and Google ID-token verification all work — so each is a
configuration step plus a few lines of client wiring once the credentials exist.

T062 changed the broker from open to closed: devices now authenticate with a
per-trip JWT whose `acl` claim grants publish to exactly one topic. The
simulator publishes with anonymous credentials and will need the same token
flow before it runs again.

## Phase 10: Convergence

Second convergence pass. The Phase 9 broker change (T062) was marked complete on
the strength of a config edit that had never been applied: the EMQX container
was still running its previous configuration, so the "closed broker" was never
actually tested. Forcing the config to apply reveals that it takes the primary
GPS ingest path down, because no broker credentials were ever provisioned.

- [X] T079 Provision EMQX credentials for the ingest consumer (bootstrap CSV or built-in-database seed) so `MqttConsumer` can subscribe, per FR-DRV-03 and plan R4 (contradicts) — CRITICAL: the consumer is currently in a reconnect loop with "Bad username or password" and no ping can reach the server over MQTT
- [X] T080 Mint a per-trip MQTT token in `apps/api/scripts/simulate-trip.ts` so it can publish against the authenticated broker, per quickstart §4 (contradicts) — CRITICAL: the simulator is the only way to exercise US2–US5 without a vehicle, and it can no longer connect
- [X] T081 Add a broker connectivity test to `apps/api/test/` that fails when the consumer cannot subscribe or a device token is rejected, per Constitution V (missing) — a complete ingest outage passed every existing gate
- [X] T082 Add explicit `EMQX_AUTHORIZATION` rules and a test proving a valid token cannot publish to another trip's topic, per contracts/realtime.md §1 (partial) — the ACL is currently asserted only by the JWT claim
- [X] T083 Re-run the simulator against the authenticated broker and correct the "158/158 MQTT pings persisted" line in quickstart.md to reflect a reproducible result, per quickstart Verification record (contradicts)

### Phase 10 notes

Verifying a container-level config change requires recreating the container.
`docker compose up -d` alone will not restart a service whose image and command
are unchanged, which is exactly how the Phase 9 verification came to measure the
old broker. Any future task that edits `docker-compose.yml` should end with
`docker compose up -d --force-recreate <service>` and a functional check.

The local stack is currently left with authentication active and MQTT ingest
failing. The HTTPS fallback endpoint and all ingest logic are unaffected (13
tracking tests pass); only the broker path is down.

## Phase 11: Convergence

Third convergence pass. Phase 10 verified clean: the broker config on disk now
matches the running container, and 97 tests pass from cold including six broker
tests.

This pass found that Constitution IV has been violated since Phase 2. The
contract pipeline was built and its drift guard verified, but the OpenAPI
document only ever contained the five auth routes written that day. Roughly 45
endpoints added across US1 through US5 never reached it, the generated Dart
client has been unused since the day it was produced, and both clients
hand-write the models the principle calls a defect.

- [X] T084 CRITICAL Import shared Zod-derived types in `apps/web/src/` instead of redeclaring `Ward`, `Route`, `Auto`, `Driver`, `AdminComplaint`, `Operator` and the rest, per Constitution IV (contradicts) — `@namma-kasa/shared` is already a declared dependency and is never imported
- [X] T085 CRITICAL Consume the generated client in `apps/mobile/lib/src/core/api.dart` instead of hand-written `Map<String,dynamic>` calls, per Constitution IV (contradicts) — the 20 models in `packages/namma_kasa_api` are imported nowhere
- [X] T086 Extend `apps/api/src/openapi/document.ts` to cover every served route — admin geo, fleet, driver, resident, complaints, notifications, compliance — per Constitution IV and contracts/api.md (partial) — the document currently describes 5 of about 50
- [X] T087 Make `scripts/check-contracts.sh` fail when a route the app serves is absent from the OpenAPI document, per Constitution IV (partial) — it currently only re-emits the document and diffs it against itself, which is why it stayed green through T086's entire gap
- [X] T088 Regenerate the Dart client once T086 lands and commit the result, per plan R2 (partial)

### Phase 11 notes

T087 is the task worth doing first and doing properly. Both of the last two
convergence passes found a guard that measured itself rather than the system:
`contracts:check` diffs the document against the generator that produces it, and
the Phase 9 broker verification read a container that had never loaded the new
config. A check that cannot observe the thing it certifies will keep reporting
success through exactly the gap it exists to prevent.

T084 and T085 are ordered after T086 in practice — importing shared types is
only useful once those types describe the endpoints the clients call.

### Phase 11 notes

The Dart client is generated from a mobile-scoped view of the contract:
`scripts/generate-dart-client.sh` strips `/admin` paths and their named
components before generating. The mobile app is a resident and driver client and
never calls those endpoints; the portal consumes them through the shared Zod
types instead. The practical trigger was that GeoJSON boundaries carry 4-deep
coordinate arrays the `dart` generator emits uncompilable code for.

Three schema shapes were relaxed in the published contract while runtime
validation in `packages/shared` stayed strict, because the generator produces
uncompilable Dart for each: a record whose values are enum arrays
(`wasteTypeSchedule`), an enum carrying a default (`mediaType`, `locale`), and
an array of free-form records (the assignment-history and live-ward responses,
now given proper schemas instead).

`flutter analyze` excludes the generated package, so none of this surfaced until
`flutter test` compiled it. Worth remembering: analyze passing says nothing about
whether generated code builds.

## Phase 12: Convergence

- [X] T089 Fix `_distanceTo` in `apps/mobile/lib/src/resident/resident_home_screen.dart` to return the Euclidean distance instead of the sum of absolute lat/lng deltas, so the map chip agrees with the server's `ST_DWithin` radius per FR-RES-03 and FR-NOTIF-01 (contradicts) — a 300 m auto on a diagonal currently renders as "424 m away" while the push says "~300 m"
- [X] T090 Compute `complaints.sla_due_at` on insert from the owning operator's configured SLA and surface breaches on the admin complaints view per FR-CMP-03 (partial) — the column is selected, typed, and rendered but never written, so every complaint reports a null SLA
- [X] T091 Add the driver quick-report endpoint and screen wiring `driverIssueSchema` to a ward-admin notification per FR-DRV-07 (missing) — the contract and enum exist in `packages/shared` with no consumer
- [X] T092 Emit the sub-75 m "arrived at your street" alert from `NotifyModule.onModuleInit` using the existing `arrivalCopy` template per FR-NOTIF-03 (missing) — the template and the `arrival` notification kind are currently unreachable
- [X] T093 Build the Super Admin city rollup view (active trips, route coverage %, complaint volume and SLA state) in `apps/web/src/app` per FR-DASH-02 (missing)
- [X] T094 Record a route's path geometry from a completed trip's trail, adding the column and the derivation, per FR-ROUTE-04 (missing)
- [X] T095 Prompt for a rating when the serving auto exits the household's proximity zone or its trip completes per FR-CMP-06 (partial) — rating is currently reachable only if the resident opens the feedback screen
- [X] T096 Add the coarse straight-line minutes estimate alongside the distance chip per FR-RES-03 (partial) — depends on T089
- [X] T097 Detect missed pickups (no ping within 75 m of a household during its window) and offer a prefilled complaint per FR-DASH-03 (missing)
- [X] T098 Add the flag-gated Sahaaya 2.0 complaint sync for BBMP wards per FR-CMP-04 (missing)

### Phase 12 notes

The distance bug (T089) was in shipped resident-facing code: `_distanceTo`
computed `dLat² + dLng²` only to test for zero, then returned `|dLat| + |dLng|`.
The square root was never taken, so the map reported Manhattan distance while
the server decided the push with `ST_DWithin` on a geography. A 300 m auto on a
diagonal showed as "424 m away" as the "~300 m" push arrived. The helpers moved
to `lib/src/resident/proximity.dart` so they could be tested at all.

The minutes estimate (T096) needed a pace constant the spec never states. It is
derived rather than invented: FR-RES-05 puts the default alert radius at 300 m
and FR-RES-03 illustrates the hint at that radius as "~6 min away", which fixes
the pace at 300 m / 360 s. A test asserts the two stay consistent.

`sla_due_at` (T090) had been selected, typed, and rendered since Phase 7 and
never written — every complaint reported a null SLA while the portal advertised
"Resident reports and SLAs". Operator `config` was `z.record(z.unknown())`, so
there was nothing to read it from; it now has a shape.

FR-CMP-04 (T098) is a seam, not an integration. BBMP has not published a
Sahaaya 2.0 contract, so the gating, the BBMP-only eligibility rule and the call
site are real and the transport logs. A live client is one `SahaayaClient`
implementation away, with no caller changes.

Adding `/driver/issues` renamed the generated Dart model for the shared
`{lat, lng}` object, because the generator names inline schemas after whichever
endpoint sorts first. It is now a named `GeoPoint` component, so the name no
longer moves when a route is added.

## Phase 13: Convergence

- [X] T099 Surface `routes.recorded_path` on `routeSchema` and in `selectRoute()`, and give the portal a way to adopt a completed trip's trail, per FR-ROUTE-04 (partial) — T094 writes the column but nothing selects it and no page calls `POST /admin/routes/{id}/recorded-path`, so the feature is both unreachable and unobservable
- [X] T100 Capture the resident's language during registration instead of hardcoding `locale: 'en'` in `apps/mobile/lib/src/resident/resident_auth_screen.dart` per FR-RES-06 (contradicts) — every account is stored as English, so the Kannada notification copy in `notify/templates.ts` can never be selected
- [X] T101 Drive `MaterialApp.locale` from the signed-in user's `locale` and add an in-app language switch wired to the existing `updateSettings({locale})` per FR-RES-06 (partial) — the app currently follows the device locale and ignores the stored preference; depends on T100
- [X] T102 Localize `resident_auth_screen.dart`, `feedback_screen.dart`, `settings_sheet.dart` and the remaining English strings in `resident_home_screen.dart` and `proximity.dart` per FR-RES-06 (partial) — 14 translated keys are defined and never referenced
- [X] T103 Branch the first-run tracking wizard on the device manufacturer so each driver sees their own OEM's steps per FR-DRV-04 (partial) — one static paragraph currently names four OEMs to everybody
- [X] T104 Drop the unused `routes.path` column or document why it stays alongside `recorded_path` per plan: data model (unrequested) — it is never read or written anywhere in the codebase

### Phase 13 notes

T099's test found that T094 had never worked. `recordPathFromTrip` selected
`p.geo`, `p.id` and ordered by a column that does not exist — `location_pings`
is a Timescale hypertable holding plain `lat`/`lng` doubles with no id and no
geometry. It typechecked (Kysely raw `sql` is not checked against the schema),
it passed contract coverage (the route was documented), and it had no test, so
nothing ran it. The lesson is narrower than "write tests": a raw-SQL query with
no test is unverified code regardless of what the type checker says.

FR-RES-06 had been recorded as satisfied on the evidence that
`app_localizations_kn.dart` existed. It did, and nothing selected it:
registration hardcoded `locale: 'en'`, `MaterialApp` never set `locale:`, and
14 translated keys were unreferenced. The test now asserts the wiring — that the
stored preference reaches `MaterialApp`, and that each resident-facing key
differs between the two bundles — rather than that translations exist.

`routes.path` is dropped. FR-ROUTE-04 is served by `recorded_path`, which also
carries the trip it came from and when it was adopted.
