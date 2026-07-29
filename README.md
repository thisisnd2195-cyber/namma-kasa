# Namma Kasa — ನಮ್ಮ ಕಸ

Citizen-facing waste reporting for Bengaluru: photograph a garbage black spot, it lands on
a public map with GPS + ward attribution, and its resolution is tracked end-to-end.

## Stack

| Layer | Tech |
|---|---|
| Android app | Expo (React Native, TypeScript, Expo Router) — `apps/mobile` |
| Web app | Next.js App Router + Tailwind — `apps/web` |
| Shared core | Zod schemas + Supabase data helpers — `packages/shared` |
| Backend | Supabase: Postgres + PostGIS, Auth, Storage — `supabase/` |
| Maps | MapLibre GL + OpenStreetMap tiles |

One TypeScript codebase in a pnpm + Turborepo workspace. The data model lives once in
`packages/shared` and is validated identically on mobile, web, and (later) edge functions.

## Getting started

Prereqs: Node ≥ 22, pnpm (`npm i -g pnpm`), Docker Desktop (for local Supabase),
Supabase CLI (`brew install supabase/tap/supabase`).

```sh
pnpm install

# 1. Backend — starts Postgres/PostGIS, applies migrations, loads seed data
supabase start          # prints API URL + anon key

# 2. Web
cp apps/web/.env.example apps/web/.env.local   # paste the anon key
pnpm --filter @namma-kasa/web dev              # http://localhost:3000

# 3. Android (Expo Go on your phone, same Wi-Fi)
cp apps/mobile/.env.example apps/mobile/.env   # use your LAN IP + anon key
pnpm --filter @namma-kasa/mobile start
```

Without Supabase configured, both apps still run and show an empty map / a
"backend not configured" notice.

## Repo layout

```
apps/web            Next.js — public map (/), /reports/[id], /wards/[id]
apps/mobile         Expo — report flow (camera → GPS → submit), recent reports
packages/shared     Zod schemas, Supabase client + report helpers
supabase/           config.toml, migrations (schema/RLS/storage), seed.sql
```

## Data model

`reports` (geography point, generated lat/lng, auto ward assignment via PostGIS
point-in-polygon trigger) · `report_photos` (evidence/resolution, Storage-backed) ·
`report_events` (full status audit trail via trigger) · `wards` (BBMP boundaries;
seed ships two sample wards). Anonymous reporting is allowed; the public
`reports_public` view never exposes reporter identity. RLS: public read, insert
restricted to open reports inside Bengaluru bounds, status changes reserved for
the service role until the supervisor console lands.

## Commands

```sh
pnpm build       # turbo: build all workspaces
pnpm typecheck   # turbo: tsc across all workspaces
pnpm lint        # turbo: eslint / tsc
supabase db reset  # re-apply migrations + seed
```

## Roadmap

MVP (current): report loop + public map + seed wards. Next: phone-OTP auth, real BBMP
ward GeoJSON import, segregation guide (kn/en), ward scorecards, supervisor console.
