-- Up Migration

-- routes.path was created by the init migration and never read or written by
-- any code. FR-ROUTE-04 is now served by recorded_path, which also carries the
-- trip it came from and when it was adopted. Two columns for one idea is how
-- the wrong one eventually gets used.

ALTER TABLE routes DROP COLUMN IF EXISTS path;

-- Down Migration

ALTER TABLE routes ADD COLUMN path geography(LineString, 4326);
