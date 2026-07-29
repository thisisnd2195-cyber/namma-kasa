# Namma Kasa — admin portal

Next.js portal for the people who run collection: Super Admins who set up a
city's wards and operators, and Ward Admins who run the routes, fleet and
complaints inside one ward.

## Running

```sh
pnpm --filter @namma-kasa/web dev      # :3000
```

Needs the API on `:4000` and its infrastructure up; see
[../../docs/operations.md](../../docs/operations.md). Point elsewhere with
`NEXT_PUBLIC_API_BASE`.

## Pages

| Route | Purpose |
|---|---|
| `/dashboard` | City rollups: coverage, complaints, SLA breaches, missed pickups |
| `/wards` | Boundaries — draw, bulk-import GeoJSON, resolve overlaps |
| `/routes` | Service areas, schedules, passes, adopting a driven path |
| `/fleet` | Autos, drivers, and their time-bounded assignments |
| `/live` | Active autos on a map, tracking health, driver-reported problems |
| `/review-queue` | Households automatic mapping could not place |
| `/complaints` | The queue, each with the GPS evidence that answers it |

## Types come from the contract

The portal imports Zod types from `@namma-kasa/shared` rather than redeclaring
them. Redeclaring a shape the backend owns is a defect — Constitution Principle
IV.

Dates cross the wire as ISO strings while Zod infers them as `Date`, so pages
map through a local `Wire<T>` type. That is the one honest exception, and it is
narrow on purpose.

## Design tokens

Colours, type scale and radii are CSS custom properties in `@theme`
(Tailwind v4), Google/Material-3-aligned and deliberately neutral. Use
`var(--color-…)` and `text-[length:var(--text-…)]` rather than literal values, so
a token change lands everywhere at once.

The portal targets WCAG 2.1 AA.

## Authorization is not the portal's job

`PortalShell` gates rendering on a session, but that is cosmetic — it only avoids
drawing a shell the user cannot fill. **The API enforces every rule regardless**,
including pinning a Ward Admin to their own ward server-side. Never treat a
client-side check as a control.
