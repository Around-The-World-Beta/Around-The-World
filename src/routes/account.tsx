import { createFileRoute, Link } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import {
  ArrowLeft,
  Check,
  KeyRound,
  LogOut,
  ShieldCheck,
  Smartphone,
  Trash2,
} from "lucide-react";

import { useAuth } from "@/lib/auth/AuthProvider";
import {
  deleteAccount,
  enrollMfa,
  getMfaFactors,
  requireAuthenticatedUser,
  signOut,
  unenrollMfa,
  updatePassword,
  verifyMfa,
  type AuthActionResult,
} from "@/lib/auth/auth.functions";
import { password as passwordSchema } from "@/lib/auth/validation";

export const Route = createFileRoute("/account")({
  beforeLoad: () =>
    requireAuthenticatedUser({ data: { returnTo: "/account" } }),
  loader: () => getMfaFactors(),
  head: () => ({
    meta: [
      { title: "Account security — Around The World" },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: AccountPage,
});

interface Enrollment {
  factorId: string;
  qrCode: string;
  secret: string;
}

function AccountPage() {
  const initialFactors = Route.useLoaderData();
  const { user, refreshAuth } = useAuth();
  const [factors, setFactors] = useState(initialFactors);
  const [enrollment, setEnrollment] = useState<Enrollment | null>(null);
  const [mfaCode, setMfaCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [deletePassword, setDeletePassword] = useState("");
  const [deleteConfirmation, setDeleteConfirmation] = useState("");
  const [busy, setBusy] = useState<string>();
  const [result, setResult] = useState<AuthActionResult | null>(null);
  const verifiedFactor = factors.find((factor) => factor.status === "verified");

  const refreshFactors = async () => {
    setFactors(await getMfaFactors());
    await refreshAuth();
  };

  const changePassword = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const strength = passwordSchema.safeParse(newPassword);
    if (!strength.success) {
      setResult({
        ok: false,
        message:
          strength.error.issues[0]?.message ?? "Use a stronger password.",
      });
      return;
    }
    if (newPassword !== confirmPassword) {
      setResult({ ok: false, message: "Passwords do not match." });
      return;
    }
    setBusy("password");
    try {
      const response = await updatePassword({
        data: { password: newPassword },
      });
      setResult(response);
      if (response.ok) {
        setNewPassword("");
        setConfirmPassword("");
      }
    } finally {
      setBusy(undefined);
    }
  };

  const startMfa = async () => {
    setBusy("mfa");
    setResult(null);
    try {
      const response = await enrollMfa();
      if (response.ok) {
        setEnrollment({
          factorId: response.factorId,
          qrCode: response.qrCode,
          secret: response.secret,
        });
      } else {
        setResult(response);
      }
    } finally {
      setBusy(undefined);
    }
  };

  const confirmMfa = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!enrollment) return;
    setBusy("mfa");
    try {
      const response = await verifyMfa({
        data: { factorId: enrollment.factorId, code: mfaCode },
      });
      setResult(response);
      if (response.ok) {
        setEnrollment(null);
        setMfaCode("");
        await refreshFactors();
      }
    } finally {
      setBusy(undefined);
    }
  };

  const removeMfa = async () => {
    if (!verifiedFactor) return;
    setBusy("mfa");
    try {
      const response = await unenrollMfa({
        data: { factorId: verifiedFactor.id },
      });
      setResult(response);
      if (response.ok) await refreshFactors();
    } finally {
      setBusy(undefined);
    }
  };

  const logout = async (allDevices: boolean) => {
    setBusy(allDevices ? "all-sessions" : "session");
    try {
      const response = await signOut({ data: { allDevices } });
      setResult(response);
      if (response.ok) {
        await refreshAuth();
        window.location.assign("/");
      }
    } finally {
      setBusy(undefined);
    }
  };

  const removeAccount = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusy("delete");
    try {
      const response = await deleteAccount({
        data: {
          confirmation: deleteConfirmation,
          password: deletePassword || undefined,
        },
      });
      setResult(response);
      if (response.ok) {
        window.location.assign("/");
      }
    } catch {
      setResult({
        ok: false,
        message: "Type DELETE exactly before continuing.",
      });
    } finally {
      setBusy(undefined);
    }
  };

  if (!user) return null;

  return (
    <main className="min-h-[100dvh] px-5 py-6">
      <header className="mb-8 flex items-center gap-3">
        <Link
          to="/profile"
          aria-label="Back to profile"
          className="flex size-10 items-center justify-center rounded-full border border-border bg-card"
        >
          <ArrowLeft className="size-4" />
        </Link>
        <div>
          <h1 className="font-display text-2xl font-black uppercase italic">
            Account security
          </h1>
          <p className="text-xs text-muted-foreground">{user.email}</p>
        </div>
      </header>

      {result && (
        <div
          role="status"
          className={`mb-5 rounded-2xl border p-3 text-sm ${
            result.ok
              ? "border-primary/30 bg-primary/10"
              : "border-destructive/30 bg-destructive/10"
          }`}
        >
          {result.message}
        </div>
      )}

      <section className="space-y-3">
        <SecurityCard
          icon={<ShieldCheck className="size-5 text-primary" />}
          title="Account status"
        >
          <div className="mt-3 space-y-2 text-sm">
            <StatusRow
              label="Email"
              value={user.emailVerified ? "Verified" : "Verification required"}
              good={user.emailVerified}
            />
            <StatusRow label="Sign-in method" value={providerLabel(user.provider)} />
            <StatusRow label="Access level" value={user.role} />
          </div>
        </SecurityCard>

        <SecurityCard
          icon={<Smartphone className="size-5 text-primary" />}
          title="Two-step verification"
        >
          <p className="mt-2 text-xs leading-relaxed text-muted-foreground">
            Protect your account with a six-digit code from an authenticator
            app. Administrators must keep this enabled.
          </p>

          {verifiedFactor ? (
            <div className="mt-4">
              <div className="flex items-center gap-2 text-sm font-semibold text-primary">
                <Check className="size-4" />
                Authenticator enabled
              </div>
              {user.role !== "admin" && (
                <button
                  type="button"
                  onClick={removeMfa}
                  disabled={busy === "mfa"}
                  className="mt-3 rounded-xl border border-border px-4 py-2 text-xs font-semibold"
                >
                  Remove authenticator
                </button>
              )}
            </div>
          ) : enrollment ? (
            <form onSubmit={confirmMfa} className="mt-4 space-y-3">
              <div className="rounded-2xl bg-white p-4">
                <img
                  src={enrollment.qrCode}
                  alt="Authenticator setup QR code"
                  className="mx-auto size-48"
                />
              </div>
              <p className="break-all font-mono text-[10px] text-muted-foreground">
                Manual key: {enrollment.secret}
              </p>
              <input
                required
                inputMode="numeric"
                autoComplete="one-time-code"
                pattern="[0-9]{6}"
                value={mfaCode}
                onChange={(event) =>
                  setMfaCode(
                    event.target.value.replace(/\D/g, "").slice(0, 6),
                  )
                }
                maxLength={6}
                placeholder="000000"
                aria-label="Authenticator verification code"
                className="auth-input text-center font-mono text-xl tracking-[0.35em]"
              />
              <button
                type="submit"
                disabled={busy === "mfa" || mfaCode.length !== 6}
                className="w-full rounded-xl bg-primary py-3 font-bold text-primary-foreground disabled:opacity-50"
              >
                Confirm authenticator
              </button>
            </form>
          ) : (
            <button
              type="button"
              onClick={startMfa}
              disabled={busy === "mfa"}
              className="mt-4 rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-primary-foreground disabled:opacity-50"
            >
              Set up authenticator
            </button>
          )}
        </SecurityCard>

        {user.provider === "email" && (
          <SecurityCard
            icon={<KeyRound className="size-5 text-primary" />}
            title="Change password"
          >
            <form onSubmit={changePassword} className="mt-4 space-y-3">
              <input
                required
                type="password"
                autoComplete="new-password"
                minLength={12}
                maxLength={72}
                value={newPassword}
                onChange={(event) => setNewPassword(event.target.value)}
                placeholder="New password"
                className="auth-input"
              />
              <input
                required
                type="password"
                autoComplete="new-password"
                minLength={12}
                maxLength={72}
                value={confirmPassword}
                onChange={(event) => setConfirmPassword(event.target.value)}
                placeholder="Confirm new password"
                className="auth-input"
              />
              <button
                type="submit"
                disabled={busy === "password"}
                className="rounded-xl border border-primary px-4 py-2.5 text-sm font-bold text-primary"
              >
                Update password
              </button>
            </form>
          </SecurityCard>
        )}

        <SecurityCard
          icon={<LogOut className="size-5 text-primary" />}
          title="Sessions"
        >
          <div className="mt-4 grid gap-2">
            <button
              type="button"
              onClick={() => logout(false)}
              disabled={Boolean(busy)}
              className="rounded-xl border border-border px-4 py-3 text-left text-sm font-semibold"
            >
              Sign out on this device
            </button>
            <button
              type="button"
              onClick={() => logout(true)}
              disabled={Boolean(busy)}
              className="rounded-xl border border-border px-4 py-3 text-left text-sm font-semibold"
            >
              Sign out on all devices
            </button>
          </div>
        </SecurityCard>

        <SecurityCard
          icon={<Trash2 className="size-5 text-destructive" />}
          title="Delete account"
          danger
        >
          <p className="mt-2 text-xs leading-relaxed text-muted-foreground">
            This permanently removes your account and associated profile data.
            Game-data handling will follow the published retention policy.
          </p>
          <form onSubmit={removeAccount} className="mt-4 space-y-3">
            {user.provider === "email" && (
              <input
                required
                type="password"
                autoComplete="current-password"
                value={deletePassword}
                onChange={(event) => setDeletePassword(event.target.value)}
                placeholder="Current password"
                className="auth-input"
              />
            )}
            <input
              required
              value={deleteConfirmation}
              onChange={(event) => setDeleteConfirmation(event.target.value)}
              placeholder="Type DELETE"
              className="auth-input"
            />
            <button
              type="submit"
              disabled={busy === "delete" || deleteConfirmation !== "DELETE"}
              className="rounded-xl bg-destructive px-4 py-2.5 text-sm font-bold text-white disabled:opacity-50"
            >
              Permanently delete account
            </button>
          </form>
        </SecurityCard>
      </section>
    </main>
  );
}

function SecurityCard({
  icon,
  title,
  danger = false,
  children,
}: {
  icon: React.ReactNode;
  title: string;
  danger?: boolean;
  children: React.ReactNode;
}) {
  return (
    <section
      className={`rounded-2xl border bg-card p-4 ${
        danger ? "border-destructive/40" : "border-border"
      }`}
    >
      <div className="flex items-center gap-2">
        {icon}
        <h2 className="font-display text-sm font-black uppercase italic">
          {title}
        </h2>
      </div>
      {children}
    </section>
  );
}

function StatusRow({
  label,
  value,
  good = false,
}: {
  label: string;
  value: string;
  good?: boolean;
}) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="text-muted-foreground">{label}</span>
      <span className={good ? "font-semibold text-primary" : "font-semibold"}>
        {value}
      </span>
    </div>
  );
}

function providerLabel(provider: string) {
  if (provider === "apple") return "Sign in with Apple";
  if (provider === "email") return "Email and password";
  return provider;
}

