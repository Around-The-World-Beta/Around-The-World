import { useI18n } from "../lib/i18n";

export function MyGamesPage() {
  const { t } = useI18n();
  return (
    <div className="state-box">
      <h2>{t("myGames")}</h2>
      <p>
        Sessions you join stay here — including full ones. Sign-in wires this list to{" "}
        <code>/api/v1/games/mine</code>.
      </p>
    </div>
  );
}
