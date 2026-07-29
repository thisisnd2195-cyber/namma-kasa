"use client";

import { useCallback, useEffect, useState } from "react";
import { PortalShell } from "@/components/PortalShell";
import { Banner, Field } from "@/app/wards/page";
import type { Auto, Driver, Route } from "@namma-kasa/shared";
import { api, readSession } from "@/lib/session";

interface AssignmentRow {
  id: string;
  effective_from: string;
  effective_to: string | null;
  routeName?: string;
  driverName?: string;
}

interface AssignmentHistory {
  autoId: string;
  routes: AssignmentRow[];
  drivers: AssignmentRow[];
}

const STATUS_TONE: Record<Auto["status"], string> = {
  available: "bg-[var(--color-success-container)] text-[var(--color-success)]",
  assigned: "bg-[var(--color-primary-container)] text-[var(--color-primary-pressed)]",
  maintenance: "bg-[var(--color-warning-container)] text-[#7a5300]",
  retired: "bg-[var(--color-surface-alt)] text-[var(--color-text-secondary)]",
};

export default function FleetPage() {
  const [wardId, setWardId] = useState<string>("");
  const [autos, setAutos] = useState<Auto[]>([]);
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [routes, setRoutes] = useState<Route[]>([]);
  const [history, setHistory] = useState<AssignmentHistory | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const [reg, setReg] = useState("");
  const [capacity, setCapacity] = useState("");
  const [driverName, setDriverName] = useState("");
  const [driverPhone, setDriverPhone] = useState("");
  const [license, setLicense] = useState("");

  useEffect(() => {
    void (async () => {
      const session = readSession();
      if (session?.wardId) {
        setWardId(session.wardId);
        return;
      }
      const wards = await api<{ id: string }[]>("/admin/wards");
      setWardId(wards[0]?.id ?? "");
    })().catch((e) => setError(e instanceof Error ? e.message : "Failed to load"));
  }, []);

  const load = useCallback(async () => {
    if (!wardId) return;
    const [a, d, r] = await Promise.all([
      api<Auto[]>(`/admin/autos?wardId=${wardId}`),
      api<Driver[]>(`/admin/drivers?wardId=${wardId}`),
      api<Route[]>(`/admin/routes?wardId=${wardId}`),
    ]);
    setAutos(a);
    setDrivers(d);
    setRoutes(r);
  }, [wardId]);

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

  async function act<T>(fn: () => Promise<T>, message: string) {
    setError(null);
    setNotice(null);
    try {
      await fn();
      setNotice(message);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Action failed");
    }
  }

  return (
    <PortalShell>
      <main className="mx-auto max-w-6xl space-y-6 p-6">
        <div>
          <h1 className="text-[length:var(--text-headline)]">Fleet</h1>
          <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
            Onboard autos and drivers, then assign them. Only available autos can take a route.
          </p>
        </div>

        {error && <Banner tone="danger">{error}</Banner>}
        {notice && <Banner tone="success">{notice}</Banner>}

        <div className="grid gap-6 lg:grid-cols-2">
          {/* ---------------------------------------------------------- autos */}
          <section className="rounded-[var(--radius-card)] border border-[var(--color-outline)]">
            <h2 className="border-b border-[var(--color-outline)] px-4 py-3 text-[length:var(--text-title)] font-medium">
              Autos
            </h2>

            <form
              className="border-b border-[var(--color-outline)] p-4"
              onSubmit={(e) => {
                e.preventDefault();
                void act(
                  () =>
                    api("/admin/autos", {
                      method: "POST",
                      body: JSON.stringify({
                        wardId,
                        registrationNumber: reg.toUpperCase(),
                        ...(capacity ? { capacityKg: Number(capacity) } : {}),
                      }),
                    }),
                  `Onboarded ${reg.toUpperCase()}`,
                ).then(() => {
                  setReg("");
                  setCapacity("");
                });
              }}
            >
              <div className="grid grid-cols-2 gap-2">
                <Field label="Registration" value={reg} onChange={setReg} required />
                <Field label="Capacity (kg)" value={capacity} onChange={setCapacity} type="number" />
              </div>
              <button
                type="submit"
                className="mt-3 rounded-full border border-[var(--color-outline)] px-4 py-2 text-[length:var(--text-body)] hover:bg-[var(--color-surface-alt)]"
              >
                Onboard auto
              </button>
            </form>

            <ul>
              {autos.map((auto) => (
                <li key={auto.id} className="border-b border-[var(--color-outline)] p-4 last:border-0">
                  <div className="flex items-center gap-2">
                    <span className="text-[length:var(--text-body)] font-medium">
                      {auto.registrationNumber}
                    </span>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[length:var(--text-label)] ${STATUS_TONE[auto.status]}`}
                    >
                      {auto.status}
                    </span>
                    <button
                      type="button"
                      onClick={() =>
                        void api<Omit<AssignmentHistory, "autoId">>(
                          `/admin/autos/${auto.id}/assignments`,
                        ).then((h) => setHistory({ autoId: auto.id, ...h }))
                      }
                      className="ml-auto text-[length:var(--text-label)] text-[var(--color-primary)] hover:underline"
                    >
                      History
                    </button>
                  </div>

                  <div className="mt-2 flex flex-wrap gap-2">
                    <select
                      defaultValue=""
                      onChange={(e) => {
                        const routeId = e.target.value;
                        if (!routeId) return;
                        void act(
                          () =>
                            api(`/admin/autos/${auto.id}/assign-route`, {
                              method: "POST",
                              body: JSON.stringify({ routeId }),
                            }),
                          `${auto.registrationNumber} assigned`,
                        );
                        e.target.value = "";
                      }}
                      className="rounded-[var(--radius-input)] border border-[var(--color-outline)] px-2 py-1 text-[length:var(--text-label)]"
                    >
                      <option value="">Assign to route…</option>
                      {routes.map((r) => (
                        <option key={r.id} value={r.id}>
                          {r.routeCode} · {r.name}
                        </option>
                      ))}
                    </select>

                    {auto.status !== "retired" && (
                      <button
                        type="button"
                        onClick={() =>
                          void act(
                            () =>
                              api(`/admin/autos/${auto.id}`, {
                                method: "PATCH",
                                body: JSON.stringify({
                                  status: auto.status === "maintenance" ? "available" : "maintenance",
                                }),
                              }),
                            "Status updated",
                          )
                        }
                        className="rounded-full border border-[var(--color-outline)] px-3 py-1 text-[length:var(--text-label)] hover:bg-[var(--color-surface-alt)]"
                      >
                        {auto.status === "maintenance" ? "Back in service" : "Maintenance"}
                      </button>
                    )}
                  </div>

                  {history?.autoId === auto.id && (
                    <div className="mt-3 rounded-[var(--radius-input)] bg-[var(--color-surface-alt)] p-3 text-[length:var(--text-label)]">
                      <p className="font-medium">Assignment history</p>
                      {history.routes.map((row) => (
                        <p key={row.id} className="text-[var(--color-text-secondary)]">
                          {row.routeName} — {new Date(row.effective_from).toLocaleDateString()} →{" "}
                          {row.effective_to
                            ? new Date(row.effective_to).toLocaleDateString()
                            : "current"}
                        </p>
                      ))}
                      {history.routes.length === 0 && (
                        <p className="text-[var(--color-text-secondary)]">Never assigned.</p>
                      )}
                    </div>
                  )}
                </li>
              ))}
              {autos.length === 0 && <Empty>No autos onboarded in this ward.</Empty>}
            </ul>
          </section>

          {/* -------------------------------------------------------- drivers */}
          <section className="rounded-[var(--radius-card)] border border-[var(--color-outline)]">
            <h2 className="border-b border-[var(--color-outline)] px-4 py-3 text-[length:var(--text-title)] font-medium">
              Drivers
            </h2>

            <form
              className="border-b border-[var(--color-outline)] p-4"
              onSubmit={(e) => {
                e.preventDefault();
                void act(
                  () =>
                    api("/admin/drivers", {
                      method: "POST",
                      body: JSON.stringify({
                        wardId,
                        fullName: driverName,
                        phone: driverPhone,
                        licenseNumber: license,
                      }),
                    }),
                  `${driverName} can now register in the app`,
                ).then(() => {
                  setDriverName("");
                  setDriverPhone("");
                  setLicense("");
                });
              }}
            >
              <Field label="Full name" value={driverName} onChange={setDriverName} required />
              <div className="grid grid-cols-2 gap-2">
                <Field label="Phone" value={driverPhone} onChange={setDriverPhone} required />
                <Field label="Licence" value={license} onChange={setLicense} required />
              </div>
              <p className="mt-2 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                Only this number will be able to register as this driver.
              </p>
              <button
                type="submit"
                className="mt-3 rounded-full border border-[var(--color-outline)] px-4 py-2 text-[length:var(--text-body)] hover:bg-[var(--color-surface-alt)]"
              >
                Provision driver
              </button>
            </form>

            <ul>
              {drivers.map((driver) => (
                <li key={driver.id} className="border-b border-[var(--color-outline)] p-4 last:border-0">
                  <div className="flex items-center gap-2">
                    <span className="text-[length:var(--text-body)] font-medium">
                      {driver.fullName}
                    </span>
                    <span
                      className={`rounded-full px-2 py-0.5 text-[length:var(--text-label)] ${
                        driver.hasAccount
                          ? "bg-[var(--color-success-container)] text-[var(--color-success)]"
                          : "bg-[var(--color-warning-container)] text-[#7a5300]"
                      }`}
                    >
                      {driver.hasAccount ? "app account" : "not registered"}
                    </span>
                  </div>
                  <p className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                    {driver.phone} · {driver.licenseNumber}
                  </p>
                  <select
                    defaultValue=""
                    onChange={(e) => {
                      const autoId = e.target.value;
                      if (!autoId) return;
                      void act(
                        () =>
                          api(`/admin/drivers/${driver.id}/assign-auto`, {
                            method: "POST",
                            body: JSON.stringify({ autoId }),
                          }),
                        `${driver.fullName} assigned`,
                      );
                      e.target.value = "";
                    }}
                    className="mt-2 rounded-[var(--radius-input)] border border-[var(--color-outline)] px-2 py-1 text-[length:var(--text-label)]"
                  >
                    <option value="">Assign to auto…</option>
                    {autos
                      .filter((a) => a.status !== "retired")
                      .map((a) => (
                        <option key={a.id} value={a.id}>
                          {a.registrationNumber}
                        </option>
                      ))}
                  </select>
                </li>
              ))}
              {drivers.length === 0 && <Empty>No drivers provisioned in this ward.</Empty>}
            </ul>
          </section>
        </div>
      </main>
    </PortalShell>
  );
}

function Empty({ children }: { children: React.ReactNode }) {
  return (
    <li className="px-4 py-6 text-center text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
      {children}
    </li>
  );
}
