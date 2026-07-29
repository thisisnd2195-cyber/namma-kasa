# Operations

Running Namma Kasa locally, deploying it, and what to do when something looks
wrong. For how the system is put together see [architecture.md](./architecture.md).

## Local environment

### Services

`docker compose up -d` brings up four containers.

| Service | Host port | Notes |
|---|---|---|
| PostgreSQL 16 + PostGIS + TimescaleDB | **5433** → 5432 | Not 5432: a Homebrew Postgres commonly owns that |
| Redis | 6379 | Dedup claims, live state, degradation level |
| EMQX | 1883 (MQTT), 18083 (dashboard) | Anonymous access is **off** |
| MinIO | 9000 (API), 9001 (console) | Stands in for S3 |

All ports are overridable via `.env` (`POSTGRES_PORT`, `REDIS_PORT`,
`MQTT_PORT`, `EMQX_DASHBOARD_PORT`, `MINIO_PORT`, `MINIO_CONSOLE_PORT`).

Docker itself runs under **Colima**, not Docker Desktop, whose installer needs an
interactive sudo password:

```sh
colima start
```

### First run

```sh
pnpm install
cp .env.example .env
docker compose up -d
pnpm --filter @namma-kasa/api migrate
pnpm --filter @namma-kasa/api seed     # prints dev logins
```

### Running

```sh
pnpm --filter @namma-kasa/api dev      # :4000
pnpm --filter @namma-kasa/web dev      # :3000
cd apps/mobile && flutter run --dart-define=API_BASE=http://<LAN-IP>:4000/v1
```

Use your **LAN IP**, not `localhost`, for the mobile app — the phone or emulator
resolves `localhost` to itself.

### Dev accounts

| Role | Phone | Password |
|---|---|---|
| Super admin | 919000000001 | `devpassword` |
| Ward admin | 919000000002 | `devpassword` |
| Residents | 919888800001–3 | `devpassword` |
| Driver (pre-provisioned, no account) | 919999900001 | register in the app |

SMS is not wired locally. `OTP_SENDER=console` prints codes to the API log as
`[dev-otp] <phone> <code>`.

## Migrations

Raw SQL under `apps/api/migrations/`, applied by `node-pg-migrate`, named
`<epoch-ms>_<slug>.sql` with `-- Up Migration` / `-- Down Migration` sections.

```sh
pnpm --filter @namma-kasa/api migrate        # apply all pending
pnpm --filter @namma-kasa/api migrate:down   # roll back one
```

**Run `pnpm migrate` with no extra arguments.** `pnpm migrate up` passes a second
`up` that node-pg-migrate parses as a step count, silently applying nothing and
still printing "Migrations complete!".

Two constraints when writing one:

- Geometry invariants belong in triggers, not services. A migration that adds a
  geographic rule should enforce it in the database.
- Postgres cannot remove a value from an enum. `ALTER TYPE ... ADD VALUE` is
  one-way; say so in the Down section rather than pretending otherwise.

## Verification gates

Everything below must pass before a merge.

```sh
pnpm typecheck && pnpm lint && pnpm build
pnpm contracts:check                              # OpenAPI in sync + every route documented
pnpm --filter @namma-kasa/api test                # 143 tests, needs Postgres/Redis/EMQX/MinIO
pnpm --filter @namma-kasa/api coverage            # line coverage by file
cd apps/mobile && flutter analyze && flutter test # 28 tests
```

The API tests run against **live infrastructure**, not mocks, and share one
database. A spec that mutates shared fixtures must snapshot and restore them —
`test/dashboards.spec.ts` shows the pattern for route collection windows.

`flutter analyze` excludes the generated API package. Only `flutter test`
compiles it, so analyze alone will not catch a broken client.

## Deployment

Pilot runs on a single managed environment in **ap-south-1** with
provider-managed backups. This is a deliberate deferral recorded in the spec:
full infrastructure-as-code (Terraform), blue-green deploys and PITR are
required before city rollout, not before pilot.

Deploy order matters, because the contract is generated:

1. Apply migrations. They are written to be backward compatible with the running
   version, so this happens first.
2. Deploy the API.
3. Deploy the portal.
4. Ship the mobile build. Older app versions must keep working — the app is not
   force-updated, so a contract change that breaks them is a breaking change.

### Environment

Required in production beyond the local defaults:

| Variable | Purpose |
|---|---|
| `DATABASE_URL`, `REDIS_URL`, `MQTT_URL` | Connections |
| `JWT_SECRET` | Signs access, refresh, and MQTT ACL tokens |
| `MQTT_USERNAME` / `MQTT_PASSWORD` | The ingest consumer's own broker credentials |
| `S3_ENDPOINT`, `S3_BUCKET`, `S3_ACCESS_KEY`, `S3_SECRET_KEY` | Media |
| `OTP_SENDER` | `console` locally; a real gateway in production |
| `PUSH_SENDER` | `fcm` to enable real push; anything else logs |

