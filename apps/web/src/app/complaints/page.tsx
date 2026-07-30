"use client";

import { useCallback, useEffect, useState } from "react";
import { PortalShell } from "@/components/PortalShell";
import { Banner } from "@/app/wards/page";
import type { AdminComplaint, ComplaintStatus } from "@namma-kasa/shared";
import { api } from "@/lib/session";

/** Dates cross the wire as ISO strings; Zod infers them as Date. */
type WireComplaint = Omit<AdminComplaint, "createdAt" | "slaDueAt" | "evidence"> & {
  createdAt: string;
  slaDueAt: string | null;
  evidence: { servedOnComplaintDay: boolean; lastCollectedAt: string | null };
};

type Status = ComplaintStatus;

const NEXT_STATUS: Record<Status, Status[]> = {
  open: ["in_review", "resolved", "rejected"],
  in_review: ["resolved", "rejected"],
  resolved: [],
  rejected: [],
};

const STATUS_TONE: Record<Status, string> = {
  open: "bg-[var(--color-danger-container)] text-[var(--color-danger)]",
  in_review: "bg-[var(--color-warning-container)] text-[#7a5300]",
  resolved: "bg-[var(--color-success-container)] text-[var(--color-success)]",
  rejected: "bg-[var(--color-surface-alt)] text-[var(--color-text-secondary)]",
};

export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState<WireComplaint[]>([]);
  const [filter, setFilter] = useState<Status | "all">("open");
  const [error, setError] = useState<string | null>(null);
  const [note, setNote] = useState<Record<string, string>>({});

  const load = useCallback(async () => {
    const query = filter === "all" ? "" : `?status=${filter}`;
    setComplaints(await api<WireComplaint[]>(`/admin/complaints${query}`));
  }, [filter]);

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

  async function move(id: string, status: Status) {
    setError(null);
    try {
      await api(`/admin/complaints/${id}`, {
        method: "PATCH",
        body: JSON.stringify({ status, resolutionNote: note[id] || undefined }),
      });
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not update");
    }
  }

  return (
    <PortalShell>
      <main className="mx-auto max-w-4xl space-y-4 p-6">
        <div>
          <h1 className="text-[length:var(--text-headline)]">Complaints</h1>
          <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
            Each complaint shows whether the auto actually reached that house, so a
            &ldquo;we did come&rdquo; dispute is settled by the GPS record.
          </p>
        </div>

        <div className="flex gap-1">
          {(["open", "in_review", "resolved", "rejected", "all"] as const).map((value) => (
            <button
              key={value}
              type="button"
              onClick={() => setFilter(value)}
              className={`rounded-full px-3 py-1.5 text-[length:var(--text-label)] ${
                filter === value
                  ? "bg-[var(--color-primary)] text-white"
                  : "border border-[var(--color-outline)] text-[var(--color-text-secondary)]"
              }`}
            >
              {value.replace("_", " ")}
            </button>
          ))}
        </div>

        {error && <Banner tone="danger">{error}</Banner>}

        <ul className="space-y-3">
          {complaints.map((complaint) => (
            <li
              key={complaint.id}
              className="card p-4"
            >
              <div className="flex flex-wrap items-center gap-2">
                <span className="text-[length:var(--text-body)] font-medium">
                  {complaint.category.replace("_", " ")}
                </span>
                <span
                  className={`rounded-full px-2 py-0.5 text-[length:var(--text-label)] ${STATUS_TONE[complaint.status]}`}
                >
                  {complaint.status.replace("_", " ")}
                </span>
                {/* The SLA state is why an admin picks this row over that one. */}
                {complaint.slaEscalated ? (
                  <span className="rounded-full bg-[var(--color-danger-container)] px-2 py-0.5 text-[length:var(--text-label)] font-medium text-[var(--color-danger)]">
                    Escalated
                  </span>
                ) : complaint.slaBreached ? (
                  <span className="rounded-full bg-[var(--color-danger-container)] px-2 py-0.5 text-[length:var(--text-label)] text-[var(--color-danger)]">
                    Past SLA
                  </span>
                ) : (
                  complaint.slaDueAt &&
                  complaint.status !== "resolved" &&
                  complaint.status !== "rejected" && (
                    <span className="text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                      Due {new Date(complaint.slaDueAt).toLocaleString()}
                    </span>
                  )
                )}
                <span className="ml-auto text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                  {new Date(complaint.createdAt).toLocaleString()}
                </span>
              </div>

              <p className="mt-1 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                {complaint.household.fullName} · {complaint.household.addressLine}
              </p>

              {complaint.description && (
                <p className="mt-2 text-[length:var(--text-body)]">{complaint.description}</p>
              )}

              {complaint.mediaUrls.length > 0 && (
                <div className="mt-2 flex gap-2">
                  {complaint.mediaUrls.map((url) => (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img
                      key={url}
                      src={url}
                      alt="Complaint evidence"
                      className="h-20 w-20 rounded-[var(--radius-input)] object-cover"
                    />
                  ))}
                </div>
              )}

              {/* The evidence panel is the point: it answers the complaint. */}
              <div
                className={`mt-3 rounded-[var(--radius-input)] px-3 py-2 text-[length:var(--text-label)] ${
                  complaint.evidence.servedOnComplaintDay
                    ? "bg-[var(--color-success-container)] text-[var(--color-success)]"
                    : "bg-[var(--color-danger-container)] text-[var(--color-danger)]"
                }`}
              >
                {complaint.evidence.servedOnComplaintDay
                  ? "GPS record: an auto reached this house on the day of the complaint."
                  : "GPS record: no auto reached this house on the day of the complaint."}
                {complaint.evidence.lastCollectedAt && (
                  <> Last collected {new Date(complaint.evidence.lastCollectedAt).toLocaleString()}.</>
                )}
              </div>

              {complaint.resolutionNote && (
                <p className="mt-2 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
                  Note: {complaint.resolutionNote}
                </p>
              )}

              {NEXT_STATUS[complaint.status].length > 0 && (
                <div className="mt-3 flex flex-wrap items-center gap-2">
                  <input
                    value={note[complaint.id] ?? ""}
                    onChange={(e) => setNote((n) => ({ ...n, [complaint.id]: e.target.value }))}
                    placeholder="Resolution note (optional)"
                    className="min-w-[220px] flex-1 rounded-[var(--radius-input)] border border-[var(--color-outline)] px-3 py-1.5 text-[length:var(--text-label)]"
                  />
                  {NEXT_STATUS[complaint.status].map((status) => (
                    <button
                      key={status}
                      type="button"
                      onClick={() => void move(complaint.id, status)}
                      className="rounded-full border border-[var(--color-outline)] px-3 py-1.5 text-[length:var(--text-label)] hover:bg-[var(--color-surface-alt)]"
                    >
                      {status.replace("_", " ")}
                    </button>
                  ))}
                </div>
              )}
            </li>
          ))}
          {complaints.length === 0 && (
            <li className="card px-4 py-10 text-center text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
              Nothing here.
            </li>
          )}
        </ul>
      </main>
    </PortalShell>
  );
}
