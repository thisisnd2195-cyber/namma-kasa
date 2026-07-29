/**
 * Live end-to-end smoke test.
 *
 * Runs the whole product journey against a REAL running server — not the
 * in-process test modules. Every hop uses the transport a real client uses:
 * OTP over HTTP with the code read from the server log (as a developer would),
 * GPS over MQTT with the per-trip device JWT (not the ingest superuser the
 * vitest suite uses), the resident's actual WebSocket, and the notification
 * outbox draining through the push sender.
 *
 * Usage:
 *   node dist/src/main.js > api.log &          # start the server
 *   node scripts/smoke.mjs http://localhost:4100 api.log
 */
import { readFileSync } from "node:fs";
import mqtt from "mqtt";
import pg from "pg";
import { WebSocket } from "ws";

const BASE = process.argv[2] ?? "http://localhost:4100";
const LOG_FILE = process.argv[3] ?? "/tmp/smoke-api.log";
const DB_URL =
  process.env.DATABASE_URL ?? "postgres://nammakasa:devpassword@localhost:5433/nammakasa";
const MQTT_URL = process.env.MQTT_URL ?? "mqtt://localhost:1883";

const db = new pg.Client({ connectionString: DB_URL });
await db.connect();

// ---------------------------------------------------------------- harness

const results = [];
let failures = 0;

function pass(name, detail = "") {
  results.push({ ok: true, name, detail });
  console.log(`  ✓ ${name}${detail ? `  (${detail})` : ""}`);
}
function fail(name, detail = "") {
  failures += 1;
  results.push({ ok: false, name, detail });
  console.log(`  ✗ ${name}${detail ? `  — ${detail}` : ""}`);
}
function check(cond, name, detail = "") {
  if (cond) pass(name, detail);
  else fail(name, detail);
  return Boolean(cond);
}
function section(title) {
  console.log(`\n${title}`);
}

