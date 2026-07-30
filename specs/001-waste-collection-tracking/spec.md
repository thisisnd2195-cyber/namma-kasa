# Feature Specification: City Waste Collection Tracking Platform

**Feature Branch**: `001-waste-collection-tracking`

**Created**: 2026-07-29

**Status**: Draft

**Input**: User description: "SPEC-WCT-001 v1.0 — Technical specification for a platform providing live
tracking of door-to-door waste-collection autos, route/fleet administration, and resident engagement
(schedules, notifications, complaints, ratings) for Bengaluru, extensible to other cities. Full
numbered requirements document provided; condensed here into a Spec Kit feature spec."

## Clarifications

### Session 2026-07-29 (gate.md checklist pass, CHK001–CHK051)

- **Serving auto / multi-auto routes (CHK001)**: the resident map shows **all** autos with
  active trips on their route, each labelled by registration number.
- **Collection event (CHK002, CHK035)**: a household is "collected" for a pass when an
  active trip's accepted position comes within 75 m of the house pin; this event drives
  the last-collected timestamp and is the MVP rating trigger (in-app banner; push prompt
  is v1.1).
- **Offline spool (CHK003, CHK038)**: 5 is the per-publish batch size; the device spools
  pings locally without limit for the trip's duration and replays in order on reconnect.
  Data loss occurs only on device storage failure. Backend outage: resident app shows
  "live tracking unavailable"; recovery objective 15 min.
- **Trip lifecycle (CHK004, CHK006, CHK007, CHK033)**: driver may resume or end an
  interrupted active trip on app restart; drivers (with reason) and Ward Admins may abort.
  Reassignments never affect an in-flight trip. A pass whose window elapses without
  starting is auto-marked `skipped`; pass *n* requires pass *n−1* completed, aborted, or
  skipped. If a trip is idle AND unreachable (no pings, no prompt ack) for 45 min it
  force-ends as `auto_idle`.
- **No-trip / zero states (CHK005, CHK037)**: resident home without an active trip shows
  house pin, route area, and next scheduled window; driver without assignment sees
  "contact your Ward Admin"; resident outside coverage sees a coverage message; empty
  wards/routes render with explicit empty states.
- **Ping validation (CHK008, CHK036, CHK042)**: speed rejection uses a 3-ping rolling
  window (guards against single GPS jumps); rejected pings are counted per trip and the
  driver app warns on sustained bad GPS (>20% rejected over 5 min). Duplicates dropped by
  per-trip `seq`; ordering by `recorded_at`; geofence evaluates forward-in-time pings only.
- **Privacy & security (CHK009–CHK016)**: driver consent to trip-time-only tracking is
  captured at registration (EN/KN); consent withdrawal deactivates the driver. Any user
  may request account deletion — PII erased/anonymized within 30 days, operational
  records (trips, pings, complaints) retained anonymized. A Google account links to at
  most one user. Drivers: max one active device (new device revokes previous, OTP
  re-verify). Rate limits beyond OTP: per-user/IP API limits, complaints ≤ 5/household/day,
  presigns ≤ 20/driver/trip, WS reconnect backoff enforced. Audit log: actor,
  entity, before/after, timestamp for every admin mutation; 2-year retention; Super Admin
  read access. Media (proof + complaint photos): ≤ 500 KB each, proof ≤ 10/trip, retained
  180 days (longer only while attached to an open complaint), served via authenticated
  scoped URLs. Ward Admin offboarding: Super Admin disables the account; the ward is
  flagged unmanaged and its queues stay visible to the Super Admin until a replacement is
  assigned.
- **Geo & admin (CHK017–CHK022)**: editing a ward boundary shows the impact count before
  save and flags affected households `pending_review` (residents notified only if their
  route changes). Bulk import is per-feature accept/reject with a reasoned report;
  accepted features commit as one batch. **Route serviceable areas within a ward must not
  overlap** (same rejection UX as wards). Review-queue items older than 48 h are flagged;
  pending residents see a "pending assignment" state and may still edit their pin.
  Operator retirement is blocked while it owns active wards; wards are transferable
  between operators (audit-logged). Autos/drivers cannot enter maintenance/retired/
  inactive while on an active trip; the transition closes their active assignment.
