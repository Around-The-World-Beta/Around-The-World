interface FriendAvatarProps {
  seed: string;
  size?: number;
  className?: string;
  title?: string;
}

// Small deterministic circular avatar based on the seed's initial.
export function FriendAvatar({ seed, size = 24, className = "", title }: FriendAvatarProps) {
  const initial = seed.trim().charAt(0).toUpperCase() || "?";
  const palette = [
    "bg-primary text-primary-foreground",
    "bg-secondary text-secondary-foreground",
    "bg-foreground text-background",
  ];
  const hash = seed.split("").reduce((a, c) => a + c.charCodeAt(0), 0);
  const swatch = palette[hash % palette.length];
  return (
    <span
      title={title ?? seed}
      style={{ width: size, height: size, fontSize: size * 0.42 }}
      className={`inline-flex shrink-0 items-center justify-center rounded-full border-2 border-background font-display font-bold ${swatch} ${className}`}
    >
      {initial}
    </span>
  );
}
