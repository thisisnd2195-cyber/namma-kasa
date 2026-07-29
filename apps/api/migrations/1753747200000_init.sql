-- Up Migration

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------- enums

CREATE TYPE operator_type       AS ENUM ('bbmp', 'private');
CREATE TYPE lifecycle_status    AS ENUM ('active', 'retired');
CREATE TYPE user_role           AS ENUM ('resident', 'driver', 'ward_admin', 'super_admin');
CREATE TYPE auth_provider       AS ENUM ('password', 'google');
CREATE TYPE user_status         AS ENUM ('active', 'blocked');
CREATE TYPE locale_code         AS ENUM ('en', 'kn');
CREATE TYPE auto_status         AS ENUM ('available', 'assigned', 'maintenance', 'retired');
CREATE TYPE driver_status       AS ENUM ('active', 'inactive');
CREATE TYPE mapping_status      AS ENUM ('auto', 'admin_corrected', 'pending_review');
CREATE TYPE trip_status         AS ENUM ('active', 'completed', 'aborted');
CREATE TYPE trip_end_reason     AS ENUM ('driver', 'auto_idle', 'admin');
CREATE TYPE pass_status         AS ENUM ('pending', 'active', 'completed', 'aborted', 'skipped');
CREATE TYPE waste_type          AS ENUM ('wet', 'dry', 'sanitary', 'hazardous', 'ewaste');
CREATE TYPE media_type          AS ENUM ('collection_proof', 'issue', 'other');
CREATE TYPE complaint_category  AS ENUM ('missed_pickup', 'late', 'behavior', 'segregation', 'other');
CREATE TYPE complaint_status    AS ENUM ('open', 'in_review', 'resolved', 'rejected');
CREATE TYPE notification_kind   AS ENUM ('proximity', 'arrival', 'schedule_change', 'complaint_status');

-- ---------------------------------------------------------------- tenancy & identity

CREATE TABLE operators (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL UNIQUE CHECK (length(trim(name)) > 0),
  type        operator_type NOT NULL,
  config      jsonb NOT NULL DEFAULT '{}'::jsonb,
  status      lifecycle_status NOT NULL DEFAULT 'active',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone          text NOT NULL UNIQUE,
  email          text,
  password_hash  text,
  auth_provider  auth_provider NOT NULL,
  role           user_role NOT NULL,
  locale         locale_code NOT NULL DEFAULT 'en',
  status         user_status NOT NULL DEFAULT 'active',
  -- Consent to phone/location processing (DPDP, NFR-04). Drivers additionally
  -- consent to trip-time tracking; withdrawal deactivates the driver.
  consented_at   timestamptz,
  deletion_requested_at timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT users_credential_present CHECK (
    (auth_provider = 'password' AND password_hash IS NOT NULL) OR
    (auth_provider = 'google'   AND email IS NOT NULL)
  )
);

-- A Google identity links to at most one user (Clarifications CHK011).
CREATE UNIQUE INDEX users_email_google_idx ON users (lower(email)) WHERE auth_provider = 'google';

CREATE TABLE refresh_tokens (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  token_hash   text NOT NULL UNIQUE,
  device_id    text,
  expires_at   timestamptz NOT NULL,
  rotated_from uuid REFERENCES refresh_tokens (id) ON DELETE SET NULL,
  revoked_at   timestamptz,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX refresh_tokens_user_idx ON refresh_tokens (user_id) WHERE revoked_at IS NULL;

-- Drivers are limited to one active device (Clarifications CHK012); residents are not.
CREATE TABLE device_tokens (
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  fcm_token  text NOT NULL,
  platform   text NOT NULL DEFAULT 'android',
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, fcm_token)
);

-- ---------------------------------------------------------------- geography