- **Measurability (CHK023–CHK030)**: 2 s is the server emit cadence; 3 s p95 (SC-004) is
  the end-to-end budget. Driver trip controls: ≥ 56 dp touch targets, WCAG AA contrast.
  "Tracking dropped" = `received_at` gap > 3 min; auto-clears on next accepted ping.
  Notification copy is server-templated and localized; distances rounded to nearest 50 m.
  Availability is measured monthly over collection hours; "down" = API error rate > 5%
  or a halted live pipeline (API, WS, ingest in scope). The pilot device matrix (min:
  Xiaomi/Redmi, Samsung, Vivo/Oppo, stock Android across Android 8/10/13) is a pilot-gate
  artifact. "Multi-city ready" means: city entity on wards, city-scoped uniqueness, no
  hardcoded Bengaluru constants — nothing more in v1. All times are IST
  (Asia/Kolkata); "collection day" = IST calendar date.
- **Consistency fixes (CHK031, CHK032, CHK034)**: proximity dedup is per household per
  **pass** — key (household, route, service-date, pass-number) — so two autos on one pass
  yield one alert. Resident WebSockets: token verified at upgrade, max socket lifetime
  60 min, then a re-auth frame prompts reconnect with a fresh token. Behavior complaints
  reference route + time window; Ward Admins resolve driver identity internally; resident
  surfaces never show it.
- **NFR additions (CHK039, CHK041, CHK043–CHK047)**: if notification permission is
  denied, alerts degrade to in-app banners (SMS fallback stays roadmapped). Ward Admins
  can broadcast per-route service advisories (holidays/disruptions) via the
  schedule-change notification kind. Load degradation order: live cadence stretches to
  10 s → resident WS paused with banner → dashboards degrade; ingest and notifications
  are protected last. **Accessibility (new NFR-11)**: WCAG 2.1 AA for the portal;
  TalkBack labels, ≥ 48 dp targets (56 dp driver controls), and dynamic font support in
  the app. Localization scope: resident + driver surfaces full EN/KN (driver defaults
  KN); admin portal EN-only in v1; fallback EN. The tracking-health dashboard shows
  per-ward active trips, % trips with drops, median ping latency, and alert queue age.
- **Assumptions hardened (CHK048–CHK051)**: hand-drawn boundaries are acceptable for
  pilot wards (must cover all pilot households); official dataset required before city
  rollout. OTP provider sits behind an abstraction with a configurable secondary; SMS
  outage blocks new registrations with a status message but never blocks existing
  password/Google logins. Google Sign-In is optional convenience — the password path
  always works. v1 keeps one household per resident account; multi-house and shared-
  account family flows are roadmap items.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Admin sets up the service area (Priority: P1)

A Super Admin onboards an operator (BBMP department or private contractor) and its wards by bulk-importing
official ward boundary files or drawing boundaries on a map, then provisions a Ward Admin for each ward.
The Ward Admin creates collection routes inside the ward (serviceable area, collection days, time window,
waste-type schedule per weekday, passes per day), onboards autos and drivers, and assigns drivers to autos
and autos to routes.

**Why this priority**: Every other capability (trips, live tracking, resident mapping, notifications)
depends on wards, routes, autos, and drivers existing. This alone delivers value as a fleet/route registry.

**Independent Test**: With a clean system, a Super Admin can create one operator + one ward (imported
boundary) + one Ward Admin; that Ward Admin can create one route, one auto, one driver, and complete
both assignments. All records visible and editable; misconfigurations (overlapping ward, route outside
ward, cross-ward assignment) are rejected with clear errors.

**Acceptance Scenarios**:

1. **Given** a boundary file of official wards, **When** the Super Admin imports it, **Then** wards are
   created with names, codes, and boundaries visible on a map.
