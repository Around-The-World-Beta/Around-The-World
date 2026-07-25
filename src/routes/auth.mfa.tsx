import { createFileRoute } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { ShieldCheck } from "lucide-react";
import { z } from "zod";

import { useAuth } from "@/lib/auth/AuthProvider";
import {
  getAuthState,
  getMfaFactors,
  verifyMfa,
  type AuthActionResult,
} from "@/lib/auth/auth.functions";

const mfaSearchSchema = z.object({
  next: z.string().optional(),
});

export const Route = createFileRoute("/auth/mfa")({
  validateSearch: mfaSearchSchema,
  beforeLoad: async () => {
    const state = await getAuthState();
    if (!state.user) {
      throw new Error("Sign in before completing two-step verification.");
    }
  },
  loader: () => getMfaFactors(),
  head: () => ({
    meta: [
      { title: "Two-step verification — Around The World" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: MfaChallengePage,
});

function MfaChallengePage() {
  const factors = Route.useLoaderData();
  const search = Route.useSearch();
  const navigate = Route.useNavigate();
  const { refreshAuth } = useAuth();
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<AuthActionResult | null>(null);
  const factor = factors.find((item) => item.status === "verified");

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!factor) return;
    setBusy(true);
    try {
      const response = await verifyMfa({
        data: { factorId: factor.id, code },
      });
      setResult(response);
      if (response.ok) {
        await refreshAuth();
        window.location.assign(safeNext(search.next));
      }
    } catch {
      setResult({ ok: false, message: "Enter the six-digit code." });
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="flex min-h-[100dvh] items-center px-5 py-10">
      <div className="w-full">
        <ShieldCheck className="size-12 text-primary" />
        <h1 className="mt-5 font-display text-4xl font-black uppercase italic leading-none">
          Verify it’s you
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          Enter the six-digit code from your authenticator app.
        </p>

        {result && (
          <div className="mt-5 rounded-2xl border border-destructive/30 bg-destructive/10 p-3 text-sm">
            {result.message}
          </div>
        )}

        {factor ? (
          <form onSubmit={submit} className="mt-6 space-y-4">
            <input
              required
              inputMode="numeric"
              autoComplete="one-time-code"
              pattern="[0-9]{6}"
              maxLength={6}
              value={code}
              onChange={(event) =>
                setCode(event.target.value.replace(/\D/g, "").slice(0, 6))
              }
              aria-label="Six-digit verification code"
              className="auth-input text-center font-mono text-2xl tracking-[0.45em]"
            />
            <button
              type="submit"
              disabled={busy || code.length !== 6}
              className="w-full rounded-xl bg-primary py-4 font-display text-xl font-black uppercase italic text-primary-foreground disabled:opacity-50"
            >
              {busy ? "Verifying…" : "Verify"}
            </button>
          </form>
        ) : (
          <div className="mt-6 rounded-2xl border border-destructive/30 bg-destructive/10 p-4 text-sm">
            No verified authenticator was found. Sign out and contact support
            if this continues.
          </div>
        )}
      </div>
    </main>
  );
}

function safeNext(next?: string) {
  return next?.startsWith("/") && !next.startsWith("//") ? next : "/profile";
}

