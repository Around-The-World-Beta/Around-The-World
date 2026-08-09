import { useI18n } from "../lib/i18n";

export function ProfilePage() {
  const { t } = useI18n();
  return (
    <div>
      <section className="hero">
        <h1>{t("profile")}</h1>
        <p>{t("basedIn")}</p>
      </section>
      <article className="card">
        <div>
          <strong>Age</strong>
          <div className="muted">—</div>
        </div>
        <div>
          <strong>Skill tier</strong>
          <div className="muted">Beginner / Intermediate / Baller</div>
        </div>
        <div>
          <strong>Position</strong>
          <div className="muted">—</div>
        </div>
        <div>
          <strong>Bio</strong>
          <div className="muted">Complete after sign-in.</div>
        </div>
        <div>
          <strong>Based in</strong>
          <div className="muted">Bay Area (nine counties)</div>
        </div>
      </article>
    </div>
  );
}
