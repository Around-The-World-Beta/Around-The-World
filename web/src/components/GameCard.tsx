import { Link } from "react-router-dom";
import { kickoffLabel, priceLabel, spotsLeft, type Game, isFull } from "../lib/api";
import { useI18n } from "../lib/i18n";

export function GameCard({ game }: { game: Game }) {
  const { t, locale } = useI18n();
  const left = spotsLeft(game);

  return (
    <article className="card">
      <div className="chips">
        <span className="chip">{kickoffLabel(game.startsAt, locale)}</span>
        <span className="chip">{game.skill}</span>
        <span className="chip">{game.format}</span>
        <span className={`chip ${isFull(game) ? "" : "gold"}`}>
          {isFull(game) ? t("full") : `${left} ${t("spots")}`}
        </span>
      </div>
      <h3>{game.title}</h3>
      <div className="muted">
        {game.neighborhood} · {game.venue}
      </div>
      <div className="muted">
        {game.joinedCount}/{game.capacity} · {priceLabel(game)}
      </div>
      <Link className="btn" to={`/games/${game.id}`}>
        Details
      </Link>
    </article>
  );
}
