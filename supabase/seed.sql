-- Dev seed: two toy ward boundaries around central Bengaluru and a few
-- sample reports so the map has pins on first run. Real BBMP ward GeoJSON
-- import lands later (scripts/import-wards).
insert into wards (ward_number, name_en, name_kn, zone, boundary) values
  (110, 'Shanthala Nagar (sample)', 'ಶಾಂತಲಾ ನಗರ', 'East',
   st_multi(st_geomfromtext('POLYGON((77.58 12.95, 77.62 12.95, 77.62 12.99, 77.58 12.99, 77.58 12.95))', 4326))),
  (154, 'Basavanagudi (sample)', 'ಬಸವನಗುಡಿ', 'South',
   st_multi(st_geomfromtext('POLYGON((77.56 12.92, 77.60 12.92, 77.60 12.95, 77.56 12.95, 77.56 12.92))', 4326)));

insert into reports (category, description, location) values
  ('illegal_dumping', 'Construction debris dumped on the footpath', st_geographyfromtext('SRID=4326;POINT(77.600 12.970)')),
  ('overflowing_bin', 'Bin not cleared for 3 days', st_geographyfromtext('SRID=4326;POINT(77.585 12.935)')),
  ('waste_burning', 'Garbage being burnt near the park gate', st_geographyfromtext('SRID=4326;POINT(77.610 12.960)'));
