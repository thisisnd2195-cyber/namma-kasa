-- Up Migration

-- FR-ROUTE-04: a route's path can be learned from a trip that has already been
-- driven, rather than traced by hand in the portal. Stored on the route because
-- it is a property of the route, not of the trip it was derived from — and the
-- trip's own trail lives in position_pings, which is dropped after 90 days.

ALTER TABLE routes
  ADD COLUMN recorded_path geography(LineString, 4326),
  -- Which trip it came from, so an admin can see what they adopted, and
  -- ON DELETE SET NULL because the path outlives the trip's retention.
  ADD COLUMN recorded_path_trip_id uuid REFERENCES trips (id) ON DELETE SET NULL,
  ADD COLUMN recorded_path_at timestamptz;

-- Down Migration

ALTER TABLE routes
  DROP COLUMN IF EXISTS recorded_path,
  DROP COLUMN IF EXISTS recorded_path_trip_id,
  DROP COLUMN IF EXISTS recorded_path_at;
