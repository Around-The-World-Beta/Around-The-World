export type Game = {
  id: string;
  hostUserId: string;
  title: string;
  venue: string;
  neighborhood: string;
  skill: string;
  format: string;
  capacity: number;
  joinedCount: number;
  priceCents: number;
  notes: string;
  startsAt: string;
  latitude: number;
  longitude: number;
  status: string;
  imageUrl?: string | null;
};

export type BayAreaMeta = {
  region: string;
  counties: string[];
  citiesByCounty: Record<string, string[]>;
  bounds: {
    minLatitude: number;
    maxLatitude: number;
    minLongitude: number;
    maxLongitude: number;
  };
};

const base = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.replace(/\/$/, "") ?? "";

async function get<T>(path: string): Promise<T> {
  const res = await fetch(`${base}${path}`, {
    headers: { Accept: "application/json" },
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `HTTP ${res.status}`);
  }
  return res.json() as Promise<T>;
}

export const api = {
  health: () => get<{ status: string; service: string }>("/health"),
  listGames: (includeFull = false) =>
    get<Game[]>(`/api/v1/games?includeFull=${includeFull}&region=bay-area`),
  listMyGames: (userId: string) =>
    get<Game[]>(`/api/v1/games/mine?userId=${encodeURIComponent(userId)}`),
  getGame: (id: string) => get<Game>(`/api/v1/games/${id}`),
  bayAreaMeta: () => get<BayAreaMeta>("/api/v1/meta/bay-area"),
};

export function spotsLeft(game: Game): number {
  return Math.max(game.capacity - game.joinedCount, 0);
}

export function isFull(game: Game): boolean {
  return game.joinedCount >= game.capacity;
}

export function priceLabel(game: Game): string {
  if (game.priceCents <= 0) return "Free";
  return `$${(game.priceCents / 100).toFixed(game.priceCents % 100 === 0 ? 0 : 2)}/player`;
}

export function kickoffLabel(iso: string, locale = "en"): string {
  return new Intl.DateTimeFormat(locale, {
    weekday: "short",
    hour: "numeric",
    minute: "2-digit",
  }).format(new Date(iso));
}