2. **Given** a new ward polygon that overlaps an existing ward, **When** the admin saves it, **Then** the
   save is rejected and the conflicting area is shown visually.
3. **Given** a route whose serviceable area extends beyond its ward, **When** the Ward Admin saves it,
   **Then** the save is rejected with the violation indicated.
4. **Given** an available auto of the same ward, **When** the Ward Admin assigns it to a route, **Then**
   the assignment is recorded with an effective-from timestamp and prior history is preserved.
5. **Given** a Ward Admin scoped to ward A, **When** they attempt to view or modify ward B resources,
   **Then** the action is denied.

---

### User Story 2 - Driver runs a collection trip (Priority: P2)

A pre-provisioned driver registers on the app with their phone number, sees their assigned auto and route
(area on map, today's collection window, waste types, passes completed/remaining), and starts a trip for
the next pass. While the trip is active the app continuously shares the auto's position, tolerating
network dead zones by queueing and replaying positions. The driver can capture geotagged photos
(collection proof or issues) and end the trip; an idle trip prompts the driver and auto-ends.

**Why this priority**: Live positions are the platform's core data feed; nothing resident-facing works
without trips emitting locations.

**Independent Test**: A provisioned driver can register, start pass 1, drive (or simulate movement),
observe their own trail recorded, and end the trip. Positions survive a temporary network drop.
An unprovisioned phone number cannot register as a driver.

**Acceptance Scenarios**:

1. **Given** a phone number not pre-provisioned by a Ward Admin, **When** it attempts driver
   registration, **Then** registration is refused.
2. **Given** an active trip, **When** the device loses connectivity for 2 minutes, **Then** positions
   recorded offline are delivered once connectivity returns, in order.
3. **Given** a route with 2 passes/day, **When** the driver tries to start pass 2 while pass 1 is still
   active, **Then** the start is blocked until pass 1 is completed or aborted.
4. **Given** an active trip with no movement for 30 minutes, **When** the driver does not respond to a
   confirmation prompt, **Then** the trip ends automatically.
5. **Given** an active trip whose positions stop arriving for more than 3 minutes, **When** the gap is
   detected, **Then** the Ward Admin dashboard shows a "tracking dropped" alert for that auto.

---

### User Story 3 - Resident registers their house and tracks the auto live (Priority: P3)

A resident registers with phone verification, then sets a sign-in method (password or Google). They map
their house by dropping a pin on a map (address text is assistive only). The system derives their ward
and suggests a route; ambiguous cases go to a Ward Admin review queue. On the home screen the resident
sees today's waste types, the collection window, the current pass ("Pass 1 of 2"), last-collected time,
and the live position of the auto serving their route, moving smoothly on the map.

**Why this priority**: This is the headline resident value — "where is my garbage auto right now" — and
depends on stories 1 and 2 being in place.

**Independent Test**: A resident can complete registration + pin-drop in one sitting, land on the home
screen, and see the serving auto move within seconds of the driver's movement. Editing the pin re-runs
ward/route mapping.

**Acceptance Scenarios**:

1. **Given** a new resident, **When** they register, **Then** phone verification is required before a
   sign-in method is set, and OTP abuse limits apply (expiry, attempt caps, resend cooldown, hourly cap).
2. **Given** a dropped pin inside a mapped ward and route area, **When** registration completes, **Then**
   the household is auto-assigned to that ward and route.
3. **Given** a pin that resolves to no route, **When** registration completes, **Then** the household
   enters the Ward Admin review queue and the resident sees a pending state, and the Ward Admin can
   assign a route manually.
4. **Given** an active trip on the resident's route, **When** the resident opens the home screen, **Then**
   the auto's position appears and updates at least every 2 seconds with smooth movement.
5. **Given** any resident session, **When** viewing the auto, **Then** only the auto's registration
   number and position are shown — never the driver's name or phone.

---

### User Story 4 - Resident gets a proximity alert (Priority: P4)

When the serving auto enters the resident's configured alert radius (default 300 m) during a pass, the
resident receives a push notification such as "Auto is ~300 m away · Today: Wet + Dry" — at most one per
household per pass.

**Why this priority**: Notifications convert live tracking into the practical outcome — residents step
out at the right time — but require stories 1–3 operating.

**Independent Test**: With a household inside a route and an active trip approaching it, exactly one
alert is delivered per pass, within 10 seconds of the auto entering the radius; repeat approaches in the
same pass produce no further alerts.

**Acceptance Scenarios**:

1. **Given** an active trip entering a household's radius, **When** the geofence hit occurs, **Then** a
   push notification is delivered within 10 seconds (p95) including today's waste types.
2. **Given** an auto that exits and re-enters the radius during the same pass, **When** it re-enters,
   **Then** no duplicate alert is sent.
3. **Given** a route with 2 passes/day, **When** each pass approaches, **Then** the household receives
   one alert per pass.

---

### User Story 5 - Resident files complaints and rates service (Priority: P5)

A resident raises a complaint (missed pickup / late / behavior / segregation / other) with description
and up to 3 photos; it routes to their Ward Admin, moves through open → in_review → resolved/rejected,
and the resident sees the status history and gets status-change notifications. After a collection event,
the resident can rate the service 1–5 stars with an optional comment — at most one rating per household
per collection day. The Ward Admin manages the complaint queue; dashboards show live autos in the ward.

**Why this priority**: Feedback loops improve accountability but the platform is viable without them at
pilot start.

**Independent Test**: A resident can file a complaint with photos and watch its status change as the
Ward Admin processes it; a rating can be submitted once per collection day and a second attempt is
rejected.

**Acceptance Scenarios**:

1. **Given** a filed complaint, **When** the Ward Admin updates its status, **Then** the resident sees
   the new status and history, and receives a notification.
2. **Given** a household that already rated today's collection, **When** a second rating is submitted,
   **Then** it is rejected.
3. **Given** a Ward Admin, **When** they open their dashboard, **Then** they see all active autos of
   their ward on a live map with trip status.

---

### Edge Cases

- Household pin lands exactly on a ward boundary or in an unmapped gap → review queue, never silent
  misassignment.
- Ward boundary is edited after households were mapped → affected households flagged for re-mapping
  review rather than silently reassigned.
- Driver phone dies / app killed by aggressive battery management mid-trip → tracking-dropped alert to
  Ward Admin; on restart the driver can resume or end the trip.
- Two autos serve the same route simultaneously → resident sees the auto whose current trip serves their
  route; alerts still dedup per household per pass per trip.
- Auto reassigned mid-day (breakdown) → history preserved; new auto's trips serve the route from the
  effective timestamp.
- Resident changes house pin to a different ward → household re-mapped; old route stops alerting.
- Position noise (GPS jumps, impossible speeds) → rejected from the live feed so residents don't see the
  auto teleport.
- OTP delivery failure or delay → resend allowed after cooldown; hourly cap prevents SMS abuse.
- Clock skew on driver devices → position timestamps ordered server-side on receipt.

## Requirements *(mandatory)*

Priorities: **M** = must (MVP) · **S** = should (v1.1) · **C** = could (v1.2+). IDs mirror the source
document (SPEC-WCT-001) for traceability.

### Functional Requirements

**Authentication & Registration**

- **FR-AUTH-01 (M)**: The app entry MUST offer "Login as Resident" and "Login as Driver".
- **FR-AUTH-02 (M)**: Registration MUST require one-time phone verification via 6-digit SMS OTP
  (5-minute expiry, 3 attempts, resend after 30 s, max 5 OTPs per number per hour).
- **FR-AUTH-03 (M)**: After phone verification, the user MUST set up either username+password or Google
  sign-in, linked to the verified phone.
- **FR-AUTH-04 (M)**: Subsequent logins use password or Google; phone re-verification only on password
  reset or driver new-device login.
- **FR-AUTH-05 (M)**: Driver registration MUST succeed only for phone numbers pre-provisioned by a Ward
  Admin.
- **FR-AUTH-06 (M)**: Sessions MUST use short-lived access credentials (15 min) with rotating refresh
  (30 days), carrying role and scope.
- **FR-AUTH-07 (M)**: Resident registration MUST capture name, address line, landmark, and a map
  pin-drop for the house (pin-drop-first; reverse geocoding assistive only).
- **FR-AUTH-08 (M)**: The system MUST derive the ward from the house pin and suggest a route;
  unresolvable households enter the Ward Admin review queue.

**Ward & Operator Management**

- **FR-WARD-01 (M)**: Super Admin MUST manage operators (BBMP or private); each ward belongs to exactly
  one operator.
- **FR-WARD-02 (M)**: Super Admin MUST create wards with name, code, and boundary polygon.
- **FR-WARD-03 (M)**: The portal MUST provide interactive polygon drawing/editing for boundaries.
- **FR-WARD-04 (M)**: The portal MUST support bulk boundary import (GeoJSON/KML) as the primary path.
- **FR-WARD-05 (M)**: Overlapping ward polygons MUST be rejected with a visual diff of the conflict.
- **FR-WARD-06 (M)**: Ward Admin accounts are scoped to exactly one ward; scoping enforced server-side
  on every call.

**Route Management**

- **FR-ROUTE-01 (M)**: Ward Admin MUST create routes with name, code, serviceable-area polygon
  (contained within the ward), collection days, and time window.
- **FR-ROUTE-02 (M)**: `passes_per_day` MUST be configurable per route (integer ≥ 1, default 1).
- **FR-ROUTE-03 (M)**: Ward Admin MUST define the waste-type schedule per route per weekday.
- **FR-ROUTE-04 (S)**: Route path MAY be auto-recorded from a completed trip's trail.
- **FR-ROUTE-05 (M)**: Route serviceable areas within a ward MUST NOT overlap; overlapping saves are
  rejected with the conflict shown visually (same UX as ward overlaps).

**Fleet — Autos & Drivers**

- **FR-FLEET-01 (M)**: Autos onboarded with unique Indian-format registration number, capacity, photos;
  status ∈ {available, assigned, maintenance, retired}.
- **FR-FLEET-02 (M)**: Route assignment lists only available autos of that ward; one active route per
  auto; multiple autos may serve one route.
- **FR-FLEET-03 (M)**: Drivers provisioned with name, phone, license, photo, emergency contact; exactly
  one active driver per auto; assignment history retained.
- **FR-FLEET-04 (M)**: Reassignments take effect from a stated timestamp and never rewrite history.
- **FR-FLEET-05 (S)**: Same-day hot-swap of backup auto/driver onto a route.

**Driver App**

- **FR-DRV-01 (M)**: Driver home shows assigned auto, route area on map, today's window, waste types,
  passes completed/remaining.
- **FR-DRV-02 (M)**: Start/End trip; pass *n* requires pass *n−1* completed, aborted, or
  auto-marked skipped (window elapsed unstarted); trip controls ≥ 56 dp touch targets, WCAG AA
  contrast.
- **FR-DRV-03 (M)**: Active trips MUST share position continuously (every 5 s or 25 m); publishes
  batch up to 5 positions, and the device spools offline positions without limit for the trip's
  duration, replaying in order on reconnect.
- **FR-DRV-04 (M)**: First-run wizard MUST guide battery-optimization exemption with OEM-specific steps;
  a persistent notification shows while tracking.
- **FR-DRV-05 (M)**: A position gap > 3 minutes mid-trip MUST raise a "tracking dropped" alert on the
  Ward Admin dashboard.
- **FR-DRV-06 (M)**: Geotagged photo capture (camera-first, compressed ≤ 500 KB), queued offline; types:
  collection proof / issue / other.
- **FR-DRV-07 (S)**: Quick-report issues (breakdown, road blocked) notifying the Ward Admin immediately.
- **FR-DRV-08 (M)**: Trips auto-end after 30 minutes without movement, after a driver confirmation
  prompt; if the device is unreachable (no pings and no prompt acknowledgment) for 45 minutes, the
  trip force-ends as `auto_idle`.

**Resident App**

- **FR-RES-01 (M)**: Home shows a map centered on the house pin with the live positions of **all**
  autos on active trips for the resident's route (labelled by registration number), server emit
  cadence ≤ 2 s with smooth marker movement.
- **FR-RES-02 (M)**: Home shows today's waste types, collection window, current pass (e.g., "Pass 1 of
  2"), and last-collected time — where "collected" means an active trip's accepted position came
  within 75 m of the house pin during a pass.
- **FR-RES-03 (S)**: Coarse arrival hint ("~6 min away", straight-line estimate).
- **FR-RES-04 (M)**: Residents can edit house details; a pin change re-runs ward/route mapping.
- **FR-RES-05 (S)**: Adjustable notification radius (100–1000 m, default 300 m).
- **FR-RES-06 (M)**: English and Kannada supported.
- **FR-RES-07 (M)**: Residents MUST never see driver personal details — only auto number and position.

**Notifications**

- **FR-NOTIF-01 (M)**: Push proximity alert when the serving auto enters the resident's radius, naming
  today's waste types.
- **FR-NOTIF-02 (M)**: Max one proximity alert per household per **pass** — dedup key (household,
  route, service date, pass number) — regardless of how many autos serve the pass.
- **FR-NOTIF-03 (S)**: "Arrived at your street" alert under 75 m.
- **FR-NOTIF-04 (M)**: Schedule-change and complaint-status notifications.
- **FR-NOTIF-05 (M)**: Notification latency ≤ 10 s (p95) from geofence hit.

**Complaints & Ratings**

- **FR-CMP-01 (M)**: Complaints with category (missed pickup / late / behavior / segregation / other),
  description, up to 3 photos.
- **FR-CMP-02 (M)**: Complaints route to the resident's Ward Admin; statuses open → in_review →
  resolved/rejected; resident sees history.
- **FR-CMP-03 (S)**: Per-operator complaint SLA and escalation configuration; breaches surface on
  dashboards.
- **FR-CMP-04 (C)**: Optional Sahaaya 2.0 sync for BBMP wards behind a feature flag.
- **FR-CMP-05 (M)**: 1–5 star rating (+comment) after a collection event; max one per household per
  collection day.
- **FR-CMP-06 (S)**: Rating prompt after the auto exits the proximity zone or the trip completes.

**Admin Dashboards**

- **FR-DASH-01 (M)**: Ward Admin live map of all active autos in the ward with trip status.
- **FR-DASH-02 (S)**: Super Admin city rollups: active trips, route coverage %, complaint volumes/SLA,
  ratings by ward/operator.
- **FR-DASH-03 (C)**: Missed-pickup auto-detection (no ping within 75 m of a household during its
  window) with prefilled complaint.

### Key Entities

- **Operator**: Entity running collection in a set of wards — BBMP department or private contractor;
  owns configuration (e.g., complaint SLAs).
- **Ward**: Administrative division with a geographic boundary; belongs to one operator; has one Ward
  Admin.
- **Route**: Named collection unit inside a ward — serviceable area, collection days, time window,
  waste-type schedule per weekday, passes per day.
- **Auto**: Collection vehicle identified by registration number; belongs to a ward; assigned to at most
  one active route; lifecycle status.
- **Driver**: Person operating an auto; pre-provisioned by a Ward Admin; linked to a user account on app
  signup; exactly one active driver per auto; personal details hidden from residents.
- **Assignment (auto↔route, driver↔auto)**: Time-bounded records (effective from/to); history never
  rewritten.
- **Household**: A resident's individually mapped house (point location, address text, landmark);
  derived ward and route; mapping status (auto / admin-corrected / pending review); notification radius.
- **Trip**: One driver's execution of one pass of a route — start/end, status (active / completed /
  aborted), position trail.
