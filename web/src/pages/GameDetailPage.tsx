import { useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, kickoffLabel, priceLabel, spotsLeft, type Game, isFull } from "../lib/api";
import { useI18n } from "../lib/i18n";

export function GameDetailPage() {
  const { id } = useParams();
  const { t, locale } = useI18n();
  const [game, setGame] = useState<Game | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    void api
      .getGame(id)
      .then(setGame)
      .catch((e) => setError(e instanceof Error ? e.message : String(e)));
  }, [id]);

  if (error) {
    return (
      <div className="state-box">
        <h2>{t("error")}</h2>
        <p>{error}</p>
        <Link className="btn" to="/">
          {t("matches")}
        </Link>
      </div>
    );
  }

  if (!game) return <div className="state-box">{t("loading")}</div>;

  return (
    <div>
      <Link className="muted" to="/">
        ← {t("matches")}
      </Link>
      <section className="hero" style={{ marginTop: "1rem" }}>
        <h1>{game.title}</h1>
        <p>
          {game.neighborhood} · {game.venue}
        </p>
      </section>
      <div className="chips" style={{ margin: "1rem 0" }}>
        <span className="chip">{kickoffLabel(game.startsAt, locale)}</span>
        <span className="chip">{game.skill}</span>
        <span className="chip">{game.format}</span>
        <span className="chip gold">{priceLabel(game)}</span>
      </div>
      <article className="card">
        <div>
          Players: {game.joinedCount}/{game.capacity}
          {!isFull(game) ? ` · ${spotsLeft(game)} ${t("spots")}` : ` · ${t("full")}`}
        </div>
        <p className="muted">{game.notes}</p>
        <button className="btn" type="button" disabled>
          {isFull(game) ? "Join waitlist (sign-in next)" : "Claim spot (sign-in next)"}
        </button>
      </article>
    </div>
  );
}
