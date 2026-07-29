-- Namma Kasa initial schema
create extension if not exists postgis;

create type report_category as enum (
  'illegal_dumping',
  'overflowing_bin',
  'waste_burning',
  'missed_pickup',
  'dead_animal',
  'other'
);

create type report_status as enum ('open', 'acknowledged', 'resolved', 'verified');

create type photo_kind as enum ('evidence', 'resolution');

create table wards (
  id serial primary key,
  ward_number integer not null unique,
  name_en text not null,
  name_kn text not null,
  zone text not null,
  boundary geometry(MultiPolygon, 4326) not null
);

create index wards_boundary_idx on wards using gist (boundary);

create table reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users (id) on delete set null,
  category report_category not null,
  description text,
  location geography(Point, 4326) not null,
  -- Flat lat/lng so clients never need to parse WKB.
  lat double precision generated always as (st_y(location::geometry)) stored,
  lng double precision generated always as (st_x(location::geometry)) stored,
  ward_id integer references wards (id),
  status report_status not null default 'open',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolution_note text
);

create index reports_location_idx on reports using gist (location);
create index reports_status_idx on reports (status);
create index reports_ward_idx on reports (ward_id);

create table report_photos (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references reports (id) on delete cascade,
  url text not null,
  kind photo_kind not null default 'evidence',
  created_at timestamptz not null default now()
);

create table report_events (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references reports (id) on delete cascade,
  actor_id uuid references auth.users (id) on delete set null,
  from_status report_status,
  to_status report_status not null,
  at timestamptz not null default now()
);

-- Assign the containing ward on insert.
create function assign_ward() returns trigger
language plpgsql as $$
begin
  new.ward_id := (
    select w.id from wards w
    where st_contains(w.boundary, new.location::geometry)
    limit 1
  );
  return new;
end;
$$;

create trigger reports_assign_ward
  before insert on reports
  for each row execute function assign_ward();

-- Audit trail: log every status transition (including creation).
create function log_report_event() returns trigger
language plpgsql security definer as $$
begin
  if tg_op = 'INSERT' then
    insert into report_events (report_id, actor_id, from_status, to_status)
    values (new.id, new.reporter_id, null, new.status);
  elsif new.status is distinct from old.status then
    insert into report_events (report_id, actor_id, from_status, to_status)
    values (new.id, auth.uid(), old.status, new.status);
    if new.status = 'resolved' then
      new.resolved_at := now();
    end if;
  end if;
  return new;
end;
$$;

create trigger reports_log_event_insert
  after insert on reports
  for each row execute function log_report_event();

create trigger reports_log_event_update
  before update on reports
  for each row execute function log_report_event();

-- Public, anonymized view for the map (no reporter_id).
create view reports_public with (security_invoker = on) as
  select id, category, description, lat, lng, ward_id, status,
         created_at, resolved_at, resolution_note,
         null::uuid as reporter_id
  from reports;

-- Row-level security: everyone can read; anyone (incl. anonymous) can file
-- a report inside Bengaluru; only supervisors change status (later phase —
-- for now updates stay locked down to service role).
alter table wards enable row level security;
alter table reports enable row level security;
alter table report_photos enable row level security;
alter table report_events enable row level security;

create policy "wards are public" on wards for select using (true);
create policy "reports are public" on reports for select using (true);
create policy "photos are public" on report_photos for select using (true);
create policy "events are public" on report_events for select using (true);

create policy "anyone can file a report" on reports for insert
  with check (
    status = 'open'
    and st_y(location::geometry) between 12.7 and 13.25
    and st_x(location::geometry) between 77.3 and 77.9
  );

create policy "anyone can attach evidence photos" on report_photos for insert
  with check (kind = 'evidence');

-- Photo storage bucket (public read).
insert into storage.buckets (id, name, public)
values ('report-photos', 'report-photos', true);

create policy "report photos are public" on storage.objects for select
  using (bucket_id = 'report-photos');

create policy "anyone can upload report photos" on storage.objects for insert
  with check (bucket_id = 'report-photos');