- **Position ping**: Time-stamped location sample of an auto during a trip (speed, heading, accuracy);
  raw retention 90 days.
- **Media upload**: Geotagged photo tied to a trip/driver (proof, issue, other).
- **Complaint**: Household-raised issue with category, description, photos, status history, assignee,
  SLA due time.
- **Rating**: 1–5 stars per household per collection day, optionally tied to a trip.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A Super Admin can onboard a city's full ward set (~225 wards) via bulk import in under one
  working day, including fixing rejected boundaries.
- **SC-002**: A Ward Admin can set up a complete route (area, schedule, auto, driver) in under 10
  minutes.
- **SC-003**: A resident completes registration including house pin-drop in under 3 minutes, and ≥ 90%
  of households are auto-mapped to a route without admin review.
- **SC-004**: Residents watching the map see auto movement reflected within 3 seconds (p95) of the
  vehicle actually moving.
- **SC-005**: Proximity alerts arrive within 10 seconds (p95) of the auto entering the radius, with at
  most one alert per household per pass.
- **SC-006**: The platform sustains city scale: ~4–5k autos reporting simultaneously and 100k residents
  concurrently watching live maps during the morning peak, with 99.5% availability during collection
  hours (05:30–15:00 IST).
- **SC-007**: ≥ 95% of trips complete without a "tracking dropped" alert on the pilot device matrix.
- **SC-008**: A driver's day requires ≤ 3 mandatory interactions per pass (start, end, confirm-if-idle).
- **SC-009**: Complaint status changes are visible to the resident within 10 seconds of the admin's
  update.
