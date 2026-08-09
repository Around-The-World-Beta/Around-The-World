import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

export type Lang = "system" | "en" | "es";

const STRINGS = {
  en: {
    brand: "Around the World",
    tagline: "Find. Play. Connect.",
    hero: "Soccer. Anyone. Anywhere.",
    subtitle: "Pickup games across every Bay Area county. Free to play. Open to everyone.",
    matches: "Matches",
    map: "Map",
    host: "Host",
    myGames: "My Games",
    profile: "Profile",
    settings: "Settings",
    free: "Free sessions",
    paid: "Paid sessions",
    loading: "Loading Bay Area games…",
    emptyTitle: "No open games nearby",
    emptyBody: "Open spots across the nine Bay Area counties show up here. Host a session or pull to refresh.",
    retry: "Try again",
    error: "Something broke",
    spots: "spots left",
    full: "Full",
    counties: "Nine counties",
    language: "Language",
    langSystem: "Device default",
    langEn: "English",
    langEs: "Spanish",
    mapEmpty: "No open sessions on the map yet.",
    hostHint: "Search a Bay Area venue, then drop a pin. Publish wires up after sign-in.",
    searchPlaceholder: "Search venues in the Bay Area…",
    basedIn: "Bay Area beta — SF, Peninsula, East Bay, South Bay, North Bay",
  },
  es: {
    brand: "Around the World",
    tagline: "Find. Play. Connect.",
    hero: "Fútbol. Para todos. En cualquier lugar.",
    subtitle: "Partidos en todos los condados del Área de la Bahía. Gratis. Abierto a todos.",
    matches: "Partidos",
    map: "Mapa",
    host: "Organizar",
    myGames: "Mis juegos",
    profile: "Perfil",
    settings: "Ajustes",
    free: "Sesiones gratis",
    paid: "Sesiones de pago",
    loading: "Cargando juegos del Área de la Bahía…",
    emptyTitle: "No hay juegos abiertos cerca",
    emptyBody: "Los cupos abiertos en los nueve condados aparecen aquí. Organiza una sesión o actualiza.",
    retry: "Reintentar",
    error: "Algo falló",
    spots: "cupos",
    full: "Lleno",
    counties: "Nueve condados",
    language: "Idioma",
    langSystem: "Predeterminado del dispositivo",
    langEn: "Inglés",
    langEs: "Español",
    mapEmpty: "Aún no hay sesiones abiertas en el mapa.",
    hostHint: "Busca una sede del Área de la Bahía y coloca un pin. Publicar requiere iniciar sesión.",
    searchPlaceholder: "Buscar sedes en el Área de la Bahía…",
    basedIn: "Beta Área de la Bahía — SF, Península, East Bay, South Bay, North Bay",
  },
} as const;

type Key = keyof (typeof STRINGS)["en"];

type I18nValue = {
  lang: Lang;
  setLang: (l: Lang) => void;
  locale: string;
  t: (key: Key) => string;
};

const Ctx = createContext<I18nValue | null>(null);
const STORAGE_KEY = "atw.language.preference";

function resolveLocale(lang: Lang): "en" | "es" {
  if (lang === "en" || lang === "es") return lang;
  return typeof navigator !== "undefined" && navigator.language.startsWith("es") ? "es" : "en";
}

export function I18nProvider({ children }: { children: ReactNode }) {
  const [lang, setLangState] = useState<Lang>(() => {
    const raw = localStorage.getItem(STORAGE_KEY) as Lang | null;
    return raw ?? "system";
  });

  const setLang = useCallback((l: Lang) => {
    setLangState(l);
    localStorage.setItem(STORAGE_KEY, l);
  }, []);

  const locale = resolveLocale(lang);
  const t = useCallback((key: Key) => STRINGS[locale][key], [locale]);

  const value = useMemo(() => ({ lang, setLang, locale, t }), [lang, setLang, locale, t]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useI18n() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useI18n outside provider");
  return ctx;
}
