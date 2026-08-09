import { useI18n, type Lang } from "../lib/i18n";

export function SettingsPage() {
  const { t, lang, setLang } = useI18n();

  return (
    <div className="settings">
      <section className="hero">
        <h1>{t("settings")}</h1>
      </section>
      <label htmlFor="lang">{t("language")}</label>
      <select
        id="lang"
        value={lang}
        onChange={(e) => setLang(e.target.value as Lang)}
      >
        <option value="system">{t("langSystem")}</option>
        <option value="en">{t("langEn")}</option>
        <option value="es">{t("langEs")}</option>
      </select>
      <p className="muted" style={{ marginTop: "1rem" }}>
        API keys: set <code>VITE_SUPABASE_URL</code>, <code>VITE_SUPABASE_ANON_KEY</code>,{" "}
        <code>VITE_GOOGLE_PLACES_API_KEY</code> in <code>web/.env</code> (see{" "}
        <code>.env.example</code>). Nothing secret is committed.
      </p>
    </div>
  );
}
