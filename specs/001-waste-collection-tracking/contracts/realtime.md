# Real-time Contracts: MQTT ingest & WebSocket fan-out

## 1. Driver ingest — MQTT (EMQX)

- **Topic**: `trips/{trip_id}/pings` (publish-only for the driver device)
- **Auth**: MQTT CONNECT with username = driver user id, password = driver access JWT;
  EMQX auth hook validates JWT and restricts publish ACL to topics of that driver's
  active trip.
- **Payload** (JSON, ≤ ~160 bytes, QoS 1):

```json
{ "lat": 12.97102, "lng": 77.59901, "speed": 4.2, "heading": 118,
  "accuracy": 8.5, "recordedAt": "2026-07-29T06:12:05.120Z", "seq": 4172 }
```

- **Batching**: device may publish an array of ≤ 5 payloads after offline gaps; `seq` is a
  per-trip monotonic counter enabling server-side ordering and duplicate drop.
- **Server behavior**: validate (accuracy ≤ 100 m, implied speed ≤ 60 km/h, trip active) →
  Redis latest-position → Timescale append → geofence evaluation. Invalid pings are
  counted, not stored.
- **Fallback**: `POST /v1/driver/trips/{id}/pings` (same payload array) when MQTT is
  unreachable.

## 2. Resident live stream — WebSocket

- **Endpoint**: `GET /v1/live` upgraded to WS; query `route_id`.
- **Auth**: `Authorization: Bearer` on the upgrade request. Server verifies the JWT's
  household route matches `route_id` — residents can only subscribe to their own route.
  Ward Admin JWTs may subscribe to any route of their ward (dashboard).
- **Server → client messages** (throttled ≤ 1 per 2 s per auto):

```json
{ "type": "position", "tripId": "…", "autoRegistration": "KA01AB1234",
  "passNumber": 1, "lat": 12.9712, "lng": 77.5993, "heading": 118,
  "at": "2026-07-29T06:12:06Z" }
```

```json
{ "type": "trip_status", "tripId": "…", "status": "completed", "passNumber": 1 }
```

- **Session lifetime**: token verified at upgrade; a socket lives at most 60 min, after
  which the server sends `{"type": "reauth"}` and closes — the client reconnects with a
  freshly refreshed access token (resolves 15-min token vs long-lived stream).
- **Client behavior**: marker interpolation between updates (FR-RES-01); reconnect with
  backoff (server enforces reconnect rate limits); a missed heartbeat (30 s) closes and
  re-dials.
- **No driver PII in any frame** (FR-RES-07).

## 3. Push notifications — FCM (server → device)

Data payload (rendered text localized server-side per user locale):

```json
{ "kind": "proximity", "title": "Auto is ~300 m away",
  "body": "Today: Wet + Dry · Pass 1 of 2", "routeId": "…", "tripId": "…" }
```

Kinds: `proximity` (FR-NOTIF-01, dedup one per household per trip), `arrival` (< 75 m,
v1.1), `schedule_change`, `complaint_status` (FR-NOTIF-04). Delivery budget: ≤ 10 s p95
from geofence hit (FR-NOTIF-05).