CREATE TABLE wards (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id        uuid NOT NULL REFERENCES operators (id),
  city_id            text NOT NULL DEFAULT 'blr',
  name               text NOT NULL,
  ward_code          text NOT NULL,
  boundary           geometry(MultiPolygon, 4326) NOT NULL,
  ward_admin_user_id uuid REFERENCES users (id) ON DELETE SET NULL,
  status             lifecycle_status NOT NULL DEFAULT 'active',
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),
  UNIQUE (city_id, ward_code)
);
CREATE INDEX wards_boundary_idx ON wards USING GIST (boundary);
-- One ward per ward admin (FR-WARD-06).
CREATE UNIQUE INDEX wards_admin_unique_idx ON wards (ward_admin_user_id)
  WHERE ward_admin_user_id IS NOT NULL;

CREATE TABLE routes (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ward_id             uuid NOT NULL REFERENCES wards (id) ON DELETE RESTRICT,
  name                text NOT NULL,
  route_code          text NOT NULL,
  serviceable_area    geometry(MultiPolygon, 4326) NOT NULL,
  path                geometry(LineString, 4326),
  collection_days     smallint[] NOT NULL CHECK (
                        array_length(collection_days, 1) > 0
                        AND collection_days <@ ARRAY[1,2,3,4,5,6,7]::smallint[]
                      ),
  window_start        time NOT NULL,
  window_end          time NOT NULL CHECK (window_end > window_start),
  passes_per_day      integer NOT NULL DEFAULT 1 CHECK (passes_per_day >= 1),
  waste_type_schedule jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (ward_id, route_code)
);
CREATE INDEX routes_area_idx ON routes USING GIST (serviceable_area);

-- ---------------------------------------------------------------- fleet

