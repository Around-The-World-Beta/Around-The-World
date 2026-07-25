import { Link } from "@tanstack/react-router";
import { Bell } from "lucide-react";
import avatar from "@/assets/avatar.jpg";
import { useAuth } from "@/lib/auth/AuthProvider";

export function HeaderActions() {
  const { user, profile } = useAuth();

  return (
    <div className="flex items-center gap-2">
      <button
        aria-label="Notifications"
        className="relative flex size-10 items-center justify-center rounded-full border border-border bg-card"
      >
        <Bell className="size-5" strokeWidth={2} absoluteStrokeWidth />
        <span className="absolute right-1.5 top-1.5 size-2 rounded-full bg-primary ring-2 ring-card" />
      </button>
      {user ? (
        <Link to="/profile" aria-label="Open profile" className="shrink-0">
          <img
            src={profile?.avatar_url || avatar}
            alt={profile?.display_name || "Your profile"}
            width={512}
            height={512}
            className="size-10 rounded-full border border-border object-cover"
          />
        </Link>
      ) : (
        <Link
          to="/auth"
          search={{ mode: "login", next: undefined, message: undefined }}
          className="rounded-full bg-primary px-4 py-2 text-xs font-bold uppercase text-primary-foreground"
        >
          Sign in
        </Link>
      )}
    </div>
  );
}
