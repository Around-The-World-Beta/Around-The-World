import { createFileRoute, Link } from "@tanstack/react-router";
import { useState, type FormEvent } from "react";
import {
  Check,
  MapPin,
  Pencil,
  Settings,
  ShieldCheck,
  X,
} from "lucide-react";

import avatarDefault from "@/assets/avatar.jpg";
import { useAuth } from "@/lib/auth/AuthProvider";
import {
  getAuthState,
  requireAuthenticatedUser,
  updateProfile,
  type AuthActionResult,
} from "@/lib/auth/auth.functions";

const POSITIONS = [
  "Goalkeeper",
  "Defender",
  "Midfielder",
  "Forward",
] as const;
const SKILLS = ["Casual", "Intermediate", "Baller", "Open to All"] as const;
type Position = (typeof POSITIONS)[number];
type Skill = (typeof SKILLS)[number];

interface ProfileDraft {
  displayName: string;
  city: string;
  bio: string;
  favoritePosition: Position | null;
  skillLevel: Skill | null;
}

export const Route = createFileRoute("/profile")({
  beforeLoad: () =>
    requireAuthenticatedUser({ data: { returnTo: "/profile" } }),
  loader: () => getAuthState(),
  head: () => ({
    meta: [
      { title: "Profile — Around The World" },
      { name: "description", content: "Your Around The World player profile." },
      { name: "robots", content: "noindex" },
    ],
  }),
  component: ProfilePage,
});

function ProfilePage() {
  const loaded = Route.useLoaderData();
  const { user, profile, refreshAuth } = useAuth();
  const effectiveProfile = profile ?? loaded.profile;
  const [editing, setEditing] = useState(false);
  const [result, setResult] = useState<AuthActionResult | null>(null);

  if (!user || !effectiveProfile) return null;

  return (
    <div className="pb-24">
      <header className="relative flex flex-col items-center border-b border-border bg-card px-5 pb-8 pt-10 text-center">
        <button
          onClick={() => setEditing(true)}
          aria-label="Edit profile"
          className="absolute right-4 top-4 flex items-center gap-1.5 rounded-full border border-border bg-card px-3 py-1.5 text-xs font-semibold"
        >
          <Pencil className="size-3.5" />
          Edit
        </button>
        <img
          src={effectiveProfile.avatar_url || avatarDefault}
          alt={effectiveProfile.display_name}
          width={512}
          height={512}
          className="size-24 rounded-full border-2 border-primary object-cover"
        />
        <h1 className="mt-4 font-display text-3xl font-bold uppercase">
          {effectiveProfile.display_name}
        </h1>
        {effectiveProfile.city && (
          <p className="flex items-center gap-1 text-sm text-muted-foreground">
            <MapPin className="size-3.5" /> {effectiveProfile.city}
          </p>
        )}
        {(effectiveProfile.skill_level ||
          effectiveProfile.favorite_position) && (
          <span className="mt-3 rounded-full border border-border bg-card px-3 py-1 text-[10px] font-bold uppercase tracking-widest text-primary">
            {[effectiveProfile.skill_level, effectiveProfile.favorite_position]
              .filter(Boolean)
              .join(" • ")}
          </span>
        )}
        {effectiveProfile.bio && (
          <p className="mt-4 max-w-sm text-sm leading-relaxed text-foreground/80">
            {effectiveProfile.bio}
          </p>
        )}
      </header>

      {result && (
        <div
          role="status"
          className={`mx-5 mt-5 rounded-2xl border p-3 text-sm ${
            result.ok
              ? "border-primary/30 bg-primary/10"
              : "border-destructive/30 bg-destructive/10"
          }`}
        >
          {result.message}
        </div>
      )}

      <section className="px-5 py-6">
        <div className="rounded-2xl border border-border bg-card p-4">
          <div className="flex items-center gap-3">
            <div className="flex size-10 items-center justify-center rounded-xl bg-primary/10">
              <ShieldCheck className="size-5 text-primary" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold">{user.email}</p>
              <p className="text-xs text-muted-foreground">
                {user.emailVerified ? "Verified account" : "Email verification required"}
              </p>
            </div>
            {user.emailVerified && <Check className="size-4 text-primary" />}
          </div>
        </div>

        <Link
          to="/account"
          className="mt-3 flex w-full items-center gap-3 rounded-2xl border border-border bg-card p-4 text-left"
        >
          <div className="flex size-10 items-center justify-center rounded-xl bg-secondary">
            <Settings className="size-5 text-primary" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-semibold">Account & Security</p>
            <p className="text-xs text-muted-foreground">
              Password, two-step verification, sessions, deletion
            </p>
          </div>
        </Link>
      </section>

      {editing && (
        <EditProfileSheet
          initial={{
            displayName: effectiveProfile.display_name,
            city: effectiveProfile.city ?? "",
            bio: effectiveProfile.bio ?? "",
            favoritePosition:
              effectiveProfile.favorite_position as Position | null,
            skillLevel: effectiveProfile.skill_level as Skill | null,
          }}
          onClose={() => setEditing(false)}
          onSaved={async (response) => {
            setResult(response);
            if (response.ok) {
              await refreshAuth();
              setEditing(false);
            }
          }}
        />
      )}
    </div>
  );
}

