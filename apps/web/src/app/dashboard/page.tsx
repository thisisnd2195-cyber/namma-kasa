"use client";

import { useEffect, useState } from "react";
import { PortalShell } from "@/components/PortalShell";
import { Banner } from "@/app/wards/page";
import type { CityRollup, MissedPickup } from "@namma-kasa/shared";
import { api, readSession } from "@/lib/session";

/**
 * The city view a Super Admin opens first (FR-DASH-02): is the city being
 * served today, and where is it not. A Ward Admin has no city-wide rollup, so
 * they see only the missed-pickup list for their own ward.
 */
export default function DashboardPage() {
  const [rollup, setRollup] = useState<CityRollup | null>(null);
  const [missed, setMissed] = useState<MissedPickup[]>([]);
  const [error, setError] = useState<string | null>(null);
  const isSuperAdmin = readSession()?.role === "super_admin";

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        const [city, misses] = await Promise.all([
          isSuperAdmin ? api<CityRollup>("/admin/dashboard/city") : Promise.resolve(null),
          api<MissedPickup[]>("/admin/dashboard/missed-pickups"),
        ]);
        if (cancelled) return;
        setRollup(city);
        setMissed(misses);
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [isSuperAdmin]);

  return (
    <PortalShell>
      <main className="mx-auto max-w-5xl space-y-6 p-6">
        <div>
          <h1 className="text-[length:var(--text-headline)]">Today</h1>
          <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
            {isSuperAdmin
              ? "City-wide collection, complaints, and the streets nobody reached."
              : "Households in your ward whose collection window has closed with no auto."}
          </p>
        </div>

        {error && <Banner tone="danger">{error}</Banner>}

        {rollup && (
          <>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <Stat
                label="Route coverage"
                value={`${rollup.routeCoverage.percent}%`}
                detail={`${rollup.routeCoverage.served} of ${rollup.routeCoverage.scheduled} routes served`}
                tone={rollup.routeCoverage.percent >= 90 ? "success" : "warning"}
              />
              <Stat
                label="Trips today"
                value={String(rollup.trips.total)}
                detail={`${rollup.trips.active} active · ${rollup.trips.completed} completed`}
              />
              <Stat
                label="Open complaints"
                value={String(rollup.complaints.open)}
                detail={`${rollup.complaints.last30Days} raised in 30 days`}
              />
              <Stat
                label="Past SLA"
                value={String(rollup.complaints.slaBreached)}
                detail="Open and overdue"
                tone={rollup.complaints.slaBreached > 0 ? "danger" : "success"}
              />
            </div>

            {rollup.openDriverIssues > 0 && (
              <Banner tone="warning">
                {rollup.openDriverIssues} driver{rollup.openDriverIssues === 1 ? "" : "s"} reported a
                problem that nobody has acknowledged yet.
              </Banner>
            )}
          </>
        )}

        <section>
          <h2 className="text-[length:var(--text-title)]">
            Missed pickups{missed.length > 0 && ` (${missed.length})`}
          </h2>
          <p className="mt-1 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
            The window has closed and no auto came within 75 m. These are the houses that will
            complain tomorrow.
          </p>

          <ul className="mt-3 space-y-2">
            {missed.map((m) => (
              <li
                key={m.householdId}
                className="flex flex-wrap items-center gap-x-3 gap-y-1 card px-4 py-3"
              >
                <span className="text-[length:var(--text-body)] font-medium">{m.fullName}</span>
                <span className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                  {m.addressLine}
                </span>
                <span className="ml-auto text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                  {m.routeName} · window closed {m.windowEnd.slice(0, 5)}
                </span>
              </li>
            ))}
            {missed.length === 0 && (
              <li className="card px-4 py-10 text-center text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
                Every house whose window has closed was reached.
              </li>
            )}
          </ul>
        </section>
      </main>
    </PortalShell>
  );
}

function Stat({
  label,
  value,
  detail,
  tone,
}: {
  label: string;
  value: string;
  detail: string;
  tone?: "success" | "warning" | "danger";
}) {
  const tones = {
    success: "text-[var(--color-success)]",
    warning: "text-[var(--color-warning)]",
    danger: "text-[var(--color-danger)]",
  };
  return (
    <div className="card p-5">
      <p className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">{label}</p>
      <p className={`mt-1 text-[2.125rem] font-extrabold tracking-tight ${tone ? tones[tone] : ""}`}>{value}</p>
      <p className="mt-1 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
        {detail}
      </p>
    </div>
  );
}
