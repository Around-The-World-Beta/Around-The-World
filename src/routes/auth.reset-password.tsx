import { createFileRoute, Link } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { Check, LockKeyhole } from "lucide-react";

import { useAuth } from "@/lib/auth/AuthProvider";
import {
  requireAuthenticatedUser,
  updatePassword,
  type AuthActionResult,
} from "@/lib/auth/auth.functions";
import { password as passwordSchema } from "@/lib/auth/validation";

export const Route = createFileRoute("/auth/reset-password")({
  beforeLoad: () =>
    requireAuthenticatedUser({ data: { returnTo: "/auth/reset-password" } }),
  head: () => ({
    meta: [
      { title: "Choose a new password — Around The World" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: ResetPasswordPage,
});

function ResetPasswordPage() {
  const { refreshAuth } = useAuth();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<AuthActionResult | null>(null);

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const strength = passwordSchema.safeParse(password);
    if (!strength.success) {
      setResult({
        ok: false,
        message:
          strength.error.issues[0]?.message ?? "Use a stronger password.",
      });
      return;
    }
    if (password !== confirm) {
      setResult({ ok: false, message: "Passwords do not match." });
      return;
    }

    setBusy(true);
    try {
      const response = await updatePassword({ data: { password } });
      setResult(response);
      if (response.ok) await refreshAuth();
    } catch {
      setResult({ ok: false, message: "The password could not be updated." });
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="min-h-[100dvh] px-5 py-12">
      <LockKeyhole className="size-10 text-primary" />
      <h1 className="mt-5 font-display text-4xl font-black uppercase italic leading-none">
        New password
      </h1>
      <p className="mt-2 text-sm text-muted-foreground">
        Choose a password you don’t use for another account.
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

      {result?.ok ? (
        <Link
          to="/profile"
          className="mt-6 flex items-center justify-center gap-2 rounded-xl bg-primary py-4 font-bold text-primary-foreground"
        >
          <Check className="size-4" />
          Continue to profile
        </Link>
      ) : (
        <form onSubmit={submit} className="mt-6 space-y-4">
          <PasswordField
            label="New password"
            value={password}
            onChange={setPassword}
          />
          <PasswordField
            label="Confirm password"
            value={confirm}
            onChange={setConfirm}
          />
          <p className="text-[11px] text-muted-foreground">
            12–72 characters with uppercase, lowercase, and a number.
          </p>
          <button
            type="submit"
            disabled={busy}
            className="w-full rounded-xl bg-primary py-4 font-display text-xl font-black uppercase italic text-primary-foreground disabled:opacity-50"
          >
            {busy ? "Updating…" : "Update password"}
          </button>
        </form>
      )}
    </main>
  );
}

function PasswordField({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
}) {
  return (
    <label className="block">
      <span className="mb-2 block text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
        {label}
      </span>
      <input
        required
        type="password"
        autoComplete="new-password"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        minLength={12}
        maxLength={72}
        className="auth-input"
      />
    </label>
  );
}