- **SC-010**: All admin actions are attributable (who/when) and assignment history is fully
  reconstructible for any past date.

## Design System & Visual Language

**Source of truth**: Tokens v2 below (decided 2026-07-30, approved from rendered mocks —
supersedes the Google/Material-3 neutral set of 2026-07-29). The direction is the
map-first pattern language of ride-hailing apps (Uber's Base system), with **orange as
the single accent wherever that language uses black**. Tokens are mirrored into Flutter
`ThemeData` and the portal Tailwind theme per DS-05.

- **DS-01 (Map-first, floating UI)**: On mobile, map screens are **full-bleed**: the map
  fills the viewport, controls float over it as circular buttons and pills with soft
  shadows, and content lives in a **draggable bottom sheet** (28 dp top radius, grabber
  bar). No fixed app bars on map screens. Non-map screens keep conventional layout.
- **DS-02 (Orange is action and liveness, never prose)**: The accent `#EA580C` is
  reserved for primary CTAs, the live auto marker and its trail, active navigation
  state, and live/ETA pills. Body text, headings and labels stay ink/grey — orange
  text on white is prohibited below 18 px (contrast), and large saturated fills are
  limited to buttons and markers. Status colors (success/warn/danger) remain
  functional-only and MUST be distinguishable by more than hue (icon/label, NFR-11).
- **DS-03 (Typography)**: One bold grotesque scale across surfaces (system/Inter class,
  Uber-Move-like weights: 700–800 for headlines, tight letter-spacing), with
  **Noto Sans Kannada** as the paired Kannada face. Driver floor unchanged: body ≥ 16,
  control labels ≥ 18 (FR-DRV-02).
- **DS-04 (Component language)**: Cards float — soft shadow, 16 dp radius, no borders.
  Sheets 28 dp top radius. Buttons are full-width, **56 dp**, bold, 14 dp radius:
  primary orange, destructive red, secondary grey ghost. Status is expressed as
  **pills/chips** (soft tinted background + strong foreground), not bare text.
- **DS-05 (Consistency across codebases)**: Mobile (Flutter) and web (React) share no UI
  code (constitution Principle III); this token set is the consistency mechanism. Any
  token change MUST update Flutter `ThemeData` and the portal Tailwind theme in the
  same change set.
- **DS-06 (Map styling)**: Light, low-contrast basemap (OpenFreeMap Positron class) so
  the orange marker/trail and status colors carry all meaning. The auto is an orange
  puck with a white ring and soft glow; the home pin is ink with a white ring.

### Design Tokens (v2)

**Ink & neutrals** — `ink #0B0B0F` · `sub #6B7280` · `faint #9CA3AF` ·
`surface #FFFFFF` · `bg #F6F6F8` · `line #ECECEE`
**Accent (DS-02)** — `orange #EA580C` · `orange-pressed #C2410C` ·
`orange-soft #FFF1E7` · `orange-line #FED7AA`
**Status (functional only)** — success `#0F8A3D` (soft `#E8F6EE`) ·
warning `#B45309` (soft `#FEF3C7`) · danger `#D92D20` (soft `#FEE4E2`)
**Dark (app only)** — `surface #131316` · `bg #0B0B0F` · `line #26262B` ·
ink/sub invert; orange unchanged
**Typography** — system grotesque (EN) + Noto Sans Kannada (KN):
Display 26/32 (800, −0.02 em) · Headline 22/28 (800) · Title 17/24 (700) ·
Body 14/20 (400) · Label 13/18 (600). Driver floor per DS-03.
**Shape** — sheet top 28 dp · card 16 dp · button 14 dp · chip/pill full ·
input 12 dp · floating circular button 44 dp
**Elevation** — cards/floats `0 8px 24px rgba(11,11,15,.14)` +
`0 2px 6px rgba(11,11,15,.08)`; sheets `0 −12px 40px rgba(11,11,15,.16)`;
portal cards `0 8px 28px rgba(11,11,15,.06)`; borders are not used where a
shadow can do the separation
**Spacing** — 8 dp grid, 4 dp half-steps; sheet padding 20 dp; screen margins 16 dp
## Assumptions

- **Locked decisions (from SPEC-WCT-001 §1.4)**: Android-only launch (Android 8+ / 2 GB RAM floor);
  residents are individual houses only (no apartments/RWAs); operator-agnostic multi-tenancy (BBMP and
  private contractors); tracking only — no payments; driver phones are BYOD with no MDM; passes/day
  configurable per route (default 1); zero-cost map tiles (no per-request billed map services), map
  provider swappable later.
- **Out of scope for v1**: iOS, payments/fees, apartments/bulk generators, route optimization,
  weighing/IoT, SMS/IVR fallback.
- Official ward boundary files (GeoJSON/KML) are procurable; licensing is an open item and does not
  block the build (sample/manual boundaries suffice for pilot).
- SMS OTP delivery uses an India DLT-registered provider; template registration starts immediately due
  to lead time (risk noted in source doc).
- Driver identity privacy (FR-RES-07) and trip-only tracking are compliance requirements (DPDP Act
  2023): explicit consent for phone & location, data residency in India, user data deletion supported,
  raw position data retained 90 days / aggregates 2 years.
- Open items from SPEC-WCT-001 §12 (complaint SLA values, image-upload policy, waste-schedule ownership,
  ratings granularity, boundary licensing) are deferred configuration/policy decisions, not MVP
  blockers.
- **Constitution note (for planning)**: The framework conflict between this spec's §9 and constitution
  v2.0.0 was resolved by constitution amendment v3.0.0 (2026-07-29) in favor of the spec: Flutter in
  `apps/mobile`, React + TypeScript in `apps/web`, and the spec's NestJS-or-Spring-Boot option resolved
  to a Node.js (TypeScript) backend. Contracts are backend-owned (OpenAPI) with a generated Dart client.
- The existing scaffolded citizen black-spot reporting slice predates this spec; this feature redefines
  the product around collection tracking. Reuse or retirement of the existing scaffold is a planning
  decision.
- **Infrastructure deferral (analyze finding C1, 2026-07-29)**: NFR-10 (Terraform, blue-green,
  PITR) and formal NFR-02 availability measurement are deferred past MVP: the pilot runs on a
  single managed environment in ap-south-1 with provider-managed backups; full infra-as-code and
  blue-green deploys are required before city rollout. The pilot device matrix (SC-007) is a
  pilot-planning artifact owned outside this spec.
