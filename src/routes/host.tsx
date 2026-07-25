import { createFileRoute, Link } from "@tanstack/react-router";
import { useState } from "react";
import { ArrowLeft, Check } from "lucide-react";
import type { SkillLevel } from "@/lib/mock-data";
import { requireAuthenticatedUser } from "@/lib/auth/auth.functions";

export const Route = createFileRoute("/host")({
  beforeLoad: () =>
    requireAuthenticatedUser({ data: { returnTo: "/host" } }),
  head: () => ({
    meta: [
      { title: "Host a Game — KickUp" },
      { name: "description", content: "Post your soccer pickup game and fill the squad." },
    ],
  }),
  component: HostPage,
});

const skills: SkillLevel[] = ["Casual", "Intermediate", "Baller", "Open to All"];
const formats = ["5v5", "6v6", "7v7", "8v8", "11v11"];

function HostPage() {
  const [skill, setSkill] = useState<SkillLevel>("Intermediate");
  const [format, setFormat] = useState("7v7");
  const [submitted, setSubmitted] = useState(false);

  if (submitted) {
    return (
      <div className="flex min-h-[70vh] flex-col items-center justify-center px-5 text-center">
        <div className="flex size-16 items-center justify-center rounded-full bg-primary glow-primary">
          <Check className="size-8 text-primary-foreground" strokeWidth={3} />
        </div>
        <h1 className="mt-5 font-display text-3xl font-black uppercase italic">
          Game Posted!
        </h1>
        <p className="mt-2 max-w-[30ch] text-sm text-muted-foreground">
          Players within range can now find and join your match. (Mock — saving comes later.)
        </p>
        <Link
          to="/"
          className="mt-6 rounded-xl bg-primary px-6 py-3 font-display text-lg font-black uppercase italic text-primary-foreground"
        >
          Back to Find
        </Link>
      </div>
    );
  }

  return (
    <div>
      <header className="sticky top-0 z-30 flex items-center gap-3 border-b border-border bg-background/90 px-5 py-4 backdrop-blur-md">
        <Link
          to="/"
          aria-label="Back"
          className="flex size-9 items-center justify-center rounded-full border border-border bg-card"
        >
          <ArrowLeft className="size-4" />
        </Link>
        <h1 className="font-display text-2xl font-black uppercase italic tracking-tight">
          Host a Game
        </h1>
      </header>

      <form
        className="space-y-5 px-5 py-6"
        onSubmit={(e) => {
          e.preventDefault();
          setSubmitted(true);
        }}
      >
        <Field label="Game Title">
          <input
            required
            placeholder="e.g. Friday Night 7v7"
            className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </Field>

        <Field label="Venue / Field">
          <input
            required
            placeholder="e.g. McCarren Park Turf"
            className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </Field>

        <div className="grid grid-cols-2 gap-3">
          <Field label="Date">
            <input
              type="date"
              required
              className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-ring [color-scheme:dark]"
            />
          </Field>
          <Field label="Kickoff Time">
            <input
              type="time"
              required
              className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-ring [color-scheme:dark]"
            />
          </Field>
        </div>

        <Field label="Format">
          <div className="flex flex-wrap gap-2">
            {formats.map((f) => (
              <button
                key={f}
                type="button"
                onClick={() => setFormat(f)}
                className={`rounded-xl px-4 py-2 font-display text-sm font-black italic transition-colors ${
                  format === f
                    ? "bg-primary text-primary-foreground"
                    : "border border-border bg-card text-muted-foreground"
                }`}
              >
                {f}
              </button>
            ))}
          </div>
        </Field>

        <Field label="Skill Level">
          <div className="flex flex-wrap gap-2">
            {skills.map((s) => (
              <button
                key={s}
                type="button"
                onClick={() => setSkill(s)}
                className={`rounded-xl px-4 py-2 font-display text-sm font-black italic transition-colors ${
                  skill === s
                    ? "bg-primary text-primary-foreground"
                    : "border border-border bg-card text-muted-foreground"
                }`}
              >
                {s}
              </button>
            ))}
          </div>
        </Field>

        <Field label="Max Players">
          <input
            type="number"
            min={4}
            max={30}
            defaultValue={14}
            className="w-full rounded-xl border border-input bg-card px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </Field>


        <Field label="Notes for Players">
          <textarea
            rows={3}
            placeholder="Shirts, shoes, rules, parking..."
            className="w-full resize-none rounded-xl border border-input bg-card px-4 py-3 text-sm placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring"
          />
        </Field>

        <button
          type="submit"
          className="w-full rounded-xl bg-primary py-4 font-display text-xl font-black uppercase italic text-primary-foreground glow-primary transition-transform active:scale-95"
        >
          Post Game
        </button>
      </form>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-2 block text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
        {label}
      </span>
      {children}
    </label>
  );
}
