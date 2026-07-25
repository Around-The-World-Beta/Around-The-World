import { createFileRoute, Link } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import { Apple, ArrowLeft, Eye, EyeOff, LockKeyhole, Mail } from "lucide-react";
import { z } from "zod";

import { Turnstile } from "@/components/Turnstile";
import { useAuth } from "@/lib/auth/AuthProvider";
import {
  beginAppleSignIn,
  signIn,
  signUp,
  type AuthActionResult,
} from "@/lib/auth/auth.functions";
import { password as passwordSchema } from "@/lib/auth/validation";

const authSearchSchema = z.object({
  mode: z.enum(["login", "signup"]).catch("login"),
  next: z.string().optional(),
  message: z.string().max(300).optional(),
});

export const Route = createFileRoute("/auth")({
  validateSearch: authSearchSchema,
  head: () => ({
    meta: [
      { title: "Sign in — Around The World" },
      {
        name: "description",
        content: "Sign in or create your Around The World player account.",
      },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: AuthPage,
});

function AuthPage() {
  const search = Route.useSearch();
  const navigate = Route.useNavigate();
  const { configured, user, refreshAuth } = useAuth();
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [acceptedTerms, setAcceptedTerms] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [captchaToken, setCaptchaToken] = useState<string>();
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<AuthActionResult | null>(
    search.message ? { ok: false, message: search.message } : null,
  );

  const isSignup = search.mode === "signup";
  const next = safeClientReturnPath(search.next);

  const switchMode = (mode: "login" | "signup") => {
    setResult(null);
    setPassword("");
    setCaptchaToken(undefined);
    navigate({
      search: { mode, next: search.next, message: undefined },
      replace: true,
    });
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusy(true);
    setResult(null);
    try {
      if (isSignup) {
        const strength = passwordSchema.safeParse(password);
        if (!strength.success) {
          setResult({
            ok: false,
            message:
              strength.error.issues[0]?.message ?? "Use a stronger password.",
          });
          return;
        }
        const response = await signUp({
          data: {
            displayName,
            email,
            password,
            acceptedTerms,
            captchaToken,
          },
        });
        setResult(response);
      } else {
        const response = await signIn({
          data: { email, password, captchaToken },
        });
        setResult(response);
        if (response.ok) {
          const state = await refreshAuth();
          if (state.mfaRequired) {
            await navigate({ to: "/auth/mfa", search: { next } });
          } else {
            window.location.assign(next);
          }
        }
      }
    } catch {
      setResult({ ok: false, message: "Check the form and try again." });
    } finally {
      setBusy(false);
    }
  };

  const handleApple = async () => {
    setBusy(true);
    setResult(null);
    try {
      const response = await beginAppleSignIn({ data: { next } });
      if (response.ok && response.redirectTo) {
        window.location.assign(response.redirectTo);
        return;
      }
      setResult(response);
    } catch {
      setResult({ ok: false, message: "Sign in with Apple could not start." });
    } finally {
      setBusy(false);
    }
  };

  if (user) {
    return (
      <AuthShell>
        <div className="rounded-3xl border border-border bg-card p-6 text-center">
          <h1 className="font-display text-2xl font-black uppercase italic">
            You're signed in
          </h1>
          <p className="mt-2 text-sm text-muted-foreground">{user.email}</p>
          <a
            href={next}
            className="mt-5 block rounded-xl bg-primary py-3 font-bold text-primary-foreground"
          >
            Continue
          </a>
        </div>
      </AuthShell>
    );
  }

  return (
    <AuthShell>
      <div className="mb-6">
        <span className="inline-flex items-center gap-2 rounded-full border border-primary/30 bg-primary/10 px-3 py-1 text-[10px] font-bold uppercase tracking-widest text-primary">
          <LockKeyhole className="size-3.5" />
          Secure player account
        </span>
        <h1 className="mt-4 font-display text-4xl font-black uppercase italic leading-none">
          {isSignup ? "Join the squad" : "Welcome back"}
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          {isSignup
            ? "Create your account to host and join nearby games."
            : "Sign in to manage your games and player profile."}
        </p>
      </div>

      {!configured && (
        <Status
          ok={false}
          message="Account services need to be connected to the development environment before sign-in can go live."
        />
      )}
      {result && <Status ok={result.ok} message={result.message} />}

      <div className="mb-5 grid grid-cols-2 rounded-2xl border border-border bg-card p-1">
        <button
          type="button"
          onClick={() => switchMode("login")}
          className={`rounded-xl px-3 py-2.5 text-sm font-bold ${
            !isSignup
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground"
          }`}
        >
          Sign in
        </button>
        <button
          type="button"
          onClick={() => switchMode("signup")}
          className={`rounded-xl px-3 py-2.5 text-sm font-bold ${
            isSignup
              ? "bg-primary text-primary-foreground"
              : "text-muted-foreground"
          }`}
        >
          Create account
        </button>
      </div>

      <button
        type="button"
        disabled={busy || !configured}
        onClick={handleApple}
        className="flex w-full items-center justify-center gap-2 rounded-xl border border-border bg-card py-3.5 font-semibold disabled:cursor-not-allowed disabled:opacity-50"
      >
        <Apple className="size-5 fill-current" />
        Continue with Apple
      </button>

      <div className="my-5 flex items-center gap-3 text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
        <span className="h-px flex-1 bg-border" />
        or use email
        <span className="h-px flex-1 bg-border" />
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {isSignup && (
          <AuthField label="Full name">
            <input
              required
              autoComplete="name"
              value={displayName}
              onChange={(event) => setDisplayName(event.target.value)}
              minLength={2}
              maxLength={60}
              placeholder="Alex Rivera"
              className="auth-input"
            />
          </AuthField>
        )}

        <AuthField label="Email">
          <div className="relative">
            <Mail className="pointer-events-none absolute left-3 top-3.5 size-4 text-muted-foreground" />
            <input
              required
              type="email"
              inputMode="email"
              autoCapitalize="none"
              autoComplete={isSignup ? "email" : "username"}
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              maxLength={254}
              placeholder="you@example.com"
              className="auth-input pl-10"
            />
          </div>
        </AuthField>

        <AuthField label="Password">
          <div className="relative">
            <input
              required
              type={showPassword ? "text" : "password"}
              autoComplete={isSignup ? "new-password" : "current-password"}
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              minLength={isSignup ? 12 : 1}
              maxLength={72}
              placeholder={isSignup ? "12+ characters" : "Your password"}
              className="auth-input pr-11"
            />
            <button
              type="button"
              onClick={() => setShowPassword((value) => !value)}
              aria-label={showPassword ? "Hide password" : "Show password"}
              className="absolute right-2 top-2 flex size-9 items-center justify-center text-muted-foreground"
            >
              {showPassword ? (
                <EyeOff className="size-4" />
              ) : (
                <Eye className="size-4" />
              )}
            </button>
          </div>
          {isSignup && (
            <p className="mt-1.5 text-[11px] leading-relaxed text-muted-foreground">
              Use 12–72 characters with uppercase, lowercase, and a number.
            </p>
          )}
        </AuthField>

        {isSignup ? (
          <label className="flex items-start gap-3 text-xs leading-relaxed text-muted-foreground">
            <input
              type="checkbox"
              checked={acceptedTerms}
              onChange={(event) => setAcceptedTerms(event.target.checked)}
              className="mt-0.5 size-4 rounded border-border accent-[hsl(var(--primary))]"
            />
            <span>
              I agree to the Terms, Privacy Policy, and Community Rules.
            </span>
          </label>
        ) : (
          <div className="text-right">
            <Link
              to="/auth/forgot-password"
              className="text-xs font-semibold text-primary"
            >
              Forgot password?
            </Link>
          </div>
        )}

        <Turnstile onToken={setCaptchaToken} />

        <button
          type="submit"
          disabled={busy || !configured || (isSignup && !acceptedTerms)}
          className="w-full rounded-xl bg-primary py-4 font-display text-xl font-black uppercase italic text-primary-foreground disabled:cursor-not-allowed disabled:opacity-50"
        >
          {busy
            ? "Please wait…"
            : isSignup
              ? "Create account"
              : "Sign in"}
        </button>
      </form>

      <p className="mt-6 text-center text-xs text-muted-foreground">
        Your password is never visible to Around The World staff.
      </p>
    </AuthShell>
  );
}

function safeClientReturnPath(next?: string) {
  return next?.startsWith("/") && !next.startsWith("//") ? next : "/profile";
}

function AuthShell({ children }: { children: React.ReactNode }) {
  return (
    <main className="min-h-[100dvh] px-5 py-6">
      <Link
        to="/"
        aria-label="Back to matches"
        className="mb-8 flex size-10 items-center justify-center rounded-full border border-border bg-card"
      >
        <ArrowLeft className="size-4" />
      </Link>
      {children}
    </main>
  );
}

function AuthField({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="block">
      <span className="mb-2 block text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
        {label}
      </span>
      {children}
    </label>
  );
}

function Status({ ok, message }: { ok: boolean; message: string }) {
  return (
    <div
      role="status"
      className={`mb-4 rounded-2xl border p-3 text-sm ${
        ok
          ? "border-primary/30 bg-primary/10 text-foreground"
          : "border-destructive/30 bg-destructive/10 text-foreground"
      }`}
    >
      {message}
    </div>
  );
}

