"use client";

import { useCallback, useEffect, useState } from "react";
import { PortalShell } from "@/components/PortalShell";
import { Banner } from "@/app/wards/page";
import { api, readSession } from "@/lib/session";

interface QueueItem {
  id: string;
  fullName: string;
  addressLine: string;
  landmark: string | null;
  pin: { lat: number; lng: number };
  createdAt: string;
  aging: boolean;
}

interface Route {
  id: string;
  name: string;
  routeCode: string;
}

/**
 * Households whose pin fell outside every route. Left alone they never receive
 * a collection alert, so items older than 48 h are flagged (CHK020).
 */
export default function ReviewQueuePage() {
  const [items, setItems] = useState<QueueItem[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const load = useCallback(async () => {
    const wardId = readSession()?.wardId;
    const [queue, routeList] = await Promise.all([
      api<QueueItem[]>("/admin/households/review-queue"),
      wardId ? api<Route[]>(`/admin/routes?wardId=${wardId}`) : Promise.resolve([]),
    ]);
    setItems(queue);
    setRoutes(routeList);
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      try {
        await load();
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : "Failed to load");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [load]);

  async function assign(householdId: string, routeId: string) {
    setError(null);
    try {
      await api(`/admin/households/${householdId}/route`, {
        method: "PATCH",
        body: JSON.stringify({ routeId }),
      });
      setNotice("Household assigned. The resident will start receiving alerts.");
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Assignment failed");
    }
  }

  return (
    <PortalShell>
      <main className="mx-auto max-w-4xl space-y-6 p-6">
        <div>
          <h1 className="text-[length:var(--text-headline)]">Review queue</h1>
          <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
            Households the system could not place on a route automatically.
          </p>
        </div>

        {error && <Banner tone="danger">{error}</Banner>}
        {notice && <Banner tone="success">{notice}</Banner>}

        <ul className="rounded-[var(--radius-card)] border border-[var(--color-outline)]">
          {items.map((item) => (
            <li key={item.id} className="border-b border-[var(--color-outline)] p-4 last:border-0">
              <div className="flex items-center gap-2">
                <span className="text-[length:var(--text-body)] font-medium">{item.fullName}</span>
                {item.aging && (
                  <span className="rounded-full bg-[var(--color-warning-container)] px-2 py-0.5 text-[length:var(--text-label)] text-[#7a5300]">
                    waiting over 48h
                  </span>
                )}
              </div>
              <p className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                {item.addressLine}
                {item.landmark ? ` · ${item.landmark}` : ""} · {item.pin.lat.toFixed(5)},{" "}
                {item.pin.lng.toFixed(5)}
              </p>
              <select
                defaultValue=""
                onChange={(e) => {
                  if (e.target.value) void assign(item.id, e.target.value);
                }}
                className="mt-2 rounded-[var(--radius-input)] border border-[var(--color-outline)] px-2 py-1 text-[length:var(--text-label)]"
              >
                <option value="">Assign to route…</option>
                {routes.map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.routeCode} · {r.name}
                  </option>
                ))}
              </select>
            </li>
          ))}
          {items.length === 0 && (
            <li className="px-4 py-10 text-center text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
              Nothing waiting. Every household is mapped to a route.
            </li>
          )}
        </ul>
      </main>
    </PortalShell>
  );
}
