import { createFileRoute, Link } from "@tanstack/react-router";
import { mockGames } from "@/lib/mock-data";
import { HeaderActions } from "@/components/HeaderActions";
import { requireAuthenticatedUser } from "@/lib/auth/auth.functions";


export const Route = createFileRoute("/my-games")({
  beforeLoad: () =>
    requireAuthenticatedUser({ data: { returnTo: "/my-games" } }),
  head: () => ({
    meta: [
      { title: "My Games — KickUp" },
      { name: "description", content: "Your upcoming and hosted pickup games." },
    ],
  }),
  component: MyGamesPage,
});

const upcoming = [mockGames[0], mockGames[3]];
const hosting = [mockGames[4]];

function MyGamesPage() {
  return (
    <div>
      <header className="border-b border-border px-5 py-4">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h1 className="font-display text-2xl font-black uppercase italic tracking-tight">
              My Games
            </h1>
            <p className="text-xs text-muted-foreground">Matches you've joined or are hosting</p>
          </div>
          <HeaderActions />
        </div>
      </header>


      <section className="px-5 py-6">
        <h2 className="mb-3 text-[10px] font-bold uppercase tracking-widest text-primary">
          Joined • {upcoming.length}
        </h2>
        <div className="space-y-3">
          {upcoming.map((game) => (
            <Link
              key={game.id}
              to="/games/$gameId"
              params={{ gameId: game.id }}
              className="flex items-center justify-between rounded-2xl border border-border bg-card p-4"
            >
              <div className="min-w-0">
                <h3 className="truncate font-display text-lg font-black uppercase italic leading-none">
                  {game.title}
                </h3>
                <p className="mt-1 text-xs text-muted-foreground">
                  {game.dateLabel} {game.timeLabel} • {game.venue}
                </p>
              </div>
              <span className="ml-3 shrink-0 font-display text-lg font-bold italic text-primary">
                {game.joined}/{game.capacity}
              </span>
            </Link>
          ))}
        </div>
      </section>

      <section className="px-5">
        <h2 className="mb-3 text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
          Hosting • {hosting.length}
        </h2>
        <div className="space-y-3">
          {hosting.map((game) => (
            <Link
              key={game.id}
              to="/games/$gameId"
              params={{ gameId: game.id }}
              className="flex items-center justify-between rounded-2xl border border-primary/30 bg-card p-4"
            >
              <div className="min-w-0">
                <span className="text-[10px] font-bold uppercase text-primary">Your game</span>
                <h3 className="truncate font-display text-lg font-black uppercase italic leading-none">
                  {game.title}
                </h3>
                <p className="mt-1 text-xs text-muted-foreground">
                  {game.dateLabel} {game.timeLabel} • {game.venue}
                </p>
              </div>
              <span className="ml-3 shrink-0 font-display text-lg font-bold italic text-primary">
                {game.joined}/{game.capacity}
              </span>
            </Link>
          ))}
        </div>
        <Link
          to="/host"
          className="mt-4 block rounded-2xl border border-dashed border-border py-4 text-center font-display text-lg font-black uppercase italic text-muted-foreground"
        >
          + Host Another Game
        </Link>
      </section>
    </div>
  );
}
