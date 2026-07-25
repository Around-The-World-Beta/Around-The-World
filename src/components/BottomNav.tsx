import { Link, useRouterState } from "@tanstack/react-router";
import { Trophy, CalendarDays, Plus, Users } from "lucide-react";
import { useAuth } from "@/lib/auth/AuthProvider";

const tabs = [
  { to: "/", label: "Matches", icon: Trophy },
  { to: "/my-games", label: "My Games", icon: CalendarDays },
  { to: "/friends", label: "Friends", icon: Users },
] as const;

export function BottomNav() {
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const { user } = useAuth();
  const authSurface =
    pathname.startsWith("/auth") || pathname.startsWith("/account");
  const showFab = Boolean(user) && !pathname.startsWith("/host") && !authSurface;

  if (authSurface) return null;

  return (
    <>
      {showFab && (
        <Link
          to="/host"
          aria-label="Host a game"
          className="fixed bottom-24 right-5 z-50 flex size-14 items-center justify-center rounded-full bg-primary text-primary-foreground glow-primary transition-transform active:scale-90"
        >
          <Plus className="size-7" strokeWidth={2.75} absoluteStrokeWidth />
        </Link>
      )}
      <nav className="fixed inset-x-0 bottom-0 z-50 border-t border-border bg-card/95 backdrop-blur-xl">
        <div className="mx-auto flex h-20 max-w-md items-center justify-between px-8 pb-3">
          {tabs.map((tab) => {
            const active =
              tab.to === "/" ? pathname === "/" : pathname.startsWith(tab.to);
            return (
              <Link
                key={tab.to}
                to={tab.to}
                className={`flex flex-col items-center gap-1 ${
                  active ? "text-primary" : "text-muted-foreground"
                }`}
              >
                <tab.icon
                  className="size-6"
                  strokeWidth={active ? 2.5 : 2}
                  absoluteStrokeWidth
                />
                <span className="font-display text-[10px] font-bold uppercase tracking-tight">
                  {tab.label}
                </span>
              </Link>
            );
          })}
        </div>
      </nav>
    </>
  );
}