function EditProfileSheet({
  initial,
  onClose,
  onSaved,
}: {
  initial: ProfileDraft;
  onClose: () => void;
  onSaved: (result: AuthActionResult) => Promise<void>;
}) {
  const [draft, setDraft] = useState(initial);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();

  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setBusy(true);
    setError(undefined);
    try {
      const response = await updateProfile({ data: draft });
      if (!response.ok) setError(response.message);
      await onSaved(response);
    } catch {
      setError("Check your profile details and try again.");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="fixed inset-x-0 top-0 z-50 flex h-[100dvh] min-h-0 flex-col overflow-hidden bg-background">
      <header className="z-10 flex shrink-0 items-center justify-between border-b border-border bg-card/95 px-4 py-3 backdrop-blur">
        <button
          type="button"
          onClick={onClose}
          aria-label="Close"
          className="flex size-9 items-center justify-center rounded-full border border-border"
        >
          <X className="size-4" />
        </button>
        <h2 className="font-display text-base font-bold uppercase tracking-tight">
          Edit profile
        </h2>
        <div className="size-9" />
      </header>

      <form
        onSubmit={submit}
        className="min-h-0 flex-1 overflow-y-auto px-5 py-6 pb-24"
      >
        {error && (
          <div className="mb-5 rounded-2xl border border-destructive/30 bg-destructive/10 p-3 text-sm">
            {error}
          </div>
        )}

        <Field label="Display name">
          <input
            required
            autoComplete="name"
            minLength={2}
            maxLength={60}
            value={draft.displayName}
            onChange={(event) =>
              setDraft({ ...draft, displayName: event.target.value })
            }
            className="auth-input"
          />
        </Field>

        <Field label="City">
          <input
            autoComplete="address-level2"
            maxLength={100}
            value={draft.city}
            onChange={(event) =>
              setDraft({ ...draft, city: event.target.value })
            }
            placeholder="Brooklyn, NY"
            className="auth-input"
          />
          <p className="mt-1 text-[10px] text-muted-foreground">
            Use a city or neighborhood—not your home address.
          </p>
        </Field>

        <Field label="Position">
          <div className="grid grid-cols-2 gap-2">
            {POSITIONS.map((position) => (
              <Choice
                key={position}
                active={draft.favoritePosition === position}
                onClick={() =>
                  setDraft({ ...draft, favoritePosition: position })
                }
              >
                {position}
              </Choice>
            ))}
          </div>
        </Field>

        <Field label="Skill level">
          <div className="grid grid-cols-2 gap-2">
            {SKILLS.map((skill) => (
              <Choice
                key={skill}
                active={draft.skillLevel === skill}
                onClick={() => setDraft({ ...draft, skillLevel: skill })}
              >
                {skill}
              </Choice>
            ))}
          </div>
        </Field>

        <Field label="Bio">
          <textarea
            rows={4}
            maxLength={200}
            value={draft.bio}
            onChange={(event) =>
              setDraft({ ...draft, bio: event.target.value })
            }
            placeholder="Tell other players a little about your game…"
            className="auth-input resize-none"
          />
          <p className="mt-1 text-right text-[10px] text-muted-foreground">
            {draft.bio.length}/200
          </p>
        </Field>

        <button
          type="submit"
          disabled={busy}
          className="w-full rounded-xl bg-primary py-4 font-display text-xl font-black uppercase italic text-primary-foreground disabled:opacity-50"
        >
          {busy ? "Saving…" : "Save profile"}
        </button>
      </form>
    </div>
  );
}

function Field({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <label className="mb-5 block">
      <span className="mb-2 block text-[11px] font-bold uppercase tracking-widest text-muted-foreground">
        {label}
      </span>
      {children}
    </label>
  );
}

function Choice({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-xl border px-3 py-2.5 text-sm font-semibold ${
        active
          ? "border-primary bg-primary text-primary-foreground"
          : "border-border bg-card"
      }`}
    >
      {children}
    </button>
  );
}

