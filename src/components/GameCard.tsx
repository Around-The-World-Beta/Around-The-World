import { Link } from "@tanstack/react-router";
import { friendsForGame, type PickupGame } from "@/lib/mock-data";
import { FriendAvatar } from "@/components/FriendAvatar";


export function GameCard({ game }: { game: PickupGame }) {
  const isFull = game.joined >= game.capacity;
  const friendsGoing = friendsForGame(game.id);


  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card">
      {game.image && (
        <div className="relative">
          <img
            src={game.image}
            alt={game.venue}
            width={800}
            height={512}
            loading="lazy"
            className="aspect-[2/1] w-full object-cover opacity-90"
          />
          <div className="absolute left-3 top-3 rounded border border-border bg-background/80 px-2 py-1 text-[10px] font-bold uppercase tracking-tight backdrop-blur-sm">
            {game.startsIn ?? `${game.dateLabel} ${game.timeLabel}`}
          </div>
        </div>
      )}
      <div className="p-4">
        <div className="mb-2 flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h3 className="font-display text-lg font-black uppercase italic leading-none">
              {game.title}
            </h3>
            <p className="mt-1 text-xs text-muted-foreground">
              {game.neighborhood} • {game.distanceMiles} miles away
            </p>
          </div>
          <div className="shrink-0 text-right">
            <div
              className={`font-display text-lg font-bold leading-none ${
                isFull ? "text-muted-foreground" : "text-primary"
              }`}
            >
              {game.joined}/{game.capacity}
            </div>
            <div className="text-[10px] font-bold uppercase text-muted-foreground">
              {isFull ? "Full" : "Players"}
            </div>
          </div>
        </div>
        <div className="mb-3 flex items-center gap-2">
          <span className="rounded border border-border bg-secondary px-2 py-0.5 text-[10px] font-bold uppercase text-secondary-foreground">
            {game.skill}
          </span>
          <span className="rounded border border-border bg-secondary px-2 py-0.5 text-[10px] font-bold uppercase text-secondary-foreground">
            {game.format}
          </span>
          <span className="text-[10px] font-bold uppercase text-muted-foreground">
            {game.pricePerPlayer === 0 ? "Free" : `$${game.pricePerPlayer}/player`}
          </span>
        </div>
        {friendsGoing.length > 0 && (
          <div className="mb-3 flex items-center gap-2 rounded-lg border border-border bg-muted/50 px-2 py-1.5">
            <div className="flex -space-x-1.5">
              {friendsGoing.slice(0, 3).map((f) => (
                <FriendAvatar key={f.id} seed={f.avatarSeed} size={22} title={f.name} />
              ))}
            </div>
            <span className="text-[11px] font-semibold text-foreground">
              {friendsGoing.length === 1
                ? `${friendsGoing[0].name.split(" ")[0]} is going`
                : `${friendsGoing[0].name.split(" ")[0]} +${friendsGoing.length - 1} going`}
            </span>
          </div>
        )}
        {isFull ? (
          <Link
            to="/games/$gameId"
            params={{ gameId: game.id }}
            className="block w-full rounded-xl border border-border py-3 text-center font-display text-lg font-black uppercase italic text-muted-foreground"
          >
            Join Waitlist
          </Link>
        ) : (
          <div className="flex gap-2">
            <Link
              to="/games/$gameId"
              params={{ gameId: game.id }}
              className="flex-1 rounded-xl bg-primary py-3 text-center font-display text-lg font-black uppercase italic text-primary-foreground transition-transform active:scale-95"
            >
              Join Match
            </Link>
            <Link
              to="/games/$gameId"
              params={{ gameId: game.id }}
              className="flex items-center rounded-xl border border-border bg-secondary px-4 font-display text-sm font-bold uppercase italic text-secondary-foreground"
            >
              Details
            </Link>
          </div>
        )}
      </div>
    </div>
  );
}
