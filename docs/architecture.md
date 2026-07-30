# Architecture

How Namma Kasa is put together, and why. For setup and day-to-day operation see
[operations.md](./operations.md); for the requirements this implements see
[`specs/001-waste-collection-tracking/spec.md`](../specs/001-waste-collection-tracking/spec.md).

**Diagrams** — [system context](#system-context) ·
[module graph](#module-graph) ·
[the path a GPS ping takes](#the-path-a-gps-ping-takes) ·
[contract pipeline](#contract-pipeline) ·
[data model](#data-model) ·
[trip lifecycle](#trip-lifecycle) ·
[complaint lifecycle](#complaint-lifecycle) ·
[deployment](#deployment) ·
[trust boundaries](#trust-boundaries) ·
[surviving a dead zone](#surviving-a-dead-zone)

All ten are Mermaid, so they render on GitHub and stay diffable in review.
`pnpm diagrams:check` renders each one to prove it parses — a diagram that looks
right in a code fence is exactly as verified as a route that typechecks.

## The problem shape

Two facts drive every decision below.

**Residents wait.** Door-to-door collection has no timetable a resident can rely
on, so they either stand at the gate or miss the auto. Fixing that needs a live
position, pushed, with enough warning to walk down — not a map they must open.

**Operators cannot currently be held to account.** "We came" and "you did not"
are unfalsifiable claims. Every trip therefore leaves a GPS trail, and a
complaint is answered by that trail rather than by argument.

The second fact is why ingest is protected above everything else: losing a ping
loses evidence.

## System context

```mermaid
graph TB
    resident["Resident<br/>(Flutter, Android)"]
    driver["Driver<br/>(Flutter, Android)"]
    admin["Ward / Super Admin<br/>(Next.js portal)"]

    api["apps/api<br/>NestJS modular monolith"]

    emqx["EMQX<br/>MQTT broker"]
    pg[("PostgreSQL 16<br/>PostGIS + TimescaleDB")]
    redis[("Redis<br/>dedup, live state, degradation")]
    s3[("S3 / MinIO<br/>collection photos")]
    fcm["Firebase Cloud Messaging"]

    driver -- "GPS pings, QoS 1" --> emqx
    driver -- "HTTPS fallback when MQTT is unreachable" --> api
    emqx --> api

    resident -- "REST + WebSocket /v1/live" --> api
    admin -- "REST" --> api

    api --> pg
    api --> redis
    api --> s3
    api -- "proximity + arrival alerts" --> fcm
    fcm --> resident
```

The backend is a **modular monolith**, not services. At pilot scale — one city,
~225 wards, a few thousand autos — the coordination cost of services buys
nothing, and the ingest path benefits from being a single process that can hand a
position to the geofence without a network hop. The module boundaries are real
(`apps/api/src/modules/*`), so splitting later is a refactor rather than a
rewrite.

### Module graph

The boundaries are real, and their direction is load-bearing.

```mermaid
graph TD
    subgraph platform[" "]
        Db[(DbModule)]
        Redis[(RedisModule)]
    end

    Auth[AuthModule]
    Geo[GeoModule]
    Fleet[FleetModule]
    Tracking[TrackingModule]
    Notify[NotifyModule]
    Complaints[ComplaintsModule]
    Issues[IssuesModule]
    Resident[ResidentModule]
    Compliance[ComplianceModule]

    Auth --> Geo
    Tracking --> Auth
    Notify --> Tracking
    Complaints --> Notify
    Issues --> Auth
    Issues --> Notify
    Resident --> Geo
    Resident --> Tracking
    Resident --> Compliance

    Db -.-> Auth
    Db -.-> Geo
    Redis -.-> Tracking

    classDef infra fill:#F6F6F8,stroke:#9CA3AF,color:#6B7280
    class Db,Redis infra
```

**`NotifyModule` importing `TrackingModule` is the constraint everything else
bends around.** Ingest emits positions, the geofence consumes them, so notify
must depend on tracking and never the reverse. That is why driver quick-reports
live in their own `IssuesModule`: the feature needs `NotifyService`, and putting
it in `TrackingModule` would have closed a cycle.

`ResidentModule` imports `ComplianceModule` for `RollupsService` — which
`ComplianceModule` must therefore **export**. It did not, for three phases, and
the API could not start; nothing caught it because no test had ever called
`NestFactory.create`. `test/http*.spec.ts` now boots the real container.

## The path a GPS ping takes

This is the product. Everything else is administration around it.

```mermaid
sequenceDiagram
    participant App as Driver app
    participant Spool as PingSpool (device)
    participant EMQX
    participant Consumer as MqttConsumer
    participant Ingest as IngestService
    participant PG as Postgres
    participant Live as LiveGateway
    participant Geo as GeofenceService
    participant Out as notifications outbox
    participant Res as Resident

    App->>Spool: position every 5 s or 25 m
    Note over Spool: survives dead zones,<br/>replayed in seq order
    Spool->>EMQX: PUBLISH trips/{tripId}/pings (QoS 1)
    Note over EMQX: JWT ACL grants pub to<br/>exactly this one topic
    EMQX->>Consumer: SUBSCRIBE trips/+/pings
    Consumer->>Ingest: contextFor(tripId) → ingest(batch)

    Note over Ingest: drops seq ≤ last seen,<br/>accuracy worse than 100 m,<br/>over 60 km/h across 3 pings
    Ingest->>PG: INSERT location_pings (hypertable)

    par live map
        Ingest->>Live: onPosition
        Live->>Res: WS frame, ≤ 1 per trip per 2 s
    and proximity
        Ingest->>Geo: onPosition
        Geo->>Geo: ST_DWithin per household radius
        Geo->>Out: queue, deduped per household per pass
        Out->>Res: FCM push (drained every 1 s)
    and evidence
        Ingest->>PG: household_collections within 75 m
    end
```

Three design points worth stating explicitly:

**The spool is unbounded for the trip's duration.** A driver through a dead zone
must not lose the trail, because the trail is the evidence. Replay is in
sequence order, and the server drops anything at or below the highest sequence
it has already accepted for that trip.

**Dedup is per household per *pass*, not per trip.** Two autos can serve one
pass of a route, and a resident should be told once that collection is coming,
not once per vehicle. The claim is a Redis `SET NX` that outlives the collection
day.

**The two alert rings are independent.** The proximity heads-up uses each
household's own radius (100–1000 m, default 300 m); the "arrived at your street"
alert uses a fixed 75 m. They hold separate dedup keys — sharing one would mean
whichever fired first silently suppressed the other.

## Contract pipeline

The backend owns the contract. This is Constitution Principle IV, and it is
enforced by the build rather than by convention.

```mermaid
graph LR
    zod["packages/shared<br/>Zod schemas"]
    doc["contracts/openapi.json<br/>OpenAPI 3.1"]
    dart["apps/mobile/packages/<br/>namma_kasa_api (generated Dart)"]
    web["apps/web<br/>imports Zod types directly"]
    routes["Nest routes<br/>(decorator metadata)"]

    zod -- "zod-openapi" --> doc
    doc -- "openapi-generator" --> dart
    zod --> web
    routes -. "contracts:coverage<br/>fails on any undocumented route" .-> doc
```

Two guards run in `pnpm contracts:check`:

- **`contracts:check`** regenerates the document and diffs it, so a changed Zod
  schema without a regenerated contract fails.
- **`contracts:coverage`** enumerates the routes Nest actually serves by reading
  decorator metadata, and fails if one is missing from the document. This exists
  because the first guard only compared the document to its own generator — 45
  of 50 routes were undocumented while it reported success.

Currently **49 path templates covering 56 routes**, with 1 deliberate exclusion
(`GET /v1/metrics`, the Prometheus scrape target).

Hand-editing anything under `apps/mobile/packages/namma_kasa_api` is a defect.
Change the Zod schema and run `pnpm contracts:generate`.

### Generator constraints

The `dart` generator emits uncompilable code for several valid OpenAPI shapes,
so the published document is deliberately looser than runtime validation in
three places — a record of enum arrays, an enum carrying a default, and 4-deep
GeoJSON coordinate arrays. `packages/shared` still validates strictly. The
mobile client is also generated from an admin-stripped view of the spec, since
the app is a resident and driver client and never calls `/admin`.

`flutter analyze` **excludes** the generated package. Only `flutter test`
compiles it, so analyze passing says nothing about whether generated code builds.

## Data model

22 application tables. The core of it:

```mermaid
erDiagram
    operators ||--o{ wards : runs
    wards ||--o{ routes : contains
    wards ||--o{ autos : "based in"
    wards ||--o{ drivers : "provisioned in"
    routes ||--o{ households : serves
    routes ||--o{ trips : "executed by"

    autos ||--o{ auto_route_assignments : "assigned via"
    routes ||--o{ auto_route_assignments : ""
    drivers ||--o{ driver_auto_assignments : "assigned via"
    autos ||--o{ driver_auto_assignments : ""

    trips ||--o{ location_pings : trail
    trips ||--o{ household_collections : proves
    trips ||--o{ media_uploads : "photo proof"
    households ||--o{ household_collections : "served by"
    households ||--o{ complaints : raises
    households ||--o{ ratings : gives

    users ||--o| households : "resident of"
    users ||--o| drivers : "account for"
    complaints ||--o{ complaint_events : "status history"
```

**Geometry is enforced in the database, not the service layer.** Ward boundaries
may not overlap, route serviceable areas may not overlap within a ward, and a
route must sit inside its ward. These are triggers, so a bug in an endpoint
cannot corrupt the geography.

The overlap check uses `ST_Relate(a, b, 'T********')` rather than `ST_Overlaps`,
because `ST_Overlaps` is false when one polygon wholly contains another — which
is exactly the case an admin most needs rejecting.

**Assignments are time-bounded and never rewritten.** `effective_from` /
`effective_to` with a partial unique index on the open row. A reassignment
closes the current row and opens a new one, so history stays reconstructable
(SC-010).

**`location_pings` is a TimescaleDB hypertable** partitioned by `recorded_at`,
holding plain `lat`/`lng` doubles rather than a geometry column. Raw pings are
dropped after 90 days; the derived `household_collections` evidence is not.

## Load shedding

Under pressure the live map degrades before anything else, because a resident
can refresh a map but cannot recover a lost alert or a lost trail.

| Level | Name | Effect |
|---|---|---|
| 0 | `normal` | Everything on; live frames every 2 s |
| 1 | `slowLive` | Live cadence stretches to 10 s |
| 2 | `pauseLive` | Resident sockets closed; app falls back to polling |
| 3 | `minimal` | Admin dashboards drop to counts only |

Ingest and notifications are never shed. The level lives in Redis
(`degradation:level`) and the gateway re-reads it on a 30 s heartbeat, so the
hot path never awaits Redis per frame.

## Authorization

Three enforcement points, deliberately different in kind:

- **Route guards** — role checks plus a `WardScopeGuard` that pins a Ward Admin
  to their own ward server-side (FR-WARD-06). The portal's client-side gate is
  cosmetic; the API rejects regardless.
- **Broker ACL** — a driver's MQTT token carries `acl.pub` granting exactly one
  topic, `trips/{tripId}/pings`. A compromised device can publish to one trip.
  EMQX is configured `NO_MATCH: deny` with `DENY_ACTION: disconnect`.
- **WebSocket upgrade** — a resident may only subscribe to the route their own
  household sits on. This is a JWT claim comparison rather than a broker rule,
  because it is far easier to audit.

Access tokens live 15 minutes with rotating refresh tokens. Sockets outlive
tokens, so they are cycled after 60 minutes with a `reauth` frame.

Residents never receive driver personal details — only the auto's registration
number and its position (FR-RES-07, a DPDP obligation).

## Trip lifecycle

A trip is the unit of evidence, so how it ends matters as much as how it runs.

```mermaid
stateDiagram-v2
    [*] --> active: driver starts pass n
    note right of active
        Requires pass n-1 completed,
        aborted, or auto-skipped (FR-DRV-02)
    end note

    active --> completed: driver ends trip
    active --> completed: watchdog force-end at 45 min
    active --> aborted: admin intervention

    completed --> [*]
    aborted --> [*]
```

The watchdog sweeps every 30 s and escalates rather than jumping straight to
force-ending, because a silent phone and an abandoned auto look identical from
the server:

| Elapsed | Signal | Who sees it |
|---|---|---|
| 3 min without a ping | "Tracking dropped" | Ward dashboard |
| 30 min without movement | Confirmation prompt | Driver's phone |
| 45 min unreachable | Force-end as `auto_idle` | Recorded on the trip |

`route_pass_days` tracks each pass separately (`pending → active → completed /
aborted / skipped`), and a pass whose window elapses unstarted is marked
`skipped` so the next pass is not blocked forever.

## Complaint lifecycle

```mermaid
stateDiagram-v2
    [*] --> open: resident files
    open --> in_review: admin picks it up
    open --> resolved
    open --> rejected
    in_review --> resolved
    in_review --> rejected
    resolved --> [*]
    rejected --> [*]
```

Transitions are enforced server-side — `resolved` and `rejected` are terminal, so
a closed complaint cannot be reopened to game the SLA clock. `sla_due_at` is
stamped **at creation** from the owning operator's configured hours, not derived
on read, so a later policy change cannot silently re-date complaints raised under
the old one. Breach and escalation are computed in SQL against one clock rather
than the browser's.

Every complaint carries the GPS verdict for the day it was raised, so
"we did come" is settled by the trail rather than by argument.

## Deployment

```mermaid
graph TB
    subgraph dev["Local development"]
        direction LR
        colima["Colima VM"]
        pg[("postgres :5433<br/>PostGIS + TimescaleDB")]
        rd[("redis :6379")]
        eq["emqx :1883 / :18083"]
        mn[("minio :9000 / :9001")]
        colima --- pg
        colima --- rd
        colima --- eq
        colima --- mn
    end

    subgraph pilot["Pilot — ap-south-1, single managed environment"]
        direction LR
        api2["API<br/>(Nest, one process)"]
        pg2[("Managed Postgres<br/>provider backups")]
        rd2[("Managed Redis")]
        eq2["EMQX"]
        s3[("S3")]
        api2 --- pg2
        api2 --- rd2
        api2 --- eq2
        api2 --- s3
    end

    dev -.->|"same compose topology"| pilot
```

Postgres is published on **5433** locally because a Homebrew Postgres commonly
owns 5432. Infrastructure-as-code, blue-green deploys and PITR are deliberately
deferred past pilot — required before city rollout, not before the first ward.

Deploy order is fixed by the generated contract: **migrations → API → portal →
mobile build**. Older app versions must keep working, so a contract change that
breaks them is a breaking change.

## Trust boundaries

Authorization is enforced in three different places, deliberately in three
different ways.

```mermaid
graph LR
    subgraph device["Untrusted"]
        app["Resident / Driver app"]
        portal["Admin portal"]
    end

    subgraph edge["Enforcement"]
        guards["AuthGuard → RateLimitGuard<br/>→ WardScopeGuard<br/>(global, in order)"]
        acl["EMQX JWT acl claim<br/>NO_MATCH deny"]
        ws["WebSocket upgrade<br/>claims.routeId comparison"]
    end

    subgraph trusted["Trusted"]
        svc["Services"]
        audit[("audit_log")]
    end

    portal -->|"REST + Bearer"| guards
    app -->|"REST + Bearer"| guards
    app -->|"MQTT + per-trip JWT"| acl
    app -->|"WS + Bearer"| ws

    guards --> svc
    acl --> svc
    ws --> svc
    svc -.->|"every admin mutation"| audit
```

- **Route guards** run globally in order: authenticate, rate-limit, then scope a
  Ward Admin to their own ward. The portal's own gate is cosmetic.
- **Broker ACL** grants a driver's token publish rights to exactly one topic,
  `trips/{tripId}/pings`. A compromised device can publish to one trip, and EMQX
  disconnects on any other topic rather than silently dropping.
- **WebSocket upgrade** compares a JWT claim instead of consulting broker rules,
  because a claim comparison is far easier to audit.

Residents never receive driver personal details — only the auto's registration
number and its position (FR-RES-07, a DPDP obligation).

## Surviving a dead zone

The trail is the evidence, so the app is built to lose none of it.

```mermaid
sequenceDiagram
    participant GPS as Device GPS
    participant Spool as PingSpool
    participant Net as MQTT / HTTPS
    participant API

    GPS->>Spool: position every 5 s or 25 m
    Spool->>Net: publish batch (max 20)
    Net->>API: accepted
    API-->>Spool: ack

    Note over Net: coverage lost
    GPS->>Spool: positions keep accumulating
    Spool->>Net: publish fails
    Note over Spool: nothing dropped, unbounded<br/>for the trip's duration

    Note over Net: coverage returns
    Spool->>Net: replay oldest first, in seq order
    Net->>API: accepted
    API-->>Spool: ack up to highest seq
    Note over Spool: entries at or below<br/>that seq are released
```

The server drops any ping whose sequence is at or below the highest it has
already accepted for that trip, so a QoS-1 redelivery or an over-eager replay
costs nothing. That per-trip ceiling lives in Redis and **outlives a test run** —
a suite whose sequence numbers restart lower has every ping dropped in silence.

## Where things live

```
apps/api/src/modules/
  auth        OTP, password/Google, rotating refresh, driver pre-provisioning
  geo         wards, routes, households, operators, mapping
  fleet       autos, drivers, time-bounded assignments
  tracking    trips, MQTT + HTTPS ingest, live gateway, media, watchdog
  notify      geofence, notification outbox, push, advisories
  complaints  complaints, ratings, SLA, Sahaaya seam
  issues      driver quick-reports (breakdown, road blocked)
  compliance  DPDP erasure, retention, Prometheus metrics, dashboards

apps/web/src/app/     portal: dashboard, wards, routes, fleet, live,
                      review-queue, complaints
apps/mobile/lib/src/  resident/ and driver/ surfaces, shared core/
packages/shared/      Zod contracts — the single source of truth
contracts/            generated OpenAPI document (committed)
```

## Testing posture

Constitution V requires integration coverage of trip tracking and proximity
notification end-to-end before release. `apps/api/test/end-to-end.spec.ts` is
that gate: it publishes over MQTT exactly as `trip_tracker.dart` does and
asserts both the resident's WebSocket frame and the queued alert.

`apps/api/test/http*.spec.ts` boot the real `AppModule` and drive it over HTTP,
so controllers, guards, the validation pipe and the audit interceptor execute
against real requests. That matters because authorization lives there: a service
that refuses correctly is no use if the route never reaches it. Booting the app
in a test immediately found a module that had never been exported, which meant
the API could not start — after 172 tests, a clean typecheck, lint, build and
contract check had all passed.

Run `pnpm --filter @namma-kasa/api coverage` for the current picture (~86% lines).
Coverage is a script rather than an ad-hoc command because reading code for these
gaps failed repeatedly — several defects were found only by measuring what the
tests actually execute, including one endpoint that had never worked at all.

Two things about the test harness, both load-bearing:

- `unplugin-swc` is in `vitest.config.ts` because Nest resolves constructor
  dependencies from `design:paramtypes`, which esbuild does not emit. Without it
  every injected dependency is `undefined`.
- `@namma-kasa/shared` is aliased to its source rather than its CJS `dist`. Left
  as dist it loads a second copy of zod, so a `ZodError` from a shared schema is
  not an instance of the one `ProblemFilter` checks, and every validation failure
  renders 500 instead of 422 — under test only.

Two things that make test failures silent, worth knowing before debugging one:

- Ingest keeps the highest accepted `seq` per trip in Redis, and that key
  outlives a test run. A suite whose sequence numbers restart lower has every
  ping dropped as a duplicate, with no error.
- Proximity dedup keys are claimed per household per pass and likewise persist.
  A test asserting an alert must clear the claims for every household on the
  route, not only its own fixture.
