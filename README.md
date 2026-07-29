# Namma Kasa — ನಮ್ಮ ಕಸ

Live tracking of door-to-door waste collection in Bengaluru.

Residents stop waiting at the gate, because the app tells them when the collection
auto is close. Operators stop being able to claim service that did not happen,
because every trip leaves a GPS trail that says otherwise.

## Stack

| Layer | Tech |
|---|---|
| Mobile (Android) | Flutter — `apps/mobile` |
| Admin portal | Next.js + React + Tailwind — `apps/web` |
| Backend | NestJS modular monolith — `apps/api` |
| Contracts | Zod → OpenAPI → generated Dart client — `packages/shared`, `contracts/` |
| Data | PostgreSQL 16 + PostGIS + TimescaleDB, Redis |
| Realtime | MQTT (EMQX) ingest, WebSocket fan-out, FCM push |
| Maps | MapLibre + OpenFreeMap tiles |

The backend owns the contract: Zod schemas generate the OpenAPI document, which
generates the Flutter client. `pnpm contracts:check` fails the build if they drift.

## Prerequisites

```sh
brew install colima docker docker-compose openjdk   # openjdk is only needed to regenerate the Dart client
brew install --cask flutter
npm i -g pnpm
```

Colima replaces Docker Desktop, whose installer needs an interactive sudo password.

## Getting started

```sh
pnpm install
colima start                                  # boots the Docker VM
cp .env.example .env
docker compose up -d                          # postgres+postgis+timescale, redis, emqx, minio

pnpm --filter @namma-kasa/api migrate
pnpm --filter @namma-kasa/api seed             # prints dev logins

pnpm --filter @namma-kasa/api dev              # API on :4000
pnpm --filter @namma-kasa/web dev              # portal on :3000
cd apps/mobile && flutter run --dart-define=API_BASE=http://<LAN-IP>:4000/v1
```

Postgres is published on **5433**, not 5432, because a host Postgres commonly
occupies the default port.

### Dev accounts (created by the seed)

| Role | Phone | Password |
|---|---|---|
| Super admin | 919000000001 | devpassword |
| Ward admin | 919000000002 | devpassword |
| Residents | 919888800001–3 | devpassword |
| Driver (pre-provisioned, no account) | 919999900001 | register in the app |

SMS is not wired in development: `OTP_SENDER=console` prints codes to the API log
as `[dev-otp] <phone> <code>`.

## Repo layout

```
apps/api        NestJS: auth, geo (wards/routes/households), fleet, + tracking/notify/complaints to come
apps/web        Admin portal: wards, routes, fleet, review queue
apps/mobile     Flutter app: resident and driver, single binary
packages/shared Zod contracts, shared by API and portal
contracts/      Generated OpenAPI document (committed)
```

## Commands

```sh
pnpm typecheck && pnpm lint && pnpm build   # TS workspaces
pnpm --filter @namma-kasa/api test          # 43 tests against live Postgres/Redis
pnpm contracts:check                        # fails if OpenAPI drifts from the Zod schemas
pnpm contracts:generate                     # regenerate OpenAPI + Dart client
cd apps/mobile && flutter analyze && flutter test
```

## Status

Built: infrastructure, database schema with geo invariants enforced in triggers,
auth (OTP, password/Google, rotating refresh, driver pre-provisioning), authorization
with ward scoping and audit logging, and the full ward/route/fleet admin surface with
its portal UI.

Next: driver trip tracking with GPS ingest, the resident live map, proximity
notifications, and complaints. See `specs/001-waste-collection-tracking/tasks.md`.
