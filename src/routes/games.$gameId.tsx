import {
  createFileRoute,
  Link,
  notFound,
  useNavigate,
} from "@tanstack/react-router";
import { ArrowLeft, MapPin, Clock, Users, DollarSign } from "lucide-react";
import { useState } from "react";
import { mockGames } from "@/lib/mock-data";
import { useAuth } from "@/lib/auth/AuthProvider";

export const Route = createFileRoute("/games/$gameId")({
  loader: ({ params }) => {
    const game = mockGames.find((g) => g.id === params.gameId);
    if (!game) throw notFound();
    return { game };
  },
  head: ({ loaderData }) => {
    if (!loaderData) {
      return {
        meta: [{ title: "Game not found — KickUp" }, { name: "robots", content: "noindex" }],
      };
    }
    return {
      meta: [
        { title: `${loaderData.game.title} — KickUp` },
        {
          name: "description",
          content: `${loaderData.game.format} pickup soccer at ${loaderData.game.venue}, ${loaderData.game.dateLabel} ${loaderData.game.timeLabel}.`,
        },
      ],
    };
  },
  notFoundComponent: GameNotFound,
  errorComponent: GameError,
  component: GameDetailPage,
});

function GameNotFound() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center px-5 text-center">
      <h1 className="font-display text-3xl font-black uppercase italic">Game not found</h1>
      <p className="mt-2 text-sm text-muted-foreground">
        This match may have been cancelled or removed.
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

function GameError() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center px-5 text-center">
      <h1 className="font-display text-3xl font-black uppercase italic">Something broke</h1>
      <Link
        to="/"
        className="mt-6 rounded-xl bg-primary px-6 py-3 font-display text-lg font-black uppercase italic text-primary-foreground"
      >
        Back to Find
      </Link>
    </div>
  );
}

function GameDetailPage() {
  const { game } = Route.useLoaderData();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [joined, setJoined] = useState(false);
  const isFull = game.joined >= game.capacity;
  const spotsLeft = game.capacity - game.joined;

  return (
    <div>
      <div className="relative">
        {game.image ? (
          <img
            src={game.image}
            alt={game.venue}
            width={800}
            height={512}
            className="aspect-[16/10] w-full object-cover"
          />
        ) : (
          <div className="flex aspect-[16/10] w-full items-center justify-center bg-card">
            <span className="text-[10px] uppercase tracking-widest text-muted-foreground">
              {game.venue}
            </span>
          </div>
        )}
        <Link
          to="/"
          aria-label="Back"
          className="absolute left-4 top-4 flex size-10 items-center justify-center rounded-full border border-border bg-background/80 backdrop-blur-sm"
        >
          <ArrowLeft className="size-5" />
        </Link>
        <div className="absolute bottom-3 left-4 rounded border border-border bg-background/80 px-2 py-1 text-[10px] font-bold uppercase tracking-tight backdrop-blur-sm">
          {game.startsIn ?? `${game.dateLabel} • ${game.timeLabel}`}
        </div>
      </div>

      <div className="px-5 py-5">
        <div className="mb-1 flex items-center gap-2">
          <span className="rounded border border-border bg-secondary px-2 py-0.5 text-[10px] font-bold uppercase">
            {game.skill}
          </span>
          <span className="rounded border border-border bg-secondary px-2 py-0.5 text-[10px] font-bold uppercase">
            {game.format}
          </span>
        </div>
        <h1 className="font-display text-3xl font-black uppercase italic leading-tight">
          {game.title}
        </h1>
        <p className="text-sm text-muted-foreground">Hosted by {game.host}</p>

        <div className="mt-5 grid grid-cols-2 gap-3">
          <InfoTile icon={<MapPin className="size-4" strokeWidth={2} absoluteStrokeWidth />} label="Venue" value={game.venue} />
          <InfoTile
            icon={<Clock className="size-4" strokeWidth={2} absoluteStrokeWidth />}
            label="Kickoff"
            value={`${game.dateLabel} ${game.timeLabel}`}
          />
          <InfoTile
            icon={<Users className="size-4" strokeWidth={2} absoluteStrokeWidth />}
            label="Players"
            value={`${game.joined + (joined ? 1 : 0)}/${game.capacity} joined`}
          />
          <InfoTile
            icon={<DollarSign className="size-4" strokeWidth={2} absoluteStrokeWidth />}
            label="Cost"
            value={game.pricePerPlayer === 0 ? "Free" : `$${game.pricePerPlayer} per player`}
          />


        </div>

        <div className="mt-5 rounded-2xl border border-border bg-card p-4">
          <h2 className="mb-1 font-display text-sm font-black uppercase italic tracking-wide text-primary">
            Host Notes
          </h2>
          <p className="text-sm leading-relaxed text-card-foreground">{game.notes}</p>
        </div>

        <p className="mt-4 text-center text-xs text-muted-foreground">
          {game.distanceMiles} miles from you • {game.neighborhood}
        </p>

        <div className="mt-4">
          {isFull ? (
            <button className="w-full rounded-xl border border-border py-4 font-display text-xl font-black uppercase italic text-muted-foreground">
              Join Waitlist
            </button>
          ) : joined ? (
            <button
              onClick={() => setJoined(false)}
              className="w-full rounded-xl border border-primary py-4 font-display text-xl font-black uppercase italic text-primary"
            >
              You're In ✓ — Tap to Leave
            </button>
          ) : (
            <button
              onClick={() => {
                if (!user) {
                  navigate({
                    to: "/auth",
                    search: {
                      mode: "login",
                      next: `/games/${game.id}`,
                      message: "Sign in to join this game.",
                    },
                  });
                  return;
                }
                setJoined(true);
              }}
              className="w-full rounded-xl bg-primary py-4 font-display text-xl font-black uppercase italic text-primary-foreground glow-primary transition-transform active:scale-95"
            >
              Claim Spot • {spotsLeft} Left
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

function InfoTile({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
}) {
  return (
    <div className="rounded-xl border border-border bg-card p-3">
      <div className="mb-1 flex items-center gap-1.5 text-muted-foreground">
        {icon}
        <span className="text-[10px] font-bold uppercase">{label}</span>
      </div>
      <p className="text-sm font-medium">{value}</p>
    </div>
  );
}