`config.schema.ts` validates these at boot. A missing required variable fails
startup rather than surfacing later as a confusing runtime error.

## Monitoring

`GET /v1/metrics` is a public Prometheus scrape target. It carries no personal
data, which is why it is the single deliberate exclusion from contract coverage.

What to watch, and why:

| Signal | Meaning |
|---|---|
| Notification outbox depth | Alerts queued but undelivered. Growth means push is failing |
| Notification latency p50/p95 | Budget is **≤ 10 s p95** from geofence hit (FR-NOTIF-05) |
| Per-ward trip stats | Active and completed trips; a ward at zero mid-window is a real problem |
| Tracking-dropped alerts | Driver devices that have gone silent |

## Runbook

### Residents report the auto's position is stale or missing

Check in this order:

1. **Is the trip active?** A completed or aborted trip stops emitting. Pings for
   an ended trip are dropped deliberately, so as not to resurrect it.
2. **Is the driver's device reporting?** A gap over **3 minutes** raises a
   tracking-dropped alert on the ward dashboard (`/live`).
3. **Is the live stream shed?** Check `degradation:level` in Redis. At level 1
   cadence stretches to 10 s; at 2 sockets are closed entirely and the app falls
   back to polling. This is designed behaviour under load, not a fault.
4. **Is the socket rejecting?** The upgrade needs both a valid token and a
   `route_id` the token's claims permit. A resident re-mapped to a new route
   carries a stale `routeId` until their access token rotates, within 15 minutes.

### A driver's phone stops reporting when the screen sleeps

Almost always the OEM battery manager, not the app. The first-run wizard shows
manufacturer-specific steps (`apps/mobile/lib/src/driver/oem_steps.dart`), but a
driver who dismissed it will not see them again automatically. Xiaomi, Oppo,
Vivo, realme and Transsion devices each need an Autostart or background-activity
toggle beyond Android's standard battery-optimisation exemption.

### Alerts are not arriving

1. Outbox depth rising with latency flat → the drain worker is stuck. It runs
   every 1 s in-process; restart the API.
2. Outbox flat and empty → the geofence is not hitting. Confirm the household
   has a `route_id` and that its user is `active`; both are required.
3. A resident gets one alert then silence for the rest of the day → working as
   designed. Dedup is per household per **pass**, and the claim outlives the
   collection day.
4. Nothing at all in production → `PUSH_SENDER` is not `fcm`, or FCM credentials
   are absent. See Known gaps.

### An admin action did not take effect

`audit_log` records every successful admin mutation with actor, entity, action
and timestamp. Reads are not logged. If there is no row, the request did not
succeed — check the API log for a 4xx.

### Trips are ending on their own

By design, on a ladder:

| Threshold | Behaviour |
|---|---|
| 3 min without a ping | "Tracking dropped" alert on the ward dashboard |
| 30 min without movement | Driver is prompted to confirm they are still collecting |
| 45 min unreachable | Trip force-ends as `auto_idle` |

The watchdog sweeps every 30 s.

### Ingest is rejecting pings

`IngestService` drops a ping when its sequence is at or below the highest already
accepted for that trip, when accuracy is worse than **100 m**, or when it implies
more than **60 km/h** judged over a rolling 3-ping window. Batches are capped at
20. Rejections are counted in the ingest result — they are not errors, and a
device replaying a spool after a dead zone will legitimately produce some.

## Data retention and DPDP

| Data | Retention |
|---|---|
| Raw GPS pings | 90 days |
| Collection evidence (`household_collections`) | Kept — it outlives the raw trail |
| Media | 180 days, extended while attached to an open complaint |
| Account after deletion request | Erased after a 30-day grace period |

Erasure is self-service via `DELETE /v1/me`. Personal fields are removed and the
row is tombstoned so the ward's collection history stays whole — the
`users_credential_present` constraint exempts tombstoned rows for exactly this
reason.

## Known gaps

Two features are implemented server-side but cannot be finished without
credentials:

- **Push notifications (T066)** need a Firebase project. Alerts queue correctly
  and the outbox drains, but with `PUSH_SENDER` unset no device receives them.
- **Google Sign-In (T074)** needs an OAuth client id. The `/auth/login` Google
  path exists and works; the mobile app cannot initiate it.

**Sahaaya 2.0 sync (FR-CMP-04) is a seam, not an integration.** BBMP has
published no contract, so the feature flag, the BBMP-only eligibility rule and
the call site are real, and the transport logs. A live client is one
`SahaayaClient` implementation away with no caller changes.
