"use client";

import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { useCallback, useEffect, useRef, useState } from "react";
import { PortalShell } from "@/components/PortalShell";
import { Banner } from "@/app/wards/page";
import type { DriverIssueRecord } from "@namma-kasa/shared";
import { api, readSession } from "@/lib/session";

interface Position {
  tripId: string;
  autoId: string;
  registrationNumber: string;
  routeName: string;
  passNumber: number;
  lat: number;
  lng: number;
  trackingDropped: boolean;
  at: string;
}

interface Alert {
  tripId: string;
  registrationNumber: string;
  routeName: string;
  silentForMin: number;
}

const POLL_MS = 5_000;

/** Dates cross the wire as ISO strings; Zod infers them as Date. */
type WireIssue = Omit<DriverIssueRecord, "acknowledgedAt" | "createdAt"> & {
  acknowledgedAt: string | null;
  createdAt: string;
};

const ISSUE_LABEL: Record<DriverIssueRecord["kind"], string> = {
  breakdown: "Auto broke down",
  road_blocked: "Road blocked",
  other: "Problem reported",
};

export default function LivePage() {
  const [positions, setPositions] = useState<Position[]>([]);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [issues, setIssues] = useState<WireIssue[]>([]);
  const [error, setError] = useState<string | null>(null);

  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markersRef = useRef<Map<string, maplibregl.Marker>>(new Map());

  useEffect(() => {
    if (!containerRef.current || mapRef.current) return;
    mapRef.current = new maplibregl.Map({
      container: containerRef.current,
      style: "https://tiles.openfreemap.org/styles/positron",
      center: [77.5946, 12.9716],
      zoom: 12,
    });
    return () => {
      mapRef.current?.remove();
      mapRef.current = null;
    };
  }, []);

  const poll = useCallback(async () => {
    const wardId = readSession()?.wardId;
    if (!wardId) throw new Error("This view is scoped to a ward");
    const [data, reported] = await Promise.all([
      api<{ positions: Position[]; alerts: Alert[] }>(`/admin/live/wards/${wardId}`),
      api<WireIssue[]>(`/admin/driver-issues/wards/${wardId}`),
    ]);
    setPositions(data.positions);
    setAlerts(data.alerts);
    setIssues(reported.filter((issue) => !issue.acknowledgedAt));
  }, []);

  const acknowledge = useCallback(
    async (id: string) => {
      // Optimistic: the row leaves the list immediately, and the next poll is
      // the source of truth if the call failed.
      setIssues((current) => current.filter((issue) => issue.id !== id));
      try {
        await api(`/admin/driver-issues/${id}/acknowledge`, { method: "PATCH" });
      } catch (e) {
        setError(e instanceof Error ? e.message : "Could not acknowledge");
        await poll();
      }
    },
    [poll],
  );

  useEffect(() => {
    let cancelled = false;
    const tick = async () => {
      try {
        await poll();
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load");
      }
    };
    void tick();
    const timer = setInterval(() => void tick(), POLL_MS);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, [poll]);

  // Markers are moved rather than recreated, so the auto slides across the map
  // instead of blinking on each poll.
  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    const seen = new Set<string>();
    for (const position of positions) {
      seen.add(position.autoId);
      const existing = markersRef.current.get(position.autoId);
      if (existing) {
        existing.setLngLat([position.lng, position.lat]);
        existing.getElement().style.background = position.trackingDropped
          ? "var(--color-danger)"
          : "var(--color-success)";
        continue;
      }

      const el = document.createElement("div");
      el.style.cssText =
        "width:14px;height:14px;border-radius:50%;border:2px solid #fff;box-shadow:0 1px 3px rgba(0,0,0,.4);background:var(--color-success)";
      const marker = new maplibregl.Marker({ element: el })
        .setLngLat([position.lng, position.lat])
        .setPopup(
          new maplibregl.Popup({ offset: 12 }).setText(
            `${position.registrationNumber} · ${position.routeName} · pass ${position.passNumber}`,
          ),
        )
        .addTo(map);
      markersRef.current.set(position.autoId, marker);
    }

    for (const [autoId, marker] of markersRef.current) {
      if (!seen.has(autoId)) {
        marker.remove();
        markersRef.current.delete(autoId);
      }
    }
  }, [positions]);

  return (
    <PortalShell>
      <main className="grid gap-6 p-6 lg:grid-cols-[340px_1fr]">
        <section className="space-y-4">
          <div>
            <h1 className="text-[length:var(--text-headline)]">Live</h1>
            <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
              Autos currently on a collection run, refreshed every {POLL_MS / 1000} seconds.
            </p>
          </div>

          {error && <Banner tone="danger">{error}</Banner>}

          {alerts.length > 0 && (
            <div className="rounded-[var(--radius-card)] bg-[var(--color-danger-container)] p-4">
              <h2 className="text-[length:var(--text-body)] font-medium text-[var(--color-danger)]">
                Tracking dropped
              </h2>
              <ul className="mt-1 space-y-1">
                {alerts.map((alert) => (
                  <li key={alert.tripId} className="text-[length:var(--text-label)] text-[var(--color-danger)]">
                    {alert.registrationNumber} on {alert.routeName} — silent for{" "}
                    {alert.silentForMin} min
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* A driver saying "I broke down" is more actionable than silence,
              so it sits above the tracking-health list (FR-DRV-07). */}
          {issues.length > 0 && (
            <div className="rounded-[var(--radius-card)] bg-[var(--color-warning-container)] p-4">
              <h2 className="text-[length:var(--text-body)] font-medium text-[#7a5300]">
                Reported by drivers
              </h2>
              <ul className="mt-2 space-y-2">
                {issues.map((issue) => (
                  <li key={issue.id} className="flex flex-wrap items-center gap-2">
                    <span className="text-[length:var(--text-label)] text-[#7a5300]">
                      {ISSUE_LABEL[issue.kind]}
                      {issue.driverName ? ` — ${issue.driverName}` : ""}
                      {issue.note ? `: ${issue.note}` : ""}
                    </span>
                    <button
                      type="button"
                      onClick={() => void acknowledge(issue.id)}
                      className="ml-auto rounded-full border border-[#7a5300] px-3 py-1 text-[length:var(--text-label)] text-[#7a5300]"
                    >
                      Acknowledge
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          )}

          <ul className="rounded-[var(--radius-card)] border border-[var(--color-outline)]">
            {positions.map((position) => (
              <li
                key={position.autoId}
                className="border-b border-[var(--color-outline)] p-4 last:border-0"
              >
                <div className="flex items-center gap-2">
                  <span
                    className="inline-block h-2.5 w-2.5 rounded-full"
                    style={{
                      background: position.trackingDropped
                        ? "var(--color-danger)"
                        : "var(--color-success)",
                    }}
                  />
                  <span className="text-[length:var(--text-body)] font-medium">
                    {position.registrationNumber}
                  </span>
                </div>
                <p className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                  {position.routeName} · pass {position.passNumber} · last seen{" "}
                  {new Date(position.at).toLocaleTimeString()}
                </p>
              </li>
            ))}
            {positions.length === 0 && (
              <li className="px-4 py-10 text-center text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
                No collection runs in progress.
              </li>
            )}
          </ul>
        </section>

        <section className="overflow-hidden rounded-[var(--radius-card)] border border-[var(--color-outline)]">
          <div ref={containerRef} className="h-[calc(100dvh-8rem)] w-full" />
        </section>
      </main>
    </PortalShell>
  );
}
