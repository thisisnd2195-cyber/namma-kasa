# Implementation Plan: City Waste Collection Tracking Platform

**Branch**: `001-waste-collection-tracking` | **Date**: 2026-07-29 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-waste-collection-tracking/spec.md`

## Summary

Build the MVP of a live waste-collection tracking platform for Bengaluru: Ward/route/fleet
administration in a web portal, a Flutter Android app serving drivers (trip execution +
continuous GPS emission) and residents (live auto map, schedules, proximity alerts,
complaints, ratings), and a NestJS backend owning all domain logic and contracts. Positions
flow driver → MQTT (EMQX) → ingest → Redis (live) + TimescaleDB (history) → WebSocket
fan-out to residents and geofence-triggered FCM alerts. The existing pre-pivot scaffold is
partially retired per research R13 (Expo app and Supabase-direct access removed; Next.js
portal and the shared contracts package retained).

## Technical Context

**Language/Version**: TypeScript 5.x strict (Node 22, NestJS) for backend/web/shared;
Dart 3 (Flutter stable 3.x) for mobile

**Primary Dependencies**: NestJS, Kysely + node-pg-migrate, zod + zod-openapi,
openapi-generator (dart-dio), EMQX (MQTT), ws (WebSocket fan-out), firebase-admin (FCM),
Next.js 16 + MapLibre GL JS + mapbox-gl-draw (portal), Flutter: maplibre_gl, riverpod,
dio, geolocator, flutter_foreground_task, mqtt_client, firebase_messaging, drift, intl

**Storage**: PostgreSQL 16 + PostGIS + TimescaleDB (hypertable for pings, 90-day raw
retention); Redis (live positions, geofence sets, OTP, rate limits, dedup);
S3-compatible object store (MinIO dev) for media

**Testing**: Vitest/Jest unit + integration with Testcontainers (Postgres/Redis/EMQX);
`flutter test` + `flutter analyze`; contract-drift check regenerating OpenAPI + Dart client

**Target Platform**: Android 8+ (API 26, 2 GB RAM floor) single APK role-based; modern
browsers for the admin portal; Linux server (containers) for backend

**Project Type**: mobile app + web portal + backend service in one monorepo

**Performance Goals**: device→resident-screen ≤ 3 s p95; geofence→push ≤ 10 s p95; API
p95 < 300 ms; ingest ~1,000 msg/s worst case (spec §6)

**Constraints**: offline-tolerant driver tracking (queue ≤ 5 pings, ordered replay); BYOD
battery-killer hardening; driver PII never in resident responses; zero-cost map tiles (no
public osm.org in production); EN + KN localization; DPDP data residency (ap-south-1)

**Scale/Scope**: ~225 wards, ~4–5k autos, 500k installs, 100k concurrent resident
sessions at peak; MVP = all M-priority requirements (spec §3), S/C deferred to v1.1/v1.2

## Constitution Check

*Gate evaluated against constitution v3.0.0 — pre-research and re-checked post-design.*

| Principle | Verdict | Evidence |
|---|---|---|
| I. Simplicity & Elegance | ✅ | Modular monolith, not microservices; one Redis for four runtime needs; raw SQL over ORM ceremony (R3); infra breadth (Timescale/EMQX/Redis/MinIO) is spec-mandated by NFR-01/03 scale+latency targets, not speculative |
| II. Engineering Discipline | ✅ | TS strict across api/web/shared; Dart strict analyzer + null safety; gates in quickstart §5 (`typecheck`, `lint`, `build`, `flutter analyze/test`) |
| III. Separate Mobile & Web Codebases | ✅ | Flutter in `apps/mobile` (Android launch, iOS later); React+TS portal stays in `apps/web`; zero shared UI code |
| IV. Single Source of Truth for Contracts | ✅ | Zod in `packages/shared` → OpenAPI 3.1 → generated dart-dio client; drift check fails CI (quickstart §5); no hand-written Dart models |
| V. Test What Matters | ✅ | Unit tests on schemas/domain logic; integration coverage of the critical flow (trip → ping → live map → proximity alert) via simulator + Testcontainers |
| Tech Constraints | ✅ | Node/TS backend owns domain logic (no client→DB access remains after R13); Postgres+PostGIS(+Timescale); MapLibre with OpenFreeMap/PMTiles — osm.org dev tiles removed in restructure (R10); pnpm+Turborepo kept, Flutter dir opts out of JS workspace; EN/KN first-class |

**Post-design re-check**: PASS — no violations introduced by Phase 1 design. Complexity
Tracking left empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-waste-collection-tracking/
├── plan.md              # This file
├── research.md          # Phase 0 — 13 resolved decisions (R1–R13)
├── data-model.md        # Phase 1 — entities, invariants, Redis runtime state
├── quickstart.md        # Phase 1 — end-to-end validation guide
├── contracts/
│   ├── api.md           # REST /v1 contract summary (OpenAPI is source artifact)
│   └── realtime.md      # MQTT ingest + WS fan-out + FCM payloads
└── tasks.md             # Phase 2 output (/speckit-tasks — not created here)
```

