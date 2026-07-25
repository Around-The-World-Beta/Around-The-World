import { createFileRoute, Link } from "@tanstack/react-router";
import { useEffect, useMemo, useRef, useState } from "react";

import {
  SlidersHorizontal,
  X,
  List,
  Map as MapIcon,
  ArrowUpDown,
  MapPin,
  Locate,
} from "lucide-react";

import { GameCard } from "@/components/GameCard";
import { HeaderActions } from "@/components/HeaderActions";
import { mockGames, type SkillLevel } from "@/lib/mock-data";



export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Matches — KickUp" },
      {
        name: "description",
        content: "Find soccer pickup games near you — browse a list or map view.",
      },
    ],
  }),
  component: MatchesPage,
});

type TimeOfDay = "Morning" | "Afternoon" | "Evening" | "Late night";
type Difficulty = "Casual" | "Intermediate" | "Baller" | "Open to All";
type ViewMode = "list" | "map";
type SortKey = "time" | "price" | "distance" | "difficulty";

const TIME_OPTIONS: { key: TimeOfDay; label: string; range: string }[] = [
  { key: "Morning", label: "Morning", range: "7am - 12pm" },
  { key: "Afternoon", label: "Afternoon", range: "12pm - 5pm" },
  { key: "Evening", label: "Evening", range: "5pm - 10pm" },
  { key: "Late night", label: "Late night", range: "10pm - 2am" },
];
const DIFFICULTY_OPTIONS: Difficulty[] = [
  "Casual",
  "Intermediate",
  "Baller",
  "Open to All",
];
const SORT_OPTIONS: { key: SortKey; label: string }[] = [
  { key: "time", label: "Time" },
  { key: "price", label: "Price" },
  { key: "distance", label: "Distance" },
  { key: "difficulty", label: "Difficulty" },
];

const skillToDifficulty: Record<SkillLevel, Difficulty> = {
  Casual: "Casual",
  Intermediate: "Intermediate",
  Baller: "Baller",
  "Open to All": "Open to All",
};
const difficultyRank: Record<Difficulty, number> = {
  Casual: 0,
  Intermediate: 1,
  Baller: 2,
  "Open to All": 3,
};

function to24h(timeLabel: string): number {
  const [hhStr, rest] = timeLabel.split(":");
  const meridiem = rest?.slice(-2).toUpperCase();
  let hh = Number(hhStr);
  const mm = Number(rest?.slice(0, 2)) || 0;
  if (meridiem === "PM" && hh !== 12) hh += 12;
  if (meridiem === "AM" && hh === 12) hh = 0;
  return hh * 60 + mm;
}
function bucketTime(timeLabel: string): TimeOfDay {
  const m = to24h(timeLabel);
  if (m >= 22 * 60 || m < 2 * 60) return "Late night";
  if (m < 12 * 60) return "Morning";
  if (m < 17 * 60) return "Afternoon";
  return "Evening";
}

// Build 7 rotating dates starting today
function buildWeek() {
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  const months = [
    "Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec",
  ];
  const out: { key: string; day: string; date: number; month: string; label: string }[] = [];
  const now = new Date();
  for (let i = 0; i < 7; i++) {
    const d = new Date(now);
    d.setDate(now.getDate() + i);
    const day = days[d.getDay()];
    const date = d.getDate();
    const month = months[d.getMonth()];
    const label =
      i === 0 ? "Today" : i === 1 ? "Tomorrow" : day;
    out.push({ key: `${month}-${date}`, day, date, month, label });
  }
  return out;
}

// Map mock game.dateLabel onto one of the 7 week slots (best-effort)
function matchesSelectedDate(
  gameDateLabel: string,
  selected: ReturnType<typeof buildWeek>[number],
  index: number,
) {
  if (index === 0 && gameDateLabel === "Today") return true;
  if (index === 1 && gameDateLabel === "Tomorrow") return true;
  return gameDateLabel === selected.day;
}

