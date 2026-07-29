# Phase 0 Research: City Waste Collection Tracking Platform

**Feature**: 001-waste-collection-tracking · **Date**: 2026-07-29

Resolves all open technical choices left by SPEC-WCT-001 (which offered options in several
places) under constitution v3.0.0. Format per decision: Decision / Rationale / Alternatives.

## R1. Backend framework

- **Decision**: NestJS (Node 22+, TypeScript strict) as a modular monolith with modules
  `auth`, `geo`, `fleet`, `tracking`, `notify`, `complaints`.
- **Rationale**: Spec §9 offered "NestJS or Spring Boot"; constitution v3.0.0 mandates
  Node.js/TS, resolving to NestJS. Its module system maps 1:1 to the spec's module list,
  and first-class OpenAPI tooling serves Principle IV (backend-owned contracts).
- **Alternatives**: Spring Boot (violates constitution); Fastify/Hono bare (fewer
  conventions to hold six modules + guards/scoping; more glue code, worse fit for the
  ward-scoping enforcement the spec demands on every admin call).

## R2. Contract pipeline (Principle IV)

- **Decision**: Zod schemas in `packages/shared` remain the single source of truth →
  OpenAPI 3.1 document generated via `zod-openapi` and served/emitted by the NestJS app →
  Dart client generated with `openapi-generator` (dart-dio) into
  `apps/mobile/lib/src/api/` (generated code committed; regeneration script in repo).
- **Rationale**: TS consumers (web, backend) import Zod directly; Flutter gets a typed
  client without hand-written models — exactly the constitution's mechanism.
- **Alternatives**: NestJS decorator-based Swagger (moves truth out of Zod, duplicates
  shapes); hand-written Dart models (constitutional defect); GraphQL (new surface area
  the spec doesn't ask for).

## R3. Database access & migrations

- **Decision**: Raw SQL migrations via `node-pg-migrate`; query layer with Kysely
  (typed SQL builder). PostgreSQL 16 + PostGIS + TimescaleDB (hypertable for
  `location_pings`).
- **Rationale**: PostGIS geometry ops, GiST indexes, Timescale hypertables, and partial
  unique indexes (one-active-assignment rules) all need real SQL — an ORM would fight
  every interesting table. Kysely keeps queries typed without hiding SQL (Principle I).
- **Alternatives**: Prisma (weak PostGIS/Timescale support); TypeORM (heavy, decorator
  drift vs Zod source of truth); Drizzle (viable, but custom-type ceremony for geometry
  exceeded plain SQL in prototypes reported by the community).

## R4. Real-time transports

- **Decision**: Driver ingest over MQTT via self-hosted EMQX (topic
  `trips/{trip_id}/pings`, JWT auth), HTTPS batch endpoint as fallback. Resident fan-out
  over plain WebSocket from the NestJS app (`/live?route_id=`), JWT-scoped to the
  resident's own route, throttled to 1 update / 2 s.
- **Rationale**: Matches spec §5/§6 primary options. MQTT suits flaky driver networks
  (QoS 1, tiny payloads, offline queue replay). Resident fan-out via WS avoids shipping
  an MQTT client + broker ACLs into the resident path; route-scoping is a one-line JWT
  guard in the backend.
- **Alternatives**: MQTT both directions (pushes per-route ACL logic into broker config —
  harder to audit than a JWT guard); WS both directions (loses QoS/offline replay
  semantics for drivers); AWS IoT Core (managed cost + lock-in; EMQX runs in dev
  docker-compose and prod alike).

## R5. Live-position store & geofencing

- **Decision**: Redis: `GEO` set + hash per auto (TTL 60 s) for latest positions; geofence
  evaluator as a backend worker doing `GEOSEARCH` against per-route household GEO sets on
  each accepted ping; dedup key `(household_id, trip_id)` in Redis SET. Redis also backs
  OTP codes and rate limits.
- **Rationale**: Spec §6 prescribes exactly this; one Redis serves three needs (positions,
  OTP, rate limits) — minimal moving parts at 1,000 msg/s worst case.
- **Alternatives**: PostGIS-only geofencing (per-ping SQL round-trips at peak; Timescale
  ingest and geofence contention); dedicated stream processor (Kafka/Flink — wildly over
  scale for 1k msg/s, Principle I violation).

## R6. Mobile app (Flutter)

- **Decision**: Flutter stable (3.x, Dart 3, null safety), single APK with role-based
  entry (resident/driver). Packages: `maplibre_gl` (map), `riverpod` (state), `dio` (+
  generated dart-dio client), `geolocator` + `flutter_foreground_task` (driver tracking
  foreground service), `mqtt_client` (driver ingest publish), `firebase_messaging` (FCM),
  `flutter_secure_storage` (tokens), `drift` (offline queue for pings/photos), `intl` +
  ARB files (EN/KN).
- **Rationale**: Locked decision D-1 + constitution v3.0.0. Each package is the de-facto
  standard for its slot; the offline ping/photo queue needs durable local storage (drift
  over ad-hoc files).
- **Alternatives**: React Native/Expo (superseded by constitution v3.0.0); `workmanager`
  for tracking (unreliable for continuous 5 s cadence — foreground service is the only
  dependable primitive on OEM-throttled Androids).

## R7. Admin web portal

- **Decision**: Keep the existing Next.js 16 app in `apps/web`, repurposed as the admin
  portal (Super Admin + Ward Admin). MapLibre GL JS + `@mapbox/mapbox-gl-draw`
  (MapLibre-compatible) for boundary drawing; TanStack Query for data fetching against
  the NestJS API.
- **Rationale**: Constitution keeps React+TS web in `apps/web`; the scaffolded app
  already has Next 16 + Tailwind + MapLibre wiring worth keeping. Server rendering is
  fine for the portal shell; map editing is client-side anyway.
- **Alternatives**: Separate SPA (Vite) — loses the existing scaffold and SSR for any
  future public pages; keeping the public black-spot map (out of scope — old product).

## R8. Auth

- **Decision**: Custom auth in NestJS: SMS OTP (MSG91 behind an `OtpSender` interface
  with a console/dev implementation), then password (argon2id) or Google Sign-In
  (ID-token verification). JWT access 15 min + rotating refresh 30 days (hashed,
  stored, revocable). Role/ward scope claims; global NestJS guard enforces ward scoping.
- **Rationale**: Spec's flows (pre-provisioned driver phones, OTP limits, driver
  new-device re-verification) are too specific for an off-the-shelf provider;
  constitution puts domain logic in the Node layer.
