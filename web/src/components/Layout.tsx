import { NavLink, Outlet } from "react-router-dom";
import { useI18n } from "../lib/i18n";

export function Layout() {
  const { t } = useI18n();
  const link = ({ isActive }: { isActive: boolean }) => (isActive ? "active" : undefined);

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <strong>
            Around <span>World</span>
          </strong>
          <small>{t("tagline")}</small>
        </div>
        <nav className="nav">
          <NavLink to="/" end className={link}>
            {t("matches")}
          </NavLink>
          <NavLink to="/map" className={link}>
            {t("map")}
          </NavLink>
          <NavLink to="/host" className={link}>
            {t("host")}
          </NavLink>
          <NavLink to="/my-games" className={link}>
            {t("myGames")}
          </NavLink>
          <NavLink to="/profile" className={link}>
            {t("profile")}
          </NavLink>
          <NavLink to="/settings" className={link}>
            {t("settings")}
          </NavLink>
        </nav>
      </header>
      <main>
        <Outlet />
      </main>
    </div>
  );
}