// Map view positions
const localPositions = [
  { top: "22%", left: "58%" },
  { top: "38%", left: "30%" },
  { top: "62%", left: "68%" },
  { top: "50%", left: "48%" },
  { top: "30%", left: "78%" },
  { top: "72%", left: "35%" },
];
const usCityDots = [
  { top: "38%", left: "18%", label: "SF" },
  { top: "58%", left: "22%", label: "LA" },
  { top: "72%", left: "45%", label: "HOU" },
  { top: "58%", left: "52%", label: "DAL" },
  { top: "32%", left: "58%", label: "CHI" },
  { top: "70%", left: "72%", label: "MIA" },
  { top: "34%", left: "82%", label: "NYC" },
  { top: "44%", left: "78%", label: "DC" },
  { top: "60%", left: "68%", label: "ATL" },
];

function MatchesPage() {
  const week = useMemo(buildWeek, []);
  const [selectedDay, setSelectedDay] = useState(0);
  const [view, setView] = useState<ViewMode>("list");
  const [radius, setRadius] = useState(10);
  const [times, setTimes] = useState<Set<TimeOfDay>>(new Set());
  const [diffs, setDiffs] = useState<Set<Difficulty>>(new Set());
  const [showFilters, setShowFilters] = useState(false);
  const [filterMounted, setFilterMounted] = useState(false);
  const [filterVisible, setFilterVisible] = useState(false);
  const [dragY, setDragY] = useState(0);
  const [dragging, setDragging] = useState(false);
  const dragStartRef = useRef<number | null>(null);
  const scrollRef = useRef<HTMLDivElement | null>(null);
  const [sort, setSort] = useState<SortKey>("time");
  const [showSort, setShowSort] = useState(false);

  // Open/close animation choreography
  useEffect(() => {
    if (showFilters) {
      setFilterMounted(true);
      setDragY(0);
      // next frame — trigger slide-up
      requestAnimationFrame(() => requestAnimationFrame(() => setFilterVisible(true)));
    } else if (filterMounted) {
      setFilterVisible(false);
    }
  }, [showFilters]);


  const [locationOn, setLocationOn] = useState(false);
  const [locating, setLocating] = useState(false);
  const [selectedGameId, setSelectedGameId] = useState(mockGames[0].id);

  const filtered = useMemo(() => {
    const day = week[selectedDay];
    const arr = mockGames.filter((g) => {
      if (!matchesSelectedDate(g.dateLabel, day, selectedDay)) return false;
      if (g.distanceMiles > radius) return false;
      if (times.size && !times.has(bucketTime(g.timeLabel))) return false;
      if (
        diffs.size &&
        !diffs.has("Open to All") &&
        !diffs.has(skillToDifficulty[g.skill])
      )
        return false;
      return true;
    });
    arr.sort((a, b) => {
      switch (sort) {
        case "price":
          return a.pricePerPlayer - b.pricePerPlayer;
        case "distance":
          return a.distanceMiles - b.distanceMiles;
        case "difficulty":
          return (
            difficultyRank[skillToDifficulty[a.skill]] -
            difficultyRank[skillToDifficulty[b.skill]]
          );
        case "time":
        default:
          return to24h(a.timeLabel) - to24h(b.timeLabel);
      }
    });
    return arr;
  }, [week, selectedDay, radius, times, diffs, sort]);

  const free = filtered.filter((g) => g.pricePerPlayer === 0);
  const paid = filtered.filter((g) => g.pricePerPlayer > 0);

  const activeCount = times.size + diffs.size + (radius !== 10 ? 1 : 0);

  const toggle = <T,>(set: Set<T>, val: T, setter: (s: Set<T>) => void) => {
    const next = new Set(set);
    next.has(val) ? next.delete(val) : next.add(val);
    setter(next);
  };
  const clearAll = () => {
    setTimes(new Set());
    setDiffs(new Set());
    setRadius(10);
  };

  const enableLocation = () => {
    setLocating(true);
    if (typeof window !== "undefined" && "geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        () => {
          setLocationOn(true);
          setLocating(false);
        },
        () => {
          setLocationOn(true);
          setLocating(false);
        },
        { timeout: 5000 },
      );
    } else {
      setTimeout(() => {
        setLocationOn(true);
        setLocating(false);
      }, 400);
    }
  };

  const selectedGame =
    mockGames.find((g) => g.id === selectedGameId) ?? mockGames[0];

  return (
    <div>
      <header className="sticky top-0 z-30 border-b border-border bg-background/90 px-5 py-4 backdrop-blur-md">
        <div className="mb-3 flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h1 className="font-display text-2xl font-black uppercase italic tracking-tight">
              Matches
            </h1>
            <p className="text-xs text-muted-foreground">Choose pickup games to attend</p>
          </div>
          <HeaderActions />
        </div>





        {/* View toggle */}
        <div className="flex rounded-full border border-border bg-muted p-1">
          <button
            onClick={() => setView("list")}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-full py-1.5 text-xs font-bold uppercase tracking-tight transition-colors ${
              view === "list"
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground"
            }`}
          >
            <List className="size-3.5" /> List
          </button>
          <button
            onClick={() => setView("map")}
            className={`flex flex-1 items-center justify-center gap-1.5 rounded-full py-1.5 text-xs font-bold uppercase tracking-tight transition-colors ${
              view === "map"
                ? "bg-primary text-primary-foreground"
                : "text-muted-foreground"
            }`}
          >
            <MapIcon className="size-3.5" /> Map
          </button>
        </div>
      </header>

      {/* Date strip */}
      <div className="border-b border-border bg-background px-3 py-3">
        <div className="flex gap-2 overflow-x-auto">
          {week.map((d, i) => {
            const active = i === selectedDay;
            return (
              <button
                key={d.key}
                onClick={() => setSelectedDay(i)}
                className={`flex min-w-[56px] flex-col items-center rounded-xl border px-2 py-2 transition-colors ${
                  active
                    ? "border-primary bg-primary text-primary-foreground"
                    : "border-border bg-card text-foreground"
                }`}
              >
                <span className="text-[10px] font-bold uppercase tracking-widest">
                  {d.day}
                </span>
                <span className="font-display text-lg font-bold leading-none">
                  {d.date}
                </span>
                <span
                  className={`mt-1 text-[9px] font-semibold uppercase ${
                    active ? "opacity-90" : "text-muted-foreground"
                  }`}
                >
                  {i === 0 ? "Today" : d.month}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Filters & Sort bar (both list and map) */}
      <div className="flex items-center justify-between gap-2 border-b border-border px-5 py-3">
        <button
          onClick={() => {
            setShowFilters((v) => !v);
            setShowSort(false);
          }}
          className="relative flex items-center gap-1.5 rounded-full border border-border bg-card px-3 py-2 text-xs font-semibold"
        >
          <SlidersHorizontal className="size-4" />
          Filters
          {activeCount > 0 && (
            <span className="ml-1 flex size-5 items-center justify-center rounded-full bg-primary text-[10px] font-bold text-primary-foreground">
              {activeCount}
            </span>
          )}
        </button>
        <div className="relative">
          <button
            onClick={() => {
              setShowSort((v) => !v);
              setShowFilters(false);
            }}
            className="flex items-center gap-1.5 rounded-full border border-border bg-card px-3 py-2 text-xs font-semibold"
          >
            <ArrowUpDown className="size-4" />
            Sort:{" "}
            <span className="text-primary">
              {SORT_OPTIONS.find((s) => s.key === sort)?.label}
            </span>
          </button>
          {showSort && (
            <div className="absolute right-0 top-full z-20 mt-2 w-44 overflow-hidden rounded-xl border border-border bg-card shadow-lg">
              {SORT_OPTIONS.map((opt) => (
                <button
                  key={opt.key}
                  onClick={() => {
                    setSort(opt.key);
                    setShowSort(false);
                  }}
                  className={`block w-full px-3 py-2 text-left text-sm ${
                    sort === opt.key
                      ? "bg-primary/10 font-bold text-primary"
                      : "text-foreground"
                  }`}
                >
                  {opt.label}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {filterMounted && (
        <section
          className="fixed inset-0 z-40 flex flex-col bg-background will-change-transform"
          style={{
            transform: `translateY(${filterVisible ? dragY : (typeof window !== "undefined" ? window.innerHeight : 1000)}px)`,

            transition: dragging ? "none" : "transform 420ms cubic-bezier(0.22, 1, 0.36, 1)",
          }}
          onTransitionEnd={() => {
            if (!filterVisible) {
              setFilterMounted(false);
              setDragY(0);
            }
          }}
          onTouchStart={(e) => {
            const el = scrollRef.current;
            if (el && el.scrollTop <= 0) {
              dragStartRef.current = e.touches[0].clientY;
            } else {
              dragStartRef.current = null;
            }
          }}
          onTouchMove={(e) => {
            if (dragStartRef.current == null) return;
            const el = scrollRef.current;
            if (el && el.scrollTop > 0) {
              dragStartRef.current = null;
              setDragging(false);
              setDragY(0);
              return;
            }
            const dy = e.touches[0].clientY - dragStartRef.current;
            if (dy > 0) {
              if (!dragging) setDragging(true);
              setDragY(dy);
            } else if (dragging) {
              setDragY(0);
            }
          }}
          onTouchEnd={() => {
            if (dragStartRef.current == null) return;
            dragStartRef.current = null;
            setDragging(false);
            if (dragY > 120) {
              setShowFilters(false);
            } else {
              setDragY(0);
            }
          }}
          onWheel={(e) => {
            const el = scrollRef.current;
            if (el && el.scrollTop <= 0 && e.deltaY < -40) setShowFilters(false);
          }}
        >

          <div className="bg-card px-5 pt-3 pb-4">
            <div className="mx-auto mb-3 h-1.5 w-10 rounded-full bg-muted-foreground/30" />
            <button
              onClick={() => setShowFilters(false)}
              aria-label="Close filters"
              className="mb-6 -ml-1 rounded-full p-1"
            >
              <X className="size-6" />
            </button>
            <div className="flex items-center gap-3">
              <SlidersHorizontal className="size-7" strokeWidth={2.25} />
              <h2 className="font-display text-3xl font-black">Filters</h2>
            </div>
          </div>


          <div
            ref={scrollRef}
            data-filters-scroll
            className="flex-1 overflow-y-auto overscroll-contain bg-card px-5 pb-[calc(env(safe-area-inset-bottom)+7rem)]"
          >

            <section className="py-6">
              <h3 className="mb-4 font-display text-lg font-bold">Preferred time</h3>
              <ul className="space-y-1">
                {TIME_OPTIONS.map((t) => {
                  const active = times.has(t.key);
                  return (
                    <li key={t.key}>
                      <button
                        onClick={() => toggle(times, t.key, setTimes)}
                        className="flex w-full items-center justify-between py-4 text-left"
                      >
                        <span className="text-base">
                          {t.label}{" "}
                          <span className="text-muted-foreground">({t.range})</span>
                        </span>
                        <span
                          className={`flex size-6 items-center justify-center rounded-md border-2 transition-colors ${
                            active
                              ? "border-primary bg-primary text-primary-foreground"
                              : "border-border bg-background"
                          }`}
                        >
                          {active && (
                            <svg viewBox="0 0 24 24" className="size-4" fill="none" stroke="currentColor" strokeWidth={3} strokeLinecap="round" strokeLinejoin="round">
                              <path d="M5 12l5 5L20 7" />
                            </svg>
                          )}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            </section>

            <div className="border-t border-border" />

            <section className="py-6">
              <div className="mb-2 flex items-center justify-between">
                <h3 className="font-display text-lg font-bold">Distance away</h3>
                <span className="text-sm font-semibold text-primary">
                  0 mi - {radius} mi
                </span>
              </div>
              <p className="mb-6 text-sm text-muted-foreground">
                See games based on proximity of your location
              </p>
              <input
                type="range"
                min={0}
                max={50}
                step={1}
                value={radius}
                onChange={(e) => setRadius(Number(e.target.value))}
                className="slider-volt w-full"
                style={{ "--slider-pct": `${(radius / 50) * 100}%` } as React.CSSProperties}
                aria-label="Search radius in miles"
              />
              <div className="mt-2 flex justify-between text-xs font-semibold text-muted-foreground">
                <span>0</span>
                <span>50</span>
              </div>
            </section>

            <div className="border-t border-border" />

            <section className="py-6">
              <h3 className="mb-4 font-display text-lg font-bold">Game difficulty</h3>
              <ul className="space-y-1">
                {DIFFICULTY_OPTIONS.map((d) => {
                  const active = diffs.has(d);
                  return (
                    <li key={d}>
                      <button
                        onClick={() => toggle(diffs, d, setDiffs)}
                        className="flex w-full items-center justify-between py-4 text-left"
                      >
                        <span className="text-base">{d}</span>
                        <span
                          className={`flex size-6 items-center justify-center rounded-md border-2 transition-colors ${
                            active
                              ? "border-primary bg-primary text-primary-foreground"
                              : "border-border bg-background"
                          }`}
                        >
                          {active && (
                            <svg viewBox="0 0 24 24" className="size-4" fill="none" stroke="currentColor" strokeWidth={3} strokeLinecap="round" strokeLinejoin="round">
                              <path d="M5 12l5 5L20 7" />
                            </svg>
                          )}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            </section>
          </div>


          <div className="flex items-center justify-between gap-4 border-t border-border bg-card px-5 py-4 pb-[calc(env(safe-area-inset-bottom)+1rem)]">
            <button
              onClick={clearAll}
              className="text-base font-bold text-foreground"
            >
              Clear
            </button>
            <button
              onClick={() => setShowFilters(false)}
              className="flex-1 max-w-[220px] rounded-full bg-primary py-3.5 text-center font-display text-base font-bold text-primary-foreground"
            >
              See {filtered.length} {filtered.length === 1 ? "Game" : "Games"}
            </button>
          </div>

        </section>
      )}

      {view === "list" ? (
        <>
          <Section title="Free Sessions" count={free.length}>
            {free.map((g) => (
              <GameCard key={g.id} game={g} />
            ))}
            {free.length === 0 && <EmptyRow label="No free sessions match" />}
          </Section>

          <Section title="Paid Sessions" count={paid.length}>
            {paid.map((g) => (
              <GameCard key={g.id} game={g} />
            ))}
            {paid.length === 0 && <EmptyRow label="No paid sessions match" />}
          </Section>
        </>
      ) : (
        <MapView
          locationOn={locationOn}
          locating={locating}
          enableLocation={enableLocation}
          selectedGameId={selectedGameId}
          setSelectedGameId={setSelectedGameId}
          selectedGame={selectedGame}
        />
      )}
    </div>
  );
}

function MapView({
  locationOn,
  locating,
  enableLocation,
  selectedGameId,
  setSelectedGameId,
  selectedGame,
}: {
  locationOn: boolean;
  locating: boolean;
  enableLocation: () => void;
  selectedGameId: string;
  setSelectedGameId: (id: string) => void;
  selectedGame: (typeof mockGames)[number];
}) {
  return (
    <div className="px-5 pt-4">
      <div className="relative aspect-[4/5] overflow-hidden rounded-2xl border border-border bg-card">
        <div
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage:
              "linear-gradient(var(--border) 1px, transparent 1px), linear-gradient(90deg, var(--border) 1px, transparent 1px)",
            backgroundSize: locationOn ? "32px 32px" : "48px 48px",
            transition: "background-size 500ms ease",
          }}
        />
        {!locationOn ? (
          <>
            <svg
              viewBox="0 0 200 120"
              className="absolute inset-0 h-full w-full p-6 text-secondary/40"
              fill="currentColor"
              aria-hidden
            >
              <path d="M20,55 L28,42 L42,38 L58,30 L78,28 L98,26 L118,28 L138,30 L155,34 L172,42 L182,55 L180,68 L172,78 L155,88 L138,92 L120,95 L108,102 L95,100 L82,95 L68,92 L52,88 L38,82 L28,72 Z" />
            </svg>
            <div className="absolute left-1/2 top-4 -translate-x-1/2 rounded-full border border-border bg-background/80 px-3 py-1 font-display text-[10px] font-bold uppercase tracking-widest backdrop-blur">
              United States
            </div>
            {usCityDots.map((c) => (
              <div
                key={c.label}
                style={{ top: c.top, left: c.left }}
                className="absolute -translate-x-1/2 -translate-y-1/2"
              >
                <div className="relative">
                  <div className="size-2.5 rounded-full bg-primary shadow-[0_0_10px] shadow-primary/60" />
                  <div className="absolute -top-1 left-1/2 size-2.5 -translate-x-1/2 animate-ping rounded-full bg-primary opacity-40" />
                </div>
                <span className="mt-1 block text-center text-[9px] font-bold uppercase tracking-wider text-muted-foreground">
                  {c.label}
                </span>
              </div>
            ))}
            <div className="absolute inset-x-0 bottom-0 flex flex-col items-center gap-2 bg-gradient-to-t from-background via-background/90 to-transparent px-5 pb-5 pt-10">
              <button
                onClick={enableLocation}
                disabled={locating}
                className="flex items-center gap-2 rounded-full bg-primary px-5 py-3 font-display text-sm font-bold uppercase tracking-tight text-primary-foreground shadow-lg glow-primary disabled:opacity-60"
              >
                <Locate className="size-4" />
                {locating ? "Locating…" : "Turn On Location"}
              </button>
              <p className="text-center text-[10px] uppercase tracking-widest text-muted-foreground">
                We'll zoom into your neighborhood
              </p>
            </div>
          </>
        ) : (
          <>
            <div className="absolute left-1/2 top-1/2 size-[85%] -translate-x-1/2 -translate-y-1/2 rounded-full border border-primary/20" />
            <div className="absolute left-1/2 top-1/2 size-[55%] -translate-x-1/2 -translate-y-1/2 rounded-full border border-primary/30" />
            <div className="absolute left-1/2 top-1/2 size-[25%] -translate-x-1/2 -translate-y-1/2 rounded-full border border-primary/40" />
            <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
              <div className="size-3 rounded-full bg-foreground ring-4 ring-foreground/20" />
            </div>
            <div className="absolute left-1/2 top-[calc(50%+14px)] -translate-x-1/2 whitespace-nowrap text-[9px] font-bold uppercase tracking-widest text-muted-foreground">
              You
            </div>
            {mockGames.map((game, i) => (
              <button
                key={game.id}
                onClick={() => setSelectedGameId(game.id)}
                style={localPositions[i % localPositions.length]}
                aria-label={game.title}
                className={`absolute -translate-x-1/2 -translate-y-1/2 rounded-full px-2 py-1 font-display text-xs font-bold transition-all ${
                  selectedGameId === game.id
                    ? "z-10 scale-110 bg-primary text-primary-foreground glow-primary"
                    : "border border-border bg-background/90 text-foreground"
                }`}
              >
                <MapPin className="mr-0.5 inline size-3" />
                {game.distanceMiles} mi
              </button>
            ))}
          </>
        )}
      </div>

      {locationOn && (
        <Link
          to="/games/$gameId"
          params={{ gameId: selectedGame.id }}
          className="mt-4 flex items-center justify-between rounded-2xl border border-border bg-card p-4"
        >
          <div className="min-w-0">
            <h3 className="truncate font-display text-lg font-bold uppercase leading-none">
              {selectedGame.title}
            </h3>
            <p className="mt-1 text-xs text-muted-foreground">
              {selectedGame.venue} • {selectedGame.dateLabel} {selectedGame.timeLabel}
            </p>
          </div>
          <span className="ml-3 shrink-0 rounded-xl bg-primary px-4 py-2 font-display text-sm font-bold uppercase text-primary-foreground">
            View
          </span>
        </Link>
      )}
    </div>
  );
}

function Section({
  title,
  count,
  children,
}: {
  title: string;
  count: number;
  children: React.ReactNode;
}) {
  return (
    <div className="mb-6 mt-4">
      <div className="mb-3 flex items-baseline justify-between px-5">
        <h3 className="font-display text-lg font-bold uppercase tracking-tight">
          {title}
        </h3>
        <span className="text-xs font-semibold text-muted-foreground">
          {count} available
        </span>
      </div>
      <div className="space-y-4 px-5">{children}</div>
    </div>
  );
}

function EmptyRow({ label }: { label: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border bg-card p-6 text-center text-sm text-muted-foreground">
      {label}
    </div>
  );
}