- **Alternatives**: Supabase Auth (phone OTP exists, but driver pre-provisioning check,
  linked dual-credential model, and rotating-refresh policy fight its model); Firebase
  Auth (same problem + vendors the core user table away from Postgres).

## R9. Media storage

- **Decision**: S3-compatible object storage (MinIO in dev via docker-compose, S3/GCS in
  prod) with pre-signed upload URLs issued by the backend
  (`POST /driver/media/presign` → PUT → `POST /driver/media/confirm`).
- **Rationale**: Spec §5 prescribes the presign flow; MinIO keeps dev parity.
- **Alternatives**: Supabase Storage (ties media auth to Supabase auth we're not using);
  direct-to-backend uploads (doubles backend bandwidth for ≤500 KB × fleet-scale images).

## R10. Map tiles

- **Decision**: OpenFreeMap public instance for MVP/pilot; self-hosted Protomaps PMTiles
  (single file on S3+CDN) as the documented scale path. Tile URL behind one config value;
  map widget/component behind an internal abstraction on both clients.
- **Rationale**: D-2 (zero-cost, no osm.org in production, swappable). OpenFreeMap
  explicitly permits production use at no cost; PMTiles removes third-party dependence
  when installs grow.
- **Alternatives**: Google Maps (billed — prohibited by D-2); raw osm.org tiles
  (prohibited by usage policy and D-2). Note: the current scaffold's dev map uses
  osm.org raster tiles — must be replaced during restructure.

## R11. Push notifications

- **Decision**: FCM via `firebase-admin` in the notify module; device tokens stored per
  user; notification templates localized EN/KN server-side.
- **Rationale**: Android-only launch makes FCM the only realistic push channel; spec
  names it.
- **Alternatives**: none credible for Android push.

## R12. Local development environment

- **Decision**: `docker-compose.yml` at repo root: `timescale/timescaledb-ha` image
  (Postgres 16 + PostGIS + Timescale), Redis, EMQX, MinIO. Seed script creates one
  operator, one ward (real boundary sample), one route, one auto, one driver, sample
  households. A `scripts/simulate-trip.ts` replays a GPS trail as MQTT pings for
  end-to-end testing without a vehicle.
- **Rationale**: One command brings up everything the quickstart needs; the simulator is
  the only practical way to test tracking/geofencing/notifications in dev.
- **Alternatives**: Supabase local stack (drops Redis/EMQX/MinIO — insufficient); cloud
  dev environment (network friction for the Flutter device loop).
- **Prereq flags**: Docker Desktop and the Flutter SDK are NOT currently installed on the
  dev machine; both are setup tasks. DLT-registered SMS templates (MSG91) have lead time —
  registration should start immediately; dev uses the console OTP sender meanwhile.

## R13. Disposition of the existing scaffold

- **Decision**: Retire the Expo app (`apps/mobile` is replaced by the Flutter project).
  Keep `apps/web` (repurposed, R7). Keep `packages/shared` as the contract source but
  replace its Supabase client helpers with API-shape schemas. Retire `supabase/`
  (config + migrations) — its PostGIS patterns (ward point-in-polygon trigger, event
  audit trigger) are ported into the new `node-pg-migrate` migrations. Remove
  `@supabase/supabase-js` everywhere; clients speak only to the NestJS API.
- **Rationale**: Constitution v3.0.0 + product pivot; the geo SQL is the one part worth
  carrying forward.
- **Alternatives**: Incremental strangler migration (nothing is deployed or committed —
  there is no user to migrate; clean cut is simpler).