CREATE TABLE autos (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_number text NOT NULL UNIQUE
                        CHECK (registration_number ~ '^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{4}$'),
  capacity_kg         integer CHECK (capacity_kg > 0),
  ward_id             uuid NOT NULL REFERENCES wards (id) ON DELETE RESTRICT,
  photos              text[] NOT NULL DEFAULT '{}',
  status              auto_status NOT NULL DEFAULT 'available',
  onboarded_by        uuid REFERENCES users (id) ON DELETE SET NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX autos_ward_idx ON autos (ward_id, status);

CREATE TABLE drivers (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           uuid UNIQUE REFERENCES users (id) ON DELETE SET NULL,
  ward_id           uuid NOT NULL REFERENCES wards (id) ON DELETE RESTRICT,
  full_name         text NOT NULL,
  -- The pre-provisioning key: driver signup requires a matching row (FR-AUTH-05).
  phone             text NOT NULL UNIQUE,
  license_number    text NOT NULL,
  photo_url         text,
  emergency_contact text,
  status            driver_status NOT NULL DEFAULT 'active',
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE auto_route_assignments (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auto_id        uuid NOT NULL REFERENCES autos (id) ON DELETE CASCADE,
  route_id       uuid NOT NULL REFERENCES routes (id) ON DELETE CASCADE,
  assigned_by    uuid REFERENCES users (id) ON DELETE SET NULL,
  effective_from timestamptz NOT NULL DEFAULT now(),
  effective_to   timestamptz,
  CHECK (effective_to IS NULL OR effective_to > effective_from)
);
-- One active route per auto (FR-FLEET-02).
CREATE UNIQUE INDEX auto_route_active_idx ON auto_route_assignments (auto_id)
  WHERE effective_to IS NULL;

CREATE TABLE driver_auto_assignments (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id      uuid NOT NULL REFERENCES drivers (id) ON DELETE CASCADE,
  auto_id        uuid NOT NULL REFERENCES autos (id) ON DELETE CASCADE,
  assigned_by    uuid REFERENCES users (id) ON DELETE SET NULL,
  effective_from timestamptz NOT NULL DEFAULT now(),
  effective_to   timestamptz,
  CHECK (effective_to IS NULL OR effective_to > effective_from)
);
-- Exactly one active driver per auto, and one active auto per driver (FR-FLEET-03).
CREATE UNIQUE INDEX driver_auto_active_driver_idx ON driver_auto_assignments (driver_id)
  WHERE effective_to IS NULL;
CREATE UNIQUE INDEX driver_auto_active_auto_idx ON driver_auto_assignments (auto_id)
  WHERE effective_to IS NULL;

-- ---------------------------------------------------------------- residents

CREATE TABLE households (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               uuid NOT NULL UNIQUE REFERENCES users (id) ON DELETE CASCADE,
  full_name             text NOT NULL,
  address_line          text NOT NULL,
  landmark              text,
  house_geo             geometry(Point, 4326) NOT NULL,
  ward_id               uuid REFERENCES wards (id) ON DELETE SET NULL,
  route_id              uuid REFERENCES routes (id) ON DELETE SET NULL,
  mapping_status        mapping_status NOT NULL DEFAULT 'pending_review',
  notification_radius_m integer NOT NULL DEFAULT 300
                          CHECK (notification_radius_m BETWEEN 100 AND 1000),
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX households_geo_idx ON households USING GIST (house_geo);
CREATE INDEX households_route_idx ON households (route_id);
CREATE INDEX households_review_idx ON households (ward_id, created_at)
  WHERE mapping_status = 'pending_review';

-- ---------------------------------------------------------------- operations

CREATE TABLE trips (
  id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auto_id            uuid NOT NULL REFERENCES autos (id) ON DELETE RESTRICT,
  driver_id          uuid NOT NULL REFERENCES drivers (id) ON DELETE RESTRICT,
  route_id           uuid NOT NULL REFERENCES routes (id) ON DELETE RESTRICT,
  pass_number        integer NOT NULL CHECK (pass_number >= 1),
  service_date       date NOT NULL,
  started_at         timestamptz NOT NULL DEFAULT now(),
  ended_at           timestamptz,
  status             trip_status NOT NULL DEFAULT 'active',
  end_reason         trip_end_reason,
  distance_covered_m integer,
  created_at         timestamptz NOT NULL DEFAULT now()
);
-- One active trip per auto.
CREATE UNIQUE INDEX trips_active_auto_idx ON trips (auto_id) WHERE status = 'active';
CREATE INDEX trips_route_date_idx ON trips (route_id, service_date);

-- Pass state per route per service day; carries the `skipped` outcome that a
-- trip row cannot express (FR-DRV-02).
CREATE TABLE route_pass_days (
  route_id     uuid NOT NULL REFERENCES routes (id) ON DELETE CASCADE,
  service_date date NOT NULL,
  pass_number  integer NOT NULL CHECK (pass_number >= 1),
  status       pass_status NOT NULL DEFAULT 'pending',
  trip_id      uuid REFERENCES trips (id) ON DELETE SET NULL,
  updated_at   timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (route_id, service_date, pass_number)
);

CREATE TABLE location_pings (
  trip_id     uuid NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
  auto_id     uuid NOT NULL REFERENCES autos (id) ON DELETE CASCADE,
  lat         double precision NOT NULL,
  lng         double precision NOT NULL,
  speed       real,
  heading     real,
  accuracy_m  real,
  recorded_at timestamptz NOT NULL,
  received_at timestamptz NOT NULL DEFAULT now()
);
SELECT create_hypertable('location_pings', 'recorded_at', chunk_time_interval => INTERVAL '1 day');
CREATE INDEX location_pings_trip_idx ON location_pings (trip_id, recorded_at DESC);

-- Automatic pickup evidence: first ping within 75 m of the house during a pass
-- (Clarifications CHK002). Drives last-collected and the rating trigger.
CREATE TABLE household_collections (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id uuid NOT NULL REFERENCES households (id) ON DELETE CASCADE,
  trip_id      uuid NOT NULL REFERENCES trips (id) ON DELETE CASCADE,
  route_id     uuid NOT NULL REFERENCES routes (id) ON DELETE CASCADE,
  pass_number  integer NOT NULL,
  detected_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (household_id, trip_id)
);
CREATE INDEX household_collections_household_idx
  ON household_collections (household_id, detected_at DESC);

CREATE TABLE media_uploads (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id     uuid REFERENCES trips (id) ON DELETE CASCADE,
  driver_id   uuid REFERENCES drivers (id) ON DELETE SET NULL,
  type        media_type NOT NULL DEFAULT 'collection_proof',
  object_url  text NOT NULL,
  geo         geometry(Point, 4326),
  captured_at timestamptz NOT NULL DEFAULT now(),
  -- 180-day retention, extended while attached to an open complaint (CHK015).
  expires_at  timestamptz NOT NULL DEFAULT (now() + INTERVAL '180 days')
);
CREATE INDEX media_uploads_trip_idx ON media_uploads (trip_id);

-- ---------------------------------------------------------------- feedback

CREATE TABLE complaints (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    uuid NOT NULL REFERENCES households (id) ON DELETE CASCADE,
  route_id        uuid REFERENCES routes (id) ON DELETE SET NULL,
  ward_id         uuid NOT NULL REFERENCES wards (id) ON DELETE RESTRICT,
  category        complaint_category NOT NULL,
  description     text CHECK (description IS NULL OR length(description) <= 2000),
  media_urls      text[] NOT NULL DEFAULT '{}' CHECK (array_length(media_urls, 1) IS NULL
                                                      OR array_length(media_urls, 1) <= 3),
  status          complaint_status NOT NULL DEFAULT 'open',
  assigned_to     uuid REFERENCES users (id) ON DELETE SET NULL,
  sla_due_at      timestamptz,
  resolution_note text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX complaints_ward_status_idx ON complaints (ward_id, status, created_at DESC);
CREATE INDEX complaints_household_idx ON complaints (household_id, created_at DESC);

CREATE TABLE complaint_events (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_id uuid NOT NULL REFERENCES complaints (id) ON DELETE CASCADE,
  actor_id     uuid REFERENCES users (id) ON DELETE SET NULL,
  from_status  complaint_status,
  to_status    complaint_status NOT NULL,
  note         text,
  at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX complaint_events_complaint_idx ON complaint_events (complaint_id, at);

CREATE TABLE ratings (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id    uuid NOT NULL REFERENCES households (id) ON DELETE CASCADE,
  route_id        uuid REFERENCES routes (id) ON DELETE SET NULL,
  trip_id         uuid REFERENCES trips (id) ON DELETE SET NULL,
  stars           smallint NOT NULL CHECK (stars BETWEEN 1 AND 5),
  comment         text,
  collection_date date NOT NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  -- One rating per household per IST collection day (FR-CMP-05).
  UNIQUE (household_id, collection_date)
);

CREATE TABLE notifications (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  kind       notification_kind NOT NULL,
  payload    jsonb NOT NULL,
  -- Proximity dedup is per household per pass: prox:{household}:{route}:{date}:{pass}
  dedup_key  text UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  sent_at    timestamptz
);
CREATE INDEX notifications_outbox_idx ON notifications (created_at) WHERE sent_at IS NULL;

CREATE TABLE audit_log (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id    uuid REFERENCES users (id) ON DELETE SET NULL,
  entity_type text NOT NULL,
  entity_id   uuid,
  action      text NOT NULL,
  before      jsonb,
  after       jsonb,
  at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_log_entity_idx ON audit_log (entity_type, entity_id, at DESC);

-- ---------------------------------------------------------------- geo invariants

-- Invariant 1: ward boundaries never overlap (FR-WARD-05).
CREATE FUNCTION assert_ward_no_overlap() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE conflict_name text;
BEGIN
  SELECT w.name INTO conflict_name
  FROM wards w
  WHERE w.id <> NEW.id
    AND w.city_id = NEW.city_id
    AND w.status = 'active'
    AND ST_Overlaps(w.boundary, NEW.boundary)
  LIMIT 1;

  IF conflict_name IS NOT NULL THEN
    RAISE EXCEPTION 'Ward boundary overlaps existing ward: %', conflict_name
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER wards_no_overlap
  BEFORE INSERT OR UPDATE OF boundary ON wards
  FOR EACH ROW EXECUTE FUNCTION assert_ward_no_overlap();

-- Invariants 2 and 2b: route areas sit inside their ward and never overlap a
-- sibling route, which is what makes household -> route mapping deterministic
-- (FR-ROUTE-01, FR-ROUTE-05).
CREATE FUNCTION assert_route_area_valid() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE conflict_name text;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM wards w
    WHERE w.id = NEW.ward_id AND ST_Within(NEW.serviceable_area, w.boundary)
  ) THEN
    RAISE EXCEPTION 'Route serviceable area must lie within its ward boundary'
      USING ERRCODE = 'check_violation';
  END IF;

  SELECT r.name INTO conflict_name
  FROM routes r
  WHERE r.id <> NEW.id
    AND r.ward_id = NEW.ward_id
    AND ST_Overlaps(r.serviceable_area, NEW.serviceable_area)
  LIMIT 1;

  IF conflict_name IS NOT NULL THEN
    RAISE EXCEPTION 'Route area overlaps existing route: %', conflict_name
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER routes_area_valid
  BEFORE INSERT OR UPDATE OF serviceable_area, ward_id ON routes
  FOR EACH ROW EXECUTE FUNCTION assert_route_area_valid();

-- Invariant 3: an auto may only be assigned to a route in its own ward.
CREATE FUNCTION assert_auto_route_same_ward() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT a.ward_id FROM autos a WHERE a.id = NEW.auto_id)
     IS DISTINCT FROM
     (SELECT r.ward_id FROM routes r WHERE r.id = NEW.route_id) THEN
    RAISE EXCEPTION 'Auto and route must belong to the same ward'
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER auto_route_same_ward
  BEFORE INSERT OR UPDATE ON auto_route_assignments
  FOR EACH ROW EXECUTE FUNCTION assert_auto_route_same_ward();

-- Invariant 6 (complaints half): every status transition is journalled.
CREATE FUNCTION log_complaint_event() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO complaint_events (complaint_id, actor_id, from_status, to_status)
    VALUES (NEW.id, NULL, NULL, NEW.status);
  ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
    INSERT INTO complaint_events (complaint_id, actor_id, from_status, to_status, note)
    VALUES (NEW.id, NEW.assigned_to, OLD.status, NEW.status, NEW.resolution_note);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER complaints_log_event
  AFTER INSERT OR UPDATE OF status ON complaints
  FOR EACH ROW EXECUTE FUNCTION log_complaint_event();

-- Down Migration

DROP TRIGGER IF EXISTS complaints_log_event ON complaints;
DROP TRIGGER IF EXISTS auto_route_same_ward ON auto_route_assignments;
DROP TRIGGER IF EXISTS routes_area_valid ON routes;
DROP TRIGGER IF EXISTS wards_no_overlap ON wards;
DROP FUNCTION IF EXISTS log_complaint_event();
DROP FUNCTION IF EXISTS assert_auto_route_same_ward();
DROP FUNCTION IF EXISTS assert_route_area_valid();
DROP FUNCTION IF EXISTS assert_ward_no_overlap();

DROP TABLE IF EXISTS audit_log, notifications, ratings, complaint_events, complaints,
  media_uploads, household_collections, location_pings, route_pass_days, trips,
  households, driver_auto_assignments, auto_route_assignments, drivers, autos,
  routes, wards, device_tokens, refresh_tokens, users, operators CASCADE;

DROP TYPE IF EXISTS notification_kind, complaint_status, complaint_category, media_type,
  waste_type, pass_status, trip_end_reason, trip_status, mapping_status, driver_status,
  auto_status, locale_code, user_status, auth_provider, user_role, lifecycle_status,
  operator_type;
