"use client";

import { useCallback, useEffect, useState } from "react";
import { AreaMap, type Area } from "@/components/AreaMap";
import { PortalShell } from "@/components/PortalShell";
import type { ImportReport, Operator, Ward, WardEditImpact } from "@namma-kasa/shared";
import { api } from "@/lib/session";

/** A 409 from the API carries the intersection so the clash can be drawn. */
interface Conflict {
  message: string;
  geometry: Area | null;
}

/** What reshaping a boundary would strand, shown before the save (CHK017). */
type EditImpact = WardEditImpact;

export default function WardsPage() {
  const [wards, setWards] = useState<Ward[]>([]);
  const [operators, setOperators] = useState<Operator[]>([]);
  const [selected, setSelected] = useState<Ward | null>(null);
  const [drawn, setDrawn] = useState<Area | null>(null);
  const [conflict, setConflict] = useState<Conflict | null>(null);
  const [report, setReport] = useState<ImportReport | null>(null);
  const [name, setName] = useState("");
  const [wardCode, setWardCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [impact, setImpact] = useState<EditImpact | null>(null);

  const load = useCallback(async () => {
    const [w, o] = await Promise.all([
      api<Ward[]>("/admin/wards"),
      api<Operator[]>("/admin/operators").catch(() => [] as Operator[]),
    ]);
    setWards(w);
    setOperators(o);
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

  async function createWard(event: React.FormEvent) {
    event.preventDefault();
    if (!drawn) {
      setError("Draw the boundary on the map first");
      return;
    }
    setBusy(true);
    setError(null);
    setConflict(null);
    try {
      await api<Ward>("/admin/wards", {
        method: "POST",
        body: JSON.stringify({
          operatorId: operators[0]?.id,
          name,
          wardCode,
          boundary: drawn,
        }),
      });
      setName("");
      setWardCode("");
      setDrawn(null);
      await load();
    } catch (err) {
      // Boundary clashes come back as a problem+json with the overlap geometry.
      const problem = err as Error & { conflict?: Area };
      setConflict({ message: problem.message, geometry: problem.conflict ?? null });
    } finally {
      setBusy(false);
    }
  }

  /**
   * Reshaping a ward can leave households outside the routes that serve them,
   * which silently stops their alerts. The admin sees the count first.
   */
  async function checkImpact() {
    if (!selected || !drawn) return;
    setError(null);
    try {
      setImpact(
        await api<EditImpact>(`/admin/wards/${selected.id}/edit-impact`, {
          method: "POST",
          body: JSON.stringify(drawn),
        }),
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not check impact");
    }
  }

  async function saveBoundary() {
    if (!selected || !drawn) return;
    setBusy(true);
    setError(null);
    try {
      await api(`/admin/wards/${selected.id}`, {
        method: "PATCH",
        body: JSON.stringify({ boundary: drawn }),
      });
      setImpact(null);
      setDrawn(null);
      setSelected(null);
      await load();
    } catch (err) {
      const problem = err as Error & { conflict?: Area };
      setConflict({ message: problem.message, geometry: problem.conflict ?? null });
    } finally {
      setBusy(false);
    }
  }

  async function importFile(file: File) {
    setBusy(true);
    setError(null);
    setReport(null);
    try {
      const featureCollection = JSON.parse(await file.text()) as unknown;
      const result = await api<ImportReport>("/admin/wards/import", {
        method: "POST",
        body: JSON.stringify({
          operatorId: operators[0]?.id,
          cityId: "blr",
          featureCollection,
        }),
      });
      setReport(result);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Import failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <PortalShell>
      <main className="grid gap-6 p-6 lg:grid-cols-[380px_1fr]">
        <section className="space-y-6">
          <div>
            <h1 className="text-[length:var(--text-headline)]">Wards</h1>
            <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
              Import official boundaries, or draw one on the map.
            </p>
          </div>

          {error && <Banner tone="danger">{error}</Banner>}

          <div className="rounded-[var(--radius-card)] border border-[var(--color-outline)] p-4">
            <h2 className="text-[length:var(--text-title)] font-medium">Bulk import</h2>
            <p className="mt-1 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
              GeoJSON FeatureCollection. Each feature needs a ward_code and name.
            </p>
            <input
              type="file"
              accept=".geojson,.json"
              disabled={busy}
              onChange={(e) => {
                const file = e.target.files?.[0];
                if (file) void importFile(file);
              }}
              className="mt-3 w-full text-[length:var(--text-body)] file:mr-3 file:rounded-full file:border-0 file:bg-[var(--color-primary-container)] file:px-4 file:py-2 file:text-[var(--color-primary-pressed)]"
            />
            {report && (
              <div className="mt-3 space-y-2 text-[length:var(--text-body)]">
                <p className="text-[var(--color-success)]">
                  Imported {report.accepted.length} ward(s)
                </p>
                {report.rejected.length > 0 && (
                  <ul className="space-y-1 rounded-[var(--radius-input)] bg-[var(--color-danger-container)] p-3">
                    {report.rejected.map((r) => (
                      <li key={r.wardCode} className="text-[var(--color-danger)]">
                        <strong>{r.wardCode}</strong>: {r.reason}
                      </li>
                    ))}
                  </ul>
                )}
              </div>
            )}
          </div>

          <form
            onSubmit={createWard}
            className="rounded-[var(--radius-card)] border border-[var(--color-outline)] p-4"
          >
            <h2 className="text-[length:var(--text-title)] font-medium">Draw a ward</h2>
            <Field label="Name" value={name} onChange={setName} required />
            <Field label="Ward code" value={wardCode} onChange={setWardCode} required />
            <p className="mt-3 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
              {drawn ? "Boundary captured." : "Click on the map to trace the boundary."}
            </p>
            {conflict && (
              <Banner tone="danger">
                {conflict.message}
                {conflict.geometry && " The overlap is shaded on the map."}
              </Banner>
            )}
            <button
              type="submit"
              disabled={busy}
              className="mt-4 w-full rounded-full bg-[var(--color-primary)] px-4 py-2.5 text-[length:var(--text-body)] font-medium text-white hover:bg-[var(--color-primary-pressed)] disabled:opacity-60"
            >
              Create ward
            </button>
          </form>

          {selected && drawn && (
            <div className="rounded-[var(--radius-card)] border border-[var(--color-outline)] p-4">
              <h2 className="text-[length:var(--text-title)] font-medium">
                Reshape {selected.wardCode}
              </h2>
              <p className="mt-1 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                Check what the new boundary would strand before saving it.
              </p>
              {impact && (
                <div
                  className={`mt-3 rounded-[var(--radius-input)] px-3 py-2 text-[length:var(--text-body)] ${
                    impact.affectedHouseholds + impact.routesOutsideNewBoundary > 0
                      ? "bg-[var(--color-warning-container)] text-[#7a5300]"
                      : "bg-[var(--color-success-container)] text-[var(--color-success)]"
                  }`}
                >
                  {impact.affectedHouseholds} household(s) would fall outside this ward and{" "}
                  {impact.routesOutsideNewBoundary} route(s) would no longer fit inside it.
                  {impact.affectedHouseholds > 0 &&
                    " Affected households return to the review queue."}
                </div>
              )}
              <div className="mt-3 flex gap-2">
                <button
                  type="button"
                  onClick={() => void checkImpact()}
                  className="rounded-full border border-[var(--color-outline)] px-4 py-2 text-[length:var(--text-body)] hover:bg-[var(--color-surface-alt)]"
                >
                  Check impact
                </button>
                <button
                  type="button"
                  disabled={busy || !impact}
                  onClick={() => void saveBoundary()}
                  className="rounded-full bg-[var(--color-primary)] px-4 py-2 text-[length:var(--text-body)] font-medium text-white hover:bg-[var(--color-primary-pressed)] disabled:opacity-60"
                  title={impact ? undefined : "Check the impact first"}
                >
                  Save new boundary
                </button>
              </div>
            </div>
          )}

          <div className="rounded-[var(--radius-card)] border border-[var(--color-outline)]">
            <h2 className="border-b border-[var(--color-outline)] px-4 py-3 text-[length:var(--text-title)] font-medium">
              {wards.length} ward{wards.length === 1 ? "" : "s"}
            </h2>
            <ul className="max-h-72 overflow-auto">
              {wards.map((ward) => (
                <li key={ward.id}>
                  <button
                    type="button"
                    onClick={() => setSelected(ward)}
                    className={`w-full px-4 py-2.5 text-left text-[length:var(--text-body)] hover:bg-[var(--color-surface-alt)] ${
                      selected?.id === ward.id ? "bg-[var(--color-primary-container)]" : ""
                    }`}
                  >
                    <span className="font-medium">{ward.wardCode}</span> · {ward.name}
                  </button>
                </li>
              ))}
              {wards.length === 0 && (
                <li className="px-4 py-6 text-center text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
                  No wards yet. Import a boundary file to begin.
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
            conflict={conflict?.geometry ?? null}
            context={(selected ? [selected] : wards).map((w) => ({
              area: w.boundary,
              color: "#1A73E8",
              label: w.wardCode,
            }))}
            className="h-[calc(100dvh-8rem)] w-full"
          />
        </section>
      </main>
    </PortalShell>
  );
}

export function Field({
  label,
  value,
  onChange,
  required,
  type = "text",
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  required?: boolean;
  type?: string;
}) {
  return (
    <label className="mt-3 block text-[length:var(--text-label)] font-medium">
      {label}
      <input
        type={type}
        value={value}
        required={required}
        onChange={(e) => onChange(e.target.value)}
        className="mt-1 w-full rounded-[var(--radius-input)] border border-[var(--color-outline)] px-3 py-2 text-[length:var(--text-body)] font-normal outline-none focus:border-[var(--color-primary)]"
      />
    </label>
  );
}

export function Banner({
  tone,
  children,
}: {
  tone: "danger" | "success" | "warning";
  children: React.ReactNode;
}) {
  const tones = {
    danger: "bg-[var(--color-danger-container)] text-[var(--color-danger)]",
    success: "bg-[var(--color-success-container)] text-[var(--color-success)]",
    warning: "bg-[var(--color-warning-container)] text-[#7a5300]",
  };
  return (
    <p role="alert" className={`mt-3 rounded-[var(--radius-input)] px-3 py-2 text-[length:var(--text-body)] ${tones[tone]}`}>
      {children}
    </p>
  );
}
