-- Up Migration

-- A driver who breaks down or finds the road blocked needs one tap to say so,
-- and the Ward Admin needs to know before residents start asking why the auto
-- never came (FR-DRV-07). Without this the only signal is the absence of pings,
-- which looks identical to a dead phone.

CREATE TYPE driver_issue_kind AS ENUM ('breakdown', 'road_blocked', 'other');

CREATE TABLE driver_issues (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id     uuid REFERENCES trips (id) ON DELETE SET NULL,
  driver_id   uuid NOT NULL REFERENCES drivers (id) ON DELETE CASCADE,
  route_id    uuid REFERENCES routes (id) ON DELETE SET NULL,
  ward_id     uuid NOT NULL REFERENCES wards (id) ON DELETE CASCADE,
  kind        driver_issue_kind NOT NULL,
  note        text,
  -- Where the auto was when it was reported; a blocked road is a place.
  geo         geography(Point, 4326),
  acknowledged_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- The admin queue reads open issues for one ward, newest first.
CREATE INDEX driver_issues_ward_idx ON driver_issues (ward_id, created_at DESC);
CREATE INDEX driver_issues_open_idx ON driver_issues (ward_id) WHERE acknowledged_at IS NULL;

ALTER TYPE notification_kind ADD VALUE IF NOT EXISTS 'driver_issue';

-- Down Migration

-- Postgres cannot drop a value from an enum, so notification_kind keeps
-- 'driver_issue'. It is unreachable once the table is gone.
DROP TABLE IF EXISTS driver_issues;
DROP TYPE IF EXISTS driver_issue_kind;
