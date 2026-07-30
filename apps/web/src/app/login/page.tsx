"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { api, writeSession, type PortalSession } from "@/lib/session";

interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: { id: string; role: string; wardId: string | null };
}

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const result = await api<LoginResponse>("/auth/login", {
        method: "POST",
        body: JSON.stringify({ phone, password }),
      });

      // The portal is for administrators; residents and drivers use the app.
      if (result.user.role !== "super_admin" && result.user.role !== "ward_admin") {
        throw new Error("This portal is for administrators only");
      }

      writeSession({
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userId: result.user.id,
        role: result.user.role,
        wardId: result.user.wardId,
      } satisfies PortalSession);
      router.push("/");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign in failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <main className="flex min-h-dvh items-center justify-center px-4">
      <form
        onSubmit={submit}
        className="w-full max-w-sm card p-6"
      >
        <h1 className="text-[length:var(--text-headline)] font-normal">Namma Kasa admin</h1>
        <p className="mt-1 text-[length:var(--text-body)] text-[var(--color-text-secondary)]">
          Sign in to manage wards, routes, and fleet.
        </p>

        <label className="mt-6 block text-[length:var(--text-label)] font-medium">
          Phone
          <input
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            inputMode="numeric"
            autoComplete="username"
            placeholder="919000000002"
            required
            className="mt-1 w-full rounded-[var(--radius-input)] border border-[var(--color-outline)] px-3 py-2 text-[length:var(--text-body)] outline-none focus:border-[var(--color-primary)]"
          />
        </label>

        <label className="mt-4 block text-[length:var(--text-label)] font-medium">
          Password
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            autoComplete="current-password"
            required
            className="mt-1 w-full rounded-[var(--radius-input)] border border-[var(--color-outline)] px-3 py-2 text-[length:var(--text-body)] outline-none focus:border-[var(--color-primary)]"
          />
        </label>

        {error && (
          <p
            role="alert"
            className="mt-4 rounded-[var(--radius-input)] bg-[var(--color-danger-container)] px-3 py-2 text-[length:var(--text-body)] text-[var(--color-danger)]"
          >
            {error}
          </p>
        )}

        <button
          type="submit"
          disabled={busy}
          className="mt-6 w-full rounded-full bg-[var(--color-primary)] px-4 py-3 text-[length:var(--text-body)] font-medium text-white transition-colors hover:bg-[var(--color-primary-pressed)] disabled:opacity-60"
        >
          {busy ? "Signing in…" : "Sign in"}
        </button>
      </form>
    </main>
  );
}
