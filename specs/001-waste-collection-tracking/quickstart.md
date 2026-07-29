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
