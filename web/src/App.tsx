import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { Layout } from "./components/Layout";
import { I18nProvider } from "./lib/i18n";
import { GameDetailPage } from "./pages/GameDetailPage";
import { HostPage } from "./pages/HostPage";
import { MapPage } from "./pages/MapPage";
import { MatchesPage } from "./pages/MatchesPage";
import { MyGamesPage } from "./pages/MyGamesPage";
import { ProfilePage } from "./pages/ProfilePage";
import { SettingsPage } from "./pages/SettingsPage";

export default function App() {
  return (
    <I18nProvider>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<MatchesPage />} />
            <Route path="map" element={<MapPage />} />
            <Route path="host" element={<HostPage />} />
            <Route path="my-games" element={<MyGamesPage />} />
            <Route path="profile" element={<ProfilePage />} />
            <Route path="settings" element={<SettingsPage />} />
            <Route path="games/:id" element={<GameDetailPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </I18nProvider>
  );
}
