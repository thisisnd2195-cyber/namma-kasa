"use client";

import { useCallback, useEffect, useState } from "react";
import { AreaMap, type Area } from "@/components/AreaMap";
import { PortalShell } from "@/components/PortalShell";
import { Banner, Field } from "@/app/wards/page";
import type { RecordableTrip, Route, Ward } from "@namma-kasa/shared";

/** Dates cross the wire as ISO strings; Zod infers them as Date. */
type WireTrip = Omit<RecordableTrip, "endedAt"> & { endedAt: string | null };
import { api, readSession } from "@/lib/session";

const WEEKDAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const WASTE_TYPES = ["wet", "dry", "sanitary", "hazardous", "ewaste"] as const;

/**
 * The route's driven path (FR-ROUTE-04). Drawing one by hand is slow and
 * approximate; an auto has already driven the real thing, so this offers the
 * completed trips and adopts one. Shows what is currently recorded, because a
 * path an admin cannot see is one they cannot tell is wrong.
 */
function RecordedPath({ route, onRecorded }: { route: Route; onRecorded: () => void }) {
  const [trips, setTrips] = useState<WireTrip[] | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const recorded = route.recordedPath;

  async function openPicker() {
    setError(null);
    try {
      setTrips(await api<WireTrip[]>(`/admin/routes/${route.id}/recordable-trips`));
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not load trips");
    }
  }

  async function adopt(tripId: string) {
    setBusy(true);
    setError(null);
    try {
      await api(`/admin/routes/${route.id}/recorded-path`, {
        method: "POST",
        body: JSON.stringify({ tripId }),
      });
      setTrips(null);
      onRecorded();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not record the path");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="mt-2">
      <div className="flex flex-wrap items-center gap-2">
        <span className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
          {recorded
            ? `Path recorded ${new Date(recorded.recordedAt).toLocaleDateString()} · ${recorded.geometry.coordinates.length} points`
            : "No path recorded"}
        </span>
        <button
          type="button"
          onClick={() => (trips ? setTrips(null) : void openPicker())}
          className="rounded-full border border-[var(--color-outline)] px-3 py-1 text-[length:var(--text-label)] hover:bg-[var(--color-surface-alt)]"
        >
          {recorded ? "Replace from a trip" : "Record from a trip"}
        </button>
      </div>

      {error && (
        <p role="alert" className="mt-1 text-[length:var(--text-label)] text-[var(--color-danger)]">
          {error}
        </p>
      )}

      {trips && (
        <ul className="mt-2 space-y-1">
          {trips.map((trip) => (
            <li key={trip.id} className="flex items-center gap-2">
              <span className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                {trip.serviceDate} · pass {trip.passNumber} · {trip.registrationNumber} ·{" "}
                {trip.positionCount} points
              </span>
              <button
                type="button"
                disabled={busy}
                onClick={() => void adopt(trip.id)}
                className="ml-auto rounded-full border border-[var(--color-outline)] px-3 py-1 text-[length:var(--text-label)] disabled:opacity-50"
              >
                Use this
              </button>
            </li>
          ))}
          {trips.length === 0 && (
            <li className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
              No completed trip on this route has enough positions yet.
            </li>
          )}
        </ul>
      )}
    </div>
  );
}

export default function RoutesPage() {
  const [wards, setWards] = useState<Ward[]>([]);
  const [wardId, setWardId] = useState<string>("");
  const [routes, setRoutes] = useState<Route[]>([]);
  const [drawn, setDrawn] = useState<Area | null>(null);
  const [name, setName] = useState("");
  const [routeCode, setRouteCode] = useState("");
  const [windowStart, setWindowStart] = useState("06:00");
  const [windowEnd, setWindowEnd] = useState("10:00");
  const [passesPerDay, setPassesPerDay] = useState(1);
  const [days, setDays] = useState<number[]>([1, 2, 3, 4, 5, 6]);
  const [schedule, setSchedule] = useState<Record<string, string[]>>({});
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const list = await api<Ward[]>("/admin/wards");
        if (cancelled) return;
        setWards(list);
        setWardId(readSession()?.wardId ?? list[0]?.id ?? "");
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load wards");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const loadRoutes = useCallback(async () => {
    if (!wardId) return;
    setRoutes(await api<Route[]>(`/admin/routes?wardId=${wardId}`));
  }, [wardId]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        await loadRoutes();
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [loadRoutes]);

  function toggleDay(day: number) {
    setDays((current) =>
      current.includes(day) ? current.filter((d) => d !== day) : [...current, day].sort(),
    );
  }

  function toggleWaste(day: number, waste: string) {
    setSchedule((current) => {
      const key = String(day);
      const existing = current[key] ?? [];
      const next = existing.includes(waste)
        ? existing.filter((w) => w !== waste)
        : [...existing, waste];
      return { ...current, [key]: next };
    });
  }

  async function createRoute(event: React.FormEvent) {
    event.preventDefault();
    if (!drawn) {
      setError("Draw the serviceable area on the map first");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await api<Route>("/admin/routes", {
        method: "POST",
        body: JSON.stringify({
          wardId,
          name,
          routeCode,
          serviceableArea: drawn,
          collectionDays: days,
          windowStart,
          windowEnd,
          passesPerDay,
          wasteTypeSchedule: Object.fromEntries(
            Object.entries(schedule).filter(([day, types]) => days.includes(Number(day)) && types.length > 0),
          ),
        }),
      });
      setName("");
      setRouteCode("");
      setDrawn(null);
      await loadRoutes();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not create route");
    } finally {
      setBusy(false);
    }
  }

  const ward = wards.find((w) => w.id === wardId);

  return (
    <PortalShell>
      <main className="grid gap-6 p-6 lg:grid-cols-[380px_1fr]">
        <section className="space-y-6">
          <div>
            <h1 className="text-[length:var(--text-headline)]">Routes</h1>
            <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
              A route&rsquo;s area must sit inside its ward and must not overlap another route.
            </p>
          </div>

          {wards.length > 1 && (
            <label className="block text-[length:var(--text-label)] font-medium">
              Ward
              <select
                value={wardId}
                onChange={(e) => setWardId(e.target.value)}
                className="mt-1 w-full rounded-[var(--radius-input)] border border-[var(--color-outline)] px-3 py-2 text-[length:var(--text-body)] font-normal"
              >
                {wards.map((w) => (
                  <option key={w.id} value={w.id}>
                    {w.wardCode} · {w.name}
                  </option>
                ))}
              </select>
            </label>
          )}

          {error && <Banner tone="danger">{error}</Banner>}

          <form
            onSubmit={createRoute}
            className="rounded-[var(--radius-card)] border border-[var(--color-outline)] p-4"
          >
            <h2 className="text-[length:var(--text-title)] font-medium">New route</h2>
            <Field label="Name" value={name} onChange={setName} required />
            <Field label="Route code" value={routeCode} onChange={setRouteCode} required />

            <div className="mt-3 grid grid-cols-3 gap-2">
              <Field label="From" value={windowStart} onChange={setWindowStart} type="time" />
              <Field label="To" value={windowEnd} onChange={setWindowEnd} type="time" />
              <label className="mt-3 block text-[length:var(--text-label)] font-medium">
                Passes
                <input
                  type="number"
                  min={1}
                  value={passesPerDay}
                  onChange={(e) => setPassesPerDay(Number(e.target.value))}
                  className="mt-1 w-full rounded-[var(--radius-input)] border border-[var(--color-outline)] px-3 py-2 text-[length:var(--text-body)] font-normal"
                />
              </label>
            </div>

            <fieldset className="mt-4">
              <legend className="text-[length:var(--text-label)] font-medium">
                Collection days and waste types
              </legend>
              <div className="mt-2 space-y-1.5">
                {WEEKDAYS.map((label, index) => {
                  const day = index + 1;
                  const on = days.includes(day);
                  return (
                    <div key={label} className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => toggleDay(day)}
                        className={`w-14 rounded-full px-2 py-1 text-[length:var(--text-label)] ${
                          on
                            ? "bg-[var(--color-primary)] text-white"
                            : "border border-[var(--color-outline)] text-[var(--color-text-secondary)]"
                        }`}
                      >
                        {label}
                      </button>
                      <div className="flex flex-wrap gap-1">
                        {WASTE_TYPES.map((waste) => {
                          const active = (schedule[String(day)] ?? []).includes(waste);
                          return (
                            <button
                              key={waste}
                              type="button"
                              disabled={!on}
                              onClick={() => toggleWaste(day, waste)}
                              className={`rounded-full px-2 py-0.5 text-[length:var(--text-label)] disabled:opacity-35 ${
                                active
                                  ? "bg-[var(--color-success-container)] text-[var(--color-success)]"
                                  : "border border-[var(--color-outline)] text-[var(--color-text-secondary)]"
                              }`}
                            >
                              {waste}
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  );
                })}
              </div>
            </fieldset>

            <p className="mt-3 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
              {drawn ? "Area captured." : "Click on the map to trace the serviceable area."}
            </p>
            <button
              type="submit"
              disabled={busy}
              className="mt-3 w-full rounded-full bg-[var(--color-primary)] px-4 py-2.5 text-[length:var(--text-body)] font-medium text-white hover:bg-[var(--color-primary-pressed)] disabled:opacity-60"
            >
              Create route
            </button>
          </form>

          <div className="rounded-[var(--radius-card)] border border-[var(--color-outline)]">
            <h2 className="border-b border-[var(--color-outline)] px-4 py-3 text-[length:var(--text-title)] font-medium">
              {routes.length} route{routes.length === 1 ? "" : "s"}
            </h2>
            <ul>
              {routes.map((route) => (
                <li key={route.id} className="border-b border-[var(--color-outline)] px-4 py-3 last:border-0">
                  <p className="text-[length:var(--text-body)] font-medium">
                    {route.routeCode} · {route.name}
                  </p>
                  <p className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                    {route.windowStart}–{route.windowEnd} · {route.passesPerDay} pass
                    {route.passesPerDay === 1 ? "" : "es"}/day ·{" "}
                    {route.collectionDays.map((d) => WEEKDAYS[d - 1]).join(" ")}
                  </p>
                  <RecordedPath route={route} onRecorded={loadRoutes} />
                </li>
              ))}
              {routes.length === 0 && (
                <li className="px-4 py-6 text-center text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
                  No routes in this ward yet.
                </li>
              )}
            </ul>
          </div>
        </section>

        <section className="overflow-hidden rounded-[var(--radius-card)] border border-[var(--color-outline)]">
          <AreaMap
            editable
            value={drawn}
            onChange={setDrawn}
            context={[
              ...(ward ? [{ area: ward.boundary, color: "#5F6368" }] : []),
              ...routes.map((r) => ({ area: r.serviceableArea, color: "#1A73E8" })),
            ]}
            className="h-[calc(100dvh-8rem)] w-full"
          />
        </section>
      </main>
    </PortalShell>
  );
}
