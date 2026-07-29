"use client";

export interface PortalSession {
  accessToken: string;
  refreshToken: string;
  userId: string;
  role: "super_admin" | "ward_admin";
  wardId: string | null;
}

const KEY = "namma-kasa-portal-session";

export function readSession(): PortalSession | null {
  if (typeof window === "undefined") return null;
  const raw = window.sessionStorage.getItem(KEY);
  return raw ? (JSON.parse(raw) as PortalSession) : null;
}

export function writeSession(session: PortalSession): void {
  window.sessionStorage.setItem(KEY, JSON.stringify(session));
}

export function clearSession(): void {
  window.sessionStorage.removeItem(KEY);
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
    const problem = (await response.json().catch(() => null)) as
      | { detail?: string; title?: string }
      | null;
    throw new Error(problem?.detail ?? problem?.title ?? "Request failed");
  }
  return (await response.json()) as T;
}
