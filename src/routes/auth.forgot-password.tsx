import { createFileRoute, Link } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { ArrowLeft, Mail } from "lucide-react";

import { Turnstile } from "@/components/Turnstile";
import { useAuth } from "@/lib/auth/AuthProvider";
import {
  requestPasswordReset,
  type AuthActionResult,
} from "@/lib/auth/auth.functions";

export const Route = createFileRoute("/auth/forgot-password")({
  head: () => ({
    meta: [
      { title: "Reset password — Around The World" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: ForgotPasswordPage,
});

function ForgotPasswordPage() {
  const { configured } = useAuth();
  const [email, setEmail] = useState("");
  const [captchaToken, setCaptchaToken] = useState<string>();
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<AuthActionResult | null>(null);

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusy(true);
    try {
      setResult(
        await requestPasswordReset({ data: { email, captchaToken } }),
      );
    } catch {
      setResult({ ok: false, message: "Check the email and try again." });
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="min-h-[100dvh] px-5 py-6">
      <Link
        to="/auth"
        search={{ mode: "login", next: undefined, message: undefined }}
        aria-label="Back to sign in"
        className="mb-8 flex size-10 items-center justify-center rounded-full border border-border bg-card"
      >
        <ArrowLeft className="size-4" />
      </Link>
      <h1 className="font-display text-4xl font-black uppercase italic leading-none">
        Reset password
      </h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Enter your account email. We’ll send a secure, time-limited reset link.
      </p>

      {result && (
        <div
          role="status"
          className={`mt-5 rounded-2xl border p-3 text-sm ${
            result.ok
              ? "border-primary/30 bg-primary/10"
              : "border-destructive/30 bg-destructive/10"
          }`}
        >
          {result.message}
        </div>
      )}

      <form onSubmit={submit} className="mt-6 space-y-4">
        <label className="block">
          <span className="mb-2 block text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
            Email
          </span>
          <div className="relative">
            <Mail className="pointer-events-none absolute left-3 top-3.5 size-4 text-muted-foreground" />
            <input
              required
              type="email"
              autoComplete="email"
              autoCapitalize="none"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              maxLength={254}
              placeholder="you@example.com"
              className="auth-input pl-10"
            />
          </div>
        </label>
        <Turnstile onToken={setCaptchaToken} />
        <button
          type="submit"
          disabled={!configured || busy}
          className="w-full rounded-xl bg-primary py-4 font-display text-xl font-black uppercase italic text-primary-foreground disabled:opacity-50"
        >
          {busy ? "Sending…" : "Send reset link"}
        </button>
      </form>
    </main>
  );
}

