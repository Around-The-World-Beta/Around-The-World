import { createFileRoute, Link } from "@tanstack/react-router";
import { useMemo, useState } from "react";
import { Search, UserPlus, UserCheck, Calendar } from "lucide-react";
import { mockFriends, mockGames, type Friend } from "@/lib/mock-data";
import { FriendAvatar } from "@/components/FriendAvatar";
import { HeaderActions } from "@/components/HeaderActions";
import { requireAuthenticatedUser } from "@/lib/auth/auth.functions";


export const Route = createFileRoute("/friends")({
  beforeLoad: () =>
    requireAuthenticatedUser({ data: { returnTo: "/friends" } }),
  head: () => ({
    meta: [
      { title: "Friends — Around The World" },
      { name: "description", content: "Follow players and see which pickup games they're playing." },
    ],
  }),
  component: FriendsPage,
});

type Tab = "following" | "followers";

const TABS: { key: Tab; label: string }[] = [
  { key: "following", label: "Following" },
  { key: "followers", label: "Followers" },
];

function FriendsPage() {
  const [tab, setTab] = useState<Tab>("following");
  const [friends, setFriends] = useState<Friend[]>(mockFriends);
  const [query, setQuery] = useState("");

  const toggleFollow = (id: string) => {
    setFriends((prev) =>
      prev.map((f) => (f.id === id ? { ...f, following: !f.following } : f)),
    );
  };

  const filter = (list: Friend[]) =>
    query.trim()
      ? list.filter(
          (f) =>
            f.name.toLowerCase().includes(query.toLowerCase()) ||
            f.handle.toLowerCase().includes(query.toLowerCase()),
        )
      : list;

  const following = useMemo(() => filter(friends.filter((f) => f.following)), [friends, query]);
  const followers = useMemo(() => filter(friends.filter((f) => f.followsYou)), [friends, query]);

  const activity = useMemo(() => {
    const items: { friend: Friend; gameId: string }[] = [];
    friends
      .filter((f) => f.following)
      .forEach((f) => f.rsvpedGameIds.forEach((gid) => items.push({ friend: f, gameId: gid })));
    return items;
  }, [friends]);

  const list = tab === "following" ? following : followers;

  return (
    <div className="pb-24">
      <header className="sticky top-0 z-30 border-b border-border bg-background/90 px-5 py-4 backdrop-blur-md">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h1 className="font-display text-2xl font-black uppercase italic tracking-tight">
              Friends
            </h1>
            <p className="text-xs text-muted-foreground">
              Follow players and see who's playing near you.
            </p>
          </div>
          <HeaderActions />
        </div>

        <div className="mt-3 flex items-center gap-2 rounded-full border border-border bg-card px-3 py-2">
          <Search className="size-4 text-muted-foreground" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search players"
            className="flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          />
        </div>
        <div className="mt-3 flex gap-2">
          {TABS.map((t) => {
            const active = tab === t.key;
            return (
              <button
                key={t.key}
                onClick={() => setTab(t.key)}
                className={`flex-1 rounded-full border px-3 py-1.5 text-xs font-semibold ${
                  active
                    ? "border-primary bg-primary text-primary-foreground"
                    : "border-border bg-card text-foreground"
                }`}
              >
                {t.label}
              </button>
            );
          })}
        </div>
      </header>

      {/* Nearby games from friends you follow */}
      {tab === "following" && activity.length > 0 && (
        <section className="border-b border-border px-5 py-4">
          <h2 className="mb-2 font-display text-sm font-bold uppercase tracking-widest text-muted-foreground">
            Friends Playing Nearby
          </h2>
          <div className="space-y-2">
            {activity.slice(0, 4).map(({ friend, gameId }) => {
              const g = mockGames.find((x) => x.id === gameId);
              if (!g) return null;
              return (
                <Link
                  key={`${friend.id}-${gameId}`}
                  to="/games/$gameId"
                  params={{ gameId: g.id }}
                  className="flex items-center gap-3 rounded-2xl border border-border bg-card p-3"
                >
                  <FriendAvatar seed={friend.avatarSeed} size={40} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm">
                      <span className="font-bold">{friend.name}</span>{" "}
                      <span className="text-muted-foreground">is going to</span>
                    </p>
                    <p className="truncate font-display text-sm font-bold uppercase">
                      {g.title}
                    </p>
                    <p className="mt-0.5 flex items-center gap-1 text-[11px] text-muted-foreground">
                      <Calendar className="size-3" />
                      {g.dateLabel} · {g.timeLabel} · {g.venue}
                    </p>
                  </div>
                </Link>
              );
            })}
          </div>
        </section>
      )}

      <div className="px-5 py-4">
        <div className="space-y-2">
          {list.length === 0 && <Empty label={`No ${tab} yet`} />}
          {list.map((f) => (
            <div
              key={f.id}
              className="flex items-center gap-3 rounded-2xl border border-border bg-card p-3"
            >
              <FriendAvatar seed={f.avatarSeed} size={44} />
              <div className="min-w-0 flex-1">
                <p className="truncate font-bold">{f.name}</p>
                <p className="truncate text-xs text-muted-foreground">
                  {f.handle} · {f.mutuals} mutuals
                </p>
              </div>
              <button
                onClick={() => toggleFollow(f.id)}
                className={`flex items-center gap-1 rounded-full px-3 py-1.5 text-xs font-bold ${
                  f.following
                    ? "border border-border bg-background text-foreground"
                    : "bg-primary text-primary-foreground"
                }`}
              >
                {f.following ? (
                  <>
                    <UserCheck className="size-3.5" /> Following
                  </>
                ) : (
                  <>
                    <UserPlus className="size-3.5" /> Follow
                  </>
                )}
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function Empty({ label }: { label: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-card p-6 text-center text-sm text-muted-foreground">
      {label}
    </div>
  );
}