### Source Code (repository root)

```text
apps/
├── api/                       # NEW — NestJS modular monolith
│   ├── src/
│   │   ├── modules/
│   │   │   ├── auth/          # OTP, register/login, JWT+refresh, guards (role+ward scope)
│   │   │   ├── geo/           # operators, wards, routes, boundary import/validation
│   │   │   ├── fleet/         # autos, drivers, assignments (append-only history)
│   │   │   ├── tracking/      # trips, MQTT/HTTPS ingest, Redis live state, WS fan-out,
│   │   │   │                  #   geofence evaluator, gap/idle watchdogs
│   │   │   ├── notify/        # FCM outbox worker, localization of payloads
│   │   │   └── complaints/    # complaints + events, ratings
│   │   ├── db/                # Kysely setup, generated DB types
│   │   └── openapi/           # zod-openapi emitter
│   ├── migrations/            # node-pg-migrate SQL (ports PostGIS triggers from old scaffold)
│   ├── scripts/               # seed.ts, simulate-trip.ts
│   └── test/                  # unit + Testcontainers integration
├── web/                       # KEPT — Next.js 16 admin portal (repurposed per R7/R13)
│   └── src/app/               # login, wards (draw/import), routes, fleet, review-queue,
│                              #   complaints, live/[wardId] dashboard
└── mobile/                    # REPLACED — Flutter app (Expo scaffold retired)
    ├── lib/src/
    │   ├── api/               # GENERATED dart-dio client (do not edit)
    │   ├── core/              # auth/session, map abstraction (R10), i18n (EN/KN)
    │   ├── driver/            # home, trip runner, foreground tracking, photo queue, wizard
    │   └── resident/          # onboarding (pin-drop), live home map, complaints, ratings
    └── test/

packages/
└── shared/                    # REPURPOSED — contract source (Zod) only; Supabase helpers removed

contracts artifacts: apps/api emits openapi.json → specs/.../contracts/ + Dart regen script
docker-compose.yml             # NEW — timescaledb-ha, redis, emqx, minio
supabase/                      # RETIRED — SQL patterns ported into apps/api/migrations
```

**Structure Decision**: Monorepo retained (pnpm + Turborepo for the three TS workspaces;
`apps/mobile` is a Flutter project with no `package.json`, managed by the `flutter` CLI and
its own CI lane). Disposition of the pre-pivot scaffold follows research R13: Expo app
deleted, `supabase/` retired after porting its PostGIS trigger patterns into
`apps/api/migrations`, `packages/shared` keeps only contract schemas, `apps/web` is
repurposed as the admin portal (public black-spot map removed — old product). README must
be rewritten as part of the restructure (flagged in constitution v3.0.0 sync report).

## Complexity Tracking

No constitution violations to justify — table intentionally empty.
