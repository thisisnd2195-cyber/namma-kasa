"use client";

export interface PortalSession {
  accessToken: string;
  refreshToken: string;
  userId: string;
  role: "super_admin" | "ward_admin";
  wardId: string | null;
}

const KEY = "namma-kasa-portal-session";

/**
 * Parsed value is cached against its raw string so repeated reads return the
 * same object reference — required for useSyncExternalStore, which loops
 * forever on a snapshot that allocates each call.
 */
let cache: { raw: string | null; value: PortalSession | null } = { raw: null, value: null };

export function readSession(): PortalSession | null {
  if (typeof window === "undefined") return null;
  const raw = window.sessionStorage.getItem(KEY);
  if (raw !== cache.raw) {
    cache = { raw, value: raw ? (JSON.parse(raw) as PortalSession) : null };
  }
  return cache.value;
}

export function writeSession(session: PortalSession): void {
  window.sessionStorage.setItem(KEY, JSON.stringify(session));
  cache = { raw: null, value: null };
}

export function clearSession(): void {
  window.sessionStorage.removeItem(KEY);
  cache = { raw: null, value: null };
}

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? "http://localhost:4000/v1";

/**
 * Thin fetch wrapper that attaches the bearer token and unwraps the API's
 * problem+json into a plain Error message.
 */
export async function api<T>(path: string, init: RequestInit = {}): Promise<T> {
  const session = readSession();
  const response = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      ...init.headers,
    },
  });

  if (!response.ok) {
    const problem = (await response.json().catch(() => null)) as Record<string, unknown> | null;
    const error = new Error(
      (problem?.detail as string) ?? (problem?.message as string) ?? (problem?.title as string) ??
        "Request failed",
    );
    // RFC 9457 extension members ride along — a boundary clash carries the
    // intersection geometry the map needs to shade.
    Object.assign(error, { status: response.status, ...problem });
    throw error;
  }
  if (response.status === 204) return undefined as T;
  return (await response.json()) as T;
}
