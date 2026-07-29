-- Up Migration

-- ST_Overlaps is false when one polygon lies entirely inside another, so a ward
-- nested in another ward, or a route nested in a sibling route, slipped past the
-- original checks. That breaks the guarantee FR-ROUTE-05 exists to provide:
-- exactly one route can contain a household pin.
--
-- ST_Relate(a, b, 'T********') asks the question we actually mean — do the two
-- interiors intersect at all — which covers partial overlap and containment
-- alike, while still allowing shapes that merely share an edge.

CREATE OR REPLACE FUNCTION assert_ward_no_overlap() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE conflict_name text;
BEGIN
  SELECT w.name INTO conflict_name
  FROM wards w
  WHERE w.id <> NEW.id
    AND w.city_id = NEW.city_id
    AND w.status = 'active'
    AND ST_Relate(w.boundary, NEW.boundary, 'T********')
  LIMIT 1;

  IF conflict_name IS NOT NULL THEN
    RAISE EXCEPTION 'Ward boundary overlaps existing ward: %', conflict_name
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION assert_route_area_valid() RETURNS trigger
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
    AND ST_Relate(r.serviceable_area, NEW.serviceable_area, 'T********')
  LIMIT 1;

  IF conflict_name IS NOT NULL THEN
    RAISE EXCEPTION 'Route area overlaps existing route: %', conflict_name
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN NEW;
END;
$$;

-- Down Migration

CREATE OR REPLACE FUNCTION assert_ward_no_overlap() RETURNS trigger
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

CREATE OR REPLACE FUNCTION assert_route_area_valid() RETURNS trigger
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
