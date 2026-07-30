"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useSyncExternalStore } from "react";
import { clearSession, readSession } from "@/lib/session";

/** The session only changes via sign-in or sign-out, both of which navigate. */
const subscribeToNothing = () => () => {};

const NAV = [
  { href: "/dashboard", label: "Today", superOnly: false },
  { href: "/wards", label: "Wards", superOnly: true },
  { href: "/routes", label: "Routes", superOnly: false },
  { href: "/fleet", label: "Fleet", superOnly: false },
  { href: "/live", label: "Live", superOnly: false },
  { href: "/review-queue", label: "Review queue", superOnly: false },
  { href: "/complaints", label: "Complaints", superOnly: false },
];

/**
 * Client-side gate. The API enforces authorisation on every call regardless —
 * this only avoids rendering a shell the user cannot populate.
 */
export function PortalShell({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  // sessionStorage is external mutable state; reading it through this hook
  // keeps the server render (null) and the client render consistent.
  const session = useSyncExternalStore(subscribeToNothing, readSession, () => null);

  useEffect(() => {
    // Consult the store directly, not the hook's value: during hydration the
    // hook reports the server snapshot (null) for the first committed render,
    // and redirecting on that kicked every signed-in admin to /login on any
    // hard refresh or deep link — with their valid session still in storage.
    if (!readSession()) router.replace("/login");
  }, [session, router]);

  if (!session) return null;

  const items = NAV.filter((item) => !item.superOnly || session.role === "super_admin");

  return (
    <div className="min-h-dvh">
      <header className="flex items-center gap-6 border-b border-[var(--color-outline)] px-6 py-3">
        <Link href="/" className="text-[length:var(--text-title)] font-medium">
          Namma Kasa
        </Link>
        <nav className="flex gap-1">
          {items.map((item) => {
            const active = pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`rounded-full px-3 py-1.5 text-[length:var(--text-body)] transition-colors ${
                  active
                    ? "bg-[var(--color-primary-container)] text-[var(--color-primary-pressed)]"
                    : "text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-alt)]"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
        <div className="ml-auto flex items-center gap-3 text-[length:var(--text-label)] text-[var(--color-text-secondary)]">
          <span>{session.role === "super_admin" ? "Super admin" : "Ward admin"}</span>
          <button
            type="button"
            onClick={() => {
              clearSession();
              router.replace("/login");
            }}
            className="rounded-full border border-[var(--color-outline)] px-3 py-1 hover:bg-[var(--color-surface-alt)]"
          >
            Sign out
          </button>
        </div>
      </header>
      {children}
    </div>
  );
}