async function api(method, path, { token, body } = {}) {
  const response = await fetch(`${BASE}/v1${path}`, {
    method,
    headers: {
      "content-type": "application/json",
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();
  let json = null;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    /* not json */
  }
  return { status: response.status, body: json, text };
}

/** The console OTP sender prints `[dev-otp] <phone> <code>` to the log. */
function otpFromLog(phone) {
  const log = readFileSync(LOG_FILE, "utf8");
  const matches = [...log.matchAll(new RegExp(`\\[dev-otp\\]\\s+${phone}\\s+(\\d{6})`, "g"))];
  if (matches.length === 0) throw new Error(`no OTP in log for ${phone}`);
  return matches[matches.length - 1][1];
}

async function waitFor(checkFn, budgetMs = 20_000, everyMs = 500) {
  const deadline = Date.now() + budgetMs;
  while (Date.now() < deadline) {
    if (await checkFn()) return true;
    await new Promise((resolve) => setTimeout(resolve, everyMs));
  }
  return false;
}

async function registerViaOtp(phone, registration) {
  let send = await api("POST", "/auth/otp/send", { body: { phone } });
  if (send.status === 429) {
    // The resend cooldown (FR-AUTH-02). Do what the app does: wait it out.
    const waitSec = Number(/\d+/.exec(send.body?.detail ?? "31")?.[0] ?? 31) + 1;
    console.log(`  … OTP cooldown active for ${phone}, waiting ${waitSec}s`);
    await new Promise((resolve) => setTimeout(resolve, waitSec * 1000));
    send = await api("POST", "/auth/otp/send", { body: { phone } });
  }
  if (send.status !== 202) throw new Error(`otp send ${send.status}: ${send.text}`);
  await new Promise((resolve) => setTimeout(resolve, 500)); // let the log flush

  const verify = await api("POST", "/auth/otp/verify", {
    body: { phone, code: otpFromLog(phone) },
  });
  if (verify.status !== 200) throw new Error(`otp verify ${verify.status}: ${verify.text}`);

  const registered = await api("POST", "/auth/register", {
    body: { ...registration, verificationToken: verify.body.verificationToken },
  });
  if (registered.status === 201) return registered.body;

  // Already registered from an earlier run: the app treats this screen as
  // sign-in too, so do the same.
  if (registered.status === 409) {
    const login = await api("POST", "/auth/login", {
      body: {
        phone,
        password: registration.credential.password,
        deviceId: registration.deviceId ?? "smoke",
      },
    });
    if (login.status === 200) return login.body;
  }
  throw new Error(`register ${registered.status}: ${registered.text}`);
}

// ------------------------------------------------------------- the journey

console.log(`Live smoke test against ${BASE}`);

section("1. Sign in as the seeded admins");
const superAdmin = (
  await api("POST", "/auth/login", {
    body: { phone: "919000000001", password: "devpassword", deviceId: "smoke-super" },
  })
).body.accessToken;
const wardAdmin = (
  await api("POST", "/auth/login", {
    body: { phone: "919000000002", password: "devpassword", deviceId: "smoke-ward" },
  })
).body.accessToken;
check(Boolean(superAdmin && wardAdmin), "both admins signed in");

const wards = await api("GET", "/admin/wards", { token: superAdmin });
const ward = wards.body[0];
const routes = await api("GET", `/admin/routes?wardId=${ward.id}`, { token: wardAdmin });
const route = routes.body[0];
check(Boolean(route?.id), "seeded ward and route found", route?.name);

section("2. Ward admin widens today's window (so the run works at any hour)");
const widened = await api("PATCH", `/admin/routes/${route.id}`, {
  token: wardAdmin,
  body: { windowStart: "00:01", windowEnd: "23:59", collectionDays: [1, 2, 3, 4, 5, 6, 7] },
});
check(widened.status === 200, "route window widened over the API");
// Derived pass state from before the widening would leave passes marked
// skipped; clear today's rows so the day starts clean under the new window.
await db.query(
  `DELETE FROM route_pass_days WHERE route_id = $1 AND service_date = (now() AT TIME ZONE 'Asia/Kolkata')::date`,
  [route.id],
);

section("3. A new resident registers in Kannada, pin inside the route area");
// Drop the pin at the centroid of the serviceable area, as a resident would
// drag the map to their house. PostGIS returns MultiPolygon even for a single
// polygon, so unwrap one level when it does.
const ring =
  route.serviceableArea.type === "MultiPolygon"
    ? route.serviceableArea.coordinates[0][0]
    : route.serviceableArea.coordinates[0];
const pin = {
  lng: ring.reduce((s, [lng]) => s + lng, 0) / ring.length,
  lat: ring.reduce((s, [, lat]) => s + lat, 0) / ring.length,
};
const RESIDENT_PHONE = "919888811111";
await db.query(`DELETE FROM users WHERE phone = $1`, [RESIDENT_PHONE]); // repeatable runs

const residentSession = await registerViaOtp(RESIDENT_PHONE, {
  role: "resident",
  credential: { password: "devpassword" },
  profile: {
    fullName: "Smoke Kumari",
    addressLine: "12, 4th Cross, Shanthala Nagar",
    landmark: "Opp. the park gate",
    pin,
    locale: "kn",
    consent: true,
  },
});
const resident = residentSession.accessToken;
const residentUserId = residentSession.user.id;
check(residentSession.user.locale === "kn", "account stored as Kannada");

const home0 = await api("GET", "/resident/home", { token: resident });
check(
  home0.body.route?.id === route.id,
  "household auto-mapped to the route from the pin alone (FR-AUTH-08)",
);
const deviceReg = await api("POST", "/notifications/devices", {
  token: resident,
  body: { fcmToken: `smoke-device-token-${Date.now()}` },
});
check(deviceReg.status === 204, "push token registered");

section("4. The pre-provisioned driver claims their account by phone");
const driverSession = await registerViaOtp("919999900001", {
  role: "driver",
  credential: { password: "devpassword" },
  profile: { locale: "kn", consent: true },
  deviceId: "smoke-driver-phone",
});
const driver = driverSession.accessToken;
check(driverSession.user.role === "driver", "driver account created against provisioning");

const assignment = await api("GET", "/driver/assignment", { token: driver });
check(
  assignment.body?.auto?.registrationNumber === "KA01AB1234",
  "driver sees their assigned auto and route (FR-DRV-01)",
  `next pass ${assignment.body?.today?.nextPassNumber}`,
);

section("5. Driver starts the trip and gets a per-trip broker token");
const trip = await api("POST", "/driver/trips", {
  token: driver,
  body: { passNumber: assignment.body.today.nextPassNumber ?? 1 },
});
check(trip.status === 201 && trip.body.status === "active", "trip started");
const tripId = trip.body.id;

const broker = await api("POST", `/driver/trips/${tripId}/mqtt-token`, { token: driver });
check(broker.status === 201 && Boolean(broker.body.password), "per-trip MQTT credential issued");

section("6. Resident opens the live map (real WebSocket)");
const wsUrl = `${BASE.replace("http", "ws")}/v1/live?token=${resident}&route_id=${route.id}`;
const socket = new WebSocket(wsUrl);
const firstFrame = new Promise((resolve) => {
  const timer = setTimeout(() => resolve(null), 25_000);
  socket.on("message", (data) => {
    clearTimeout(timer);
    resolve(JSON.parse(data.toString()));
  });
});
await new Promise((resolve, reject) => {
  socket.once("open", resolve);
  socket.once("error", reject);
});
pass("socket accepted for the resident's own route");

section("7. Driver's phone publishes GPS over MQTT with the device token");
// The REAL auth path: EMQX validates this JWT and its acl claim. The vitest
// e2e uses the ingest superuser, so this is the first live proof of it.
const device = await mqtt.connectAsync(MQTT_URL, {
  username: broker.body.username,
  password: broker.body.password,
  clientId: "smoke-device",
});
pass("broker accepted the device JWT");

// Approach the resident's house from ~600 m out. recordedAt spacing keeps the
// implied speed legal (~18 km/h); the final ping is at the gate.
const metresPerDegLat = 111_320;
const offsets = [600, 450, 350, 250, 150, 80, 40, 0];
const now = Date.now();
const pings = offsets.map((metres, i) => ({
  lat: pin.lat - metres / metresPerDegLat,
  lng: pin.lng,
  recordedAt: new Date(now - (offsets.length - 1 - i) * 30_000).toISOString(),
  seq: i + 1,
  accuracy: 8,
}));
await device.publishAsync(`trips/${tripId}/pings`, JSON.stringify(pings), { qos: 1 });
pass(`published ${pings.length} positions on trips/${tripId}/pings`);

// Negative: the same token must NOT publish anywhere else. A denied QoS-1
// publish never acks — EMQX disconnects instead — so race ack vs close.
const rogue = await mqtt.connectAsync(MQTT_URL, {
  username: broker.body.username,
  password: broker.body.password,
  clientId: "smoke-rogue",
});
const rogueOutcome = await Promise.race([
  rogue.publishAsync("trips/some-other-trip/pings", "[]", { qos: 1 }).then(() => "allowed"),
  new Promise((resolve) => rogue.once("close", () => resolve("denied"))),
  new Promise((resolve) => setTimeout(() => resolve("denied"), 4_000)),
]);
check(rogueOutcome === "denied", "device token refused for another trip's topic (ACL)");
rogue.end(true);

section("8. The position reaches the resident");
const frame = await firstFrame;
check(
  frame?.type === "position" && frame.tripId === tripId,
  "live frame arrived on the socket",
  frame ? `auto ${frame.registrationNumber}` : "no frame",
);
socket.close();

const gotProximity = await waitFor(async () => {
  const { rows } = await db.query(
    `SELECT payload FROM notifications WHERE user_id = $1 AND kind = 'proximity' AND sent_at IS NOT NULL`,
    [residentUserId],
  );
  return rows.length > 0;
});
check(gotProximity, "proximity alert queued, drained, and delivered through the sender");
const gotArrival = await waitFor(async () => {
  const { rows } = await db.query(
    `SELECT 1 FROM notifications WHERE user_id = $1 AND kind = 'arrival' AND sent_at IS NOT NULL`,
    [residentUserId],
  );
  return rows.length > 0;
});
check(gotArrival, "'at your street' alert delivered at 75 m (FR-NOTIF-03)");

const { rows: proxRows } = await db.query(
  `SELECT payload->>'title' AS title FROM notifications WHERE user_id = $1 AND kind = 'proximity'`,
  [residentUserId],
);
check(
  /[ಀ-೿]/.test(proxRows[0]?.title ?? ""),
  "the push copy is in Kannada, because the resident chose Kannada",
  proxRows[0]?.title,
);

section("9. The visit becomes evidence, and the resident rates it");
const collected = await waitFor(async () => {
  const home = await api("GET", "/resident/home", { token: resident });
  return home.body.lastCollectedAt !== null && home.body.canRateToday === true;
});
check(collected, "lastCollectedAt set and rating offered (75 m evidence rule)");
const rating = await api("POST", "/resident/ratings", { token: resident, body: { stars: 5 } });
check(rating.status === 201, "rating accepted");
const again = await api("POST", "/resident/ratings", { token: resident, body: { stars: 1 } });
check(again.status === 409, "second rating today refused (FR-CMP-05)");

section("10. A complaint is answered by the GPS record");
const complaint = await api("POST", "/resident/complaints", {
  token: resident,
  body: { category: "missed_pickup", description: "Testing the evidence trail", mediaUrls: [] },
});
check(complaint.status === 201 && complaint.body.slaDueAt, "complaint filed with an SLA due time");

const queue = await api("GET", "/admin/complaints?status=open", { token: wardAdmin });
const mine = queue.body.find((c) => c.id === complaint.body.id);
check(
  mine?.evidence?.servedOnComplaintDay === true,
  "admin sees the GPS record: the auto DID reach this house today",
);
const resolved = await api("PATCH", `/admin/complaints/${complaint.body.id}`, {
  token: wardAdmin,
  body: { status: "resolved", resolutionNote: "GPS shows collection at your gate today." },
});
check(resolved.status === 200, "complaint resolved");
const statusPush = await waitFor(async () => {
  const { rows } = await db.query(
    `SELECT 1 FROM notifications WHERE user_id = $1 AND kind = 'complaint_status' AND sent_at IS NOT NULL`,
    [residentUserId],
  );
  return rows.length > 0;
});
check(statusPush, "resident notified of the resolution");

section("11. Driver reports a breakdown; the ward admin acknowledges");
const issue = await api("POST", "/driver/issues", {
  token: driver,
  body: { kind: "breakdown", note: "Smoke test breakdown", geo: pin },
});
check(issue.status === 201, "issue reported");
const issues = await api("GET", `/admin/driver-issues/wards/${ward.id}`, { token: wardAdmin });
check(
  issues.body.some((i) => i.id === issue.body.id && i.acknowledgedAt === null),
  "issue visible in the ward queue, unacknowledged",
);
const acked = await api("PATCH", `/admin/driver-issues/${issue.body.id}/acknowledge`, {
  token: wardAdmin,
  body: {},
});
check(acked.status === 200 && acked.body.acknowledgedAt !== null, "acknowledged");

section("12. Trip ends; its trail becomes the route's recorded path");
const ended = await api("PATCH", `/driver/trips/${tripId}/end`, {
  token: driver,
  body: { reason: "driver" },
});
check(ended.status === 200 && ended.body.status === "completed", "trip completed");
device.end(true);

const recordable = await api("GET", `/admin/routes/${route.id}/recordable-trips`, {
  token: wardAdmin,
});
check(
  recordable.body.some((t) => t.id === tripId && t.positionCount >= 2),
  "completed trip offered as a recordable path",
);
const recorded = await api("POST", `/admin/routes/${route.id}/recorded-path`, {
  token: wardAdmin,
  body: { tripId },
});
check(
  recorded.status === 200 && recorded.body.recordedPath?.geometry?.coordinates?.length >= 2,
  "trail adopted and readable back on the route",
  `${recorded.body.recordedPath?.geometry?.coordinates?.length} points`,
);

section("13. The day shows up on the city dashboard");
const rollup = await api("GET", "/admin/dashboard/city", { token: superAdmin });
check(
  rollup.body.trips.total >= 1 && rollup.body.routeCoverage.served >= 1,
  "rollup counts the trip and the served route",
  `${rollup.body.routeCoverage.percent}% coverage`,
);

section("14. Everything an admin did is attributable");
const { rows: audit } = await db.query(
  `SELECT count(*)::int AS n FROM audit_log WHERE at > now() - interval '10 minutes'`,
);
check(audit[0].n >= 4, "audit rows written for this run's admin mutations", `${audit[0].n} rows`);

section("15. The resident can leave (DPDP erasure)");
const erasure = await api("DELETE", "/me", { token: resident });
check(
  erasure.status === 202 && Boolean(erasure.body.erasesAfter),
  "erasure scheduled with a stated date",
);

// ------------------------------------------------------------------ summary

await db.end();
const passed = results.filter((r) => r.ok).length;
console.log(`\n${passed}/${results.length} checks passed${failures ? ` — ${failures} FAILED` : ""}`);
process.exit(failures === 0 ? 0 : 1);
