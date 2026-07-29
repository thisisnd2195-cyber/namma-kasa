# Quickstart & Validation Guide

**Feature**: 001-waste-collection-tracking. Proves the MVP works end-to-end on a dev machine.
Contracts: [contracts/api.md](contracts/api.md), [contracts/realtime.md](contracts/realtime.md).
Entities: [data-model.md](data-model.md).

## Prerequisites

| Tool | Check | Note |
|---|---|---|
| Node ≥ 22 + pnpm | `pnpm --version` | installed |
| Docker Desktop | `docker compose version` | **not yet installed on this machine** |
| Flutter SDK (stable) | `flutter doctor` | **not yet installed on this machine** |
| Android device/emulator | `flutter devices` | Android 8+ |

## 1. Infrastructure up

```sh
docker compose up -d        # timescaledb(+postgis), redis, emqx, minio
pnpm --filter @namma-kasa/api migrate   # node-pg-migrate: schema + triggers
pnpm --filter @namma-kasa/api seed      # 1 operator, 1 ward, 1 route, 1 auto,
                                        # 1 driver (phone 9999900001), households
```

**Expected**: migrations apply cleanly; seed prints the ward/route ids and the driver's
pre-provisioned phone.

## 2. Backend + web portal

```sh
pnpm --filter @namma-kasa/api dev       # NestJS on :4000 (REST, WS, MQTT consumers)
pnpm --filter @namma-kasa/web dev       # admin portal on :3000
```

**Validate (Story 1 — admin setup)**:
- Log in to the portal as the seeded Super Admin; the seeded ward renders with its boundary.
- Import `fixtures/wards-sample.geojson` → wards appear; re-importing an overlapping polygon
  is rejected with the conflict highlighted (FR-WARD-05).
- As the seeded Ward Admin: create a route by drawing an area inside the ward (drawing a
  polygon crossing the ward edge → 422); assign auto → route and driver → auto; the
  assignment history table shows effective-from timestamps.

## 3. Mobile app

```sh
cd apps/mobile
flutter pub get
flutter run --dart-define=API_BASE=http://<LAN-IP>:4000
```

**Validate (Story 2 — driver)**:
- Register as driver with the seeded phone (dev OTP is printed to the API console).
  Registering with any other number is refused (FR-AUTH-05).
- Home shows auto, route area, window, "Pass 0 of 1". Start trip → persistent tracking
  notification appears.

**Validate (Story 3 — resident)**:
- Register as a resident; drop the pin inside the seeded route area → auto-mapped; drop it
  outside every route → "pending review" and the household appears in the portal review
  queue (FR-AUTH-08).

## 4. End-to-end tracking without a vehicle

```sh
pnpm --filter @namma-kasa/api simulate-trip -- --route <route_id> \
  --trail fixtures/trail-route1.geojson --speed 12
```

The simulator starts a trip as the seeded driver and replays the GPS trail over MQTT.

**Expected**:
- Resident home: auto marker appears and moves smoothly; screen lag vs. simulator log
  ≤ 3 s (SC-004).
- When the trail passes within the household radius: exactly one FCM proximity alert,
  within 10 s (SC-005); re-approaching sends nothing (FR-NOTIF-02).
- Portal live map shows the moving auto (FR-DASH-01). Kill the simulator mid-trip → after
  3 min the portal shows a "tracking dropped" alert (FR-DRV-05).
- Trip ends (simulator completion or 30-min idle auto-end) → resident sees
  "last collected" update; rating prompt allows one rating; a second rating attempt → 409
  (FR-CMP-05).

**Validate (Story 5 — complaints)**:
- File a complaint with a photo from the resident app → appears in the portal; move it
  open → in_review → resolved → resident sees history and receives a status notification
  (FR-CMP-02, FR-NOTIF-04).

## 5. Automated gates (must be green before merge — constitution)

```sh
pnpm typecheck && pnpm lint && pnpm build   # TS workspaces
pnpm --filter @namma-kasa/api test          # unit + integration (Testcontainers)
cd apps/mobile && flutter analyze && flutter test
```

Contract drift check: `pnpm contracts:check` regenerates `contracts/openapi.json` and the
Dart client and fails if the working tree changes (Principle IV).


## Verification record (2026-07-29)

Run on an Apple Silicon laptop, Colima VM (4 CPU / 6 GB), against the Compose stack.

| Check | Result |
|---|---|
| Migrations + geo invariants | 23 tables, 17 enums, hypertable, 6 partial-unique indexes; overlapping/nested wards and routes rejected |
| Ward import (US1) | 1 accepted, 1 rejected with the conflicting ward named |
| Assignment history (US1) | Reassignment closed the prior row, left exactly one open |
| Ward scoping (US1) | Own ward 200, other ward 403, super-admin-only endpoint 403 |
| GPS ingest (US2) | 158/158 MQTT pings persisted over the **authenticated** broker, 2.6 km trail |
| Collection events (US3) | All 3 route households recorded as the auto passed within 75 m |
| Proximity alerts (US4) | 3 households, 1 alert each, Kannada resident received Kannada copy |
| Complaint evidence (US5) | Admin queue showed "served that day = true, last collected 09:38" |
| Ingest load | 150 autos at 1 Hz: 149.7 pings/sec accepted, p50 35 ms, p95 83 ms, p99 103 ms |
| Metrics | Per-ward active trips, trips today, skipped passes, outbox depth |
| Tests | 84 API, 12 Flutter; `flutter analyze`, typecheck, lint, build, contract drift all clean |

Broker authentication is on: the ingest consumer authenticates from
`docker/emqx/auth-bootstrap.csv`, and devices present a per-trip JWT whose `acl`
claim is enforced (`ACL_CLAIM_NAME`) with `DENY_ACTION=disconnect`. Six broker
tests cover both directions, including that a valid token cannot publish to
another trip's topic.

Changing `docker-compose.yml` requires `docker compose up -d --force-recreate
<service>`; a plain `up -d` leaves an existing container on its old config,
which is how a broker change once appeared to pass while never being applied.

The load figure is cadence-limited rather than a saturation point: the useful
number is the per-ping cost (p95 83 ms), which is what to extrapolate the
SC-006 target of ~1000 pings/sec from. A real saturation run belongs on
production-shaped hardware.
