import { MapContainer, Marker, Popup, TileLayer } from "react-leaflet";
import L from "leaflet";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";
import { Link } from "react-router-dom";
import { useGames } from "../hooks/useGames";
import { spotsLeft } from "../lib/api";
import { useI18n } from "../lib/i18n";
import "leaflet/dist/leaflet.css";

// Fix default marker assets under Vite.
const DefaultIcon = L.icon({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});
L.Marker.prototype.options.icon = DefaultIcon;

const SF_CENTER: [number, number] = [37.7749, -122.4194];

export function MapPage() {
  const { t } = useI18n();
  const { games, loading, error, reload } = useGames();

  return (
    <div>
      <section className="hero">
        <h1>{t("map")}</h1>
        <p>{t("basedIn")}</p>
      </section>

      {loading && <div className="state-box">{t("loading")}</div>}
      {error && (
        <div className="state-box">
          <h2>{t("error")}</h2>
          <p>{error}</p>
          <button className="btn" type="button" onClick={() => void reload()}>
            {t("retry")}
          </button>
        </div>
      )}
      {!loading && !error && games.length === 0 && (
        <div className="state-box">{t("mapEmpty")}</div>
      )}

      {!loading && !error && games.length > 0 && (
        <div className="map-wrap">
          <MapContainer center={SF_CENTER} zoom={9} scrollWheelZoom>
            <TileLayer
              attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
              url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
            />
            {games.map((game) => (
              <Marker key={game.id} position={[game.latitude, game.longitude]}>
                <Popup>
                  <strong>{game.title}</strong>
                  <br />
                  {game.neighborhood}
                  <br />
                  {spotsLeft(game)} {t("spots")}
                  <br />
                  <Link to={`/games/${game.id}`}>Details</Link>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        </div>
      )}
    </div>
  );
}
