import { useEffect, useState } from "react";
import { GameCard } from "../components/GameCard";
import { useGames } from "../hooks/useGames";
import { api, type BayAreaMeta } from "../lib/api";
import { useI18n } from "../lib/i18n";

export function MatchesPage() {
  const { t } = useI18n();
  const { games, loading, error, reload } = useGames();
  const [meta, setMeta] = useState<BayAreaMeta | null>(null);

  useEffect(() => {
    void api.bayAreaMeta().then(setMeta).catch(() => setMeta(null));
  }, []);

  const free = games.filter((g) => g.priceCents === 0);
  const paid = games.filter((g) => g.priceCents > 0);

  return (
    <div>
      <section className="hero">
        <h1>{t("hero")}</h1>
        <p>{t("subtitle")}</p>
      </section>

      <div className="meta-strip">
        {t("counties")}
        {meta ? ` · ${meta.counties.join(" · ")}` : ""}
      </div>

      {loading && <div className="state-box">{t("loading")}</div>}

      {!loading && error && (
        <div className="state-box">
          <h2>{t("error")}</h2>
          <p>{error}</p>
          <p className="muted">Start the API with ./scripts/run-backend.sh (or ./scripts/dev.sh)</p>
          <button className="btn" type="button" onClick={() => void reload()}>
            {t("retry")}
          </button>
        </div>
      )}

      {!loading && !error && games.length === 0 && (
        <div className="state-box">
          <h2>{t("emptyTitle")}</h2>
          <p>{t("emptyBody")}</p>
          <button className="btn" type="button" onClick={() => void reload()}>
            {t("retry")}
          </button>
        </div>
      )}

      {!loading && !error && games.length > 0 && (
        <>
          <div className="section-title">
            <h2>{t("free")}</h2>
            <span>{free.length}</span>
          </div>
          <div className="grid">
            {free.map((g) => (
              <GameCard key={g.id} game={g} />
            ))}
          </div>

          <div className="section-title">
            <h2>{t("paid")}</h2>
            <span>{paid.length}</span>
          </div>
          <div className="grid">
            {paid.map((g) => (
              <GameCard key={g.id} game={g} />
            ))}
          </div>
        </>
      )}

      {meta && (
        <>
          <div className="section-title">
            <h2>{t("basedIn")}</h2>
          </div>
          <div className="county-list">
            {meta.counties.map((county) => (
              <article key={county}>
                <h3>{county}</h3>
                <p>{(meta.citiesByCounty[county] ?? []).join(", ")}</p>
              </article>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
