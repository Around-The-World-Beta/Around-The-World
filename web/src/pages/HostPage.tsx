import { useMemo, useState } from "react";
import { MapContainer, Marker, TileLayer, useMapEvents } from "react-leaflet";
import { useI18n } from "../lib/i18n";
import "leaflet/dist/leaflet.css";

type Hit = {
  display_name: string;
  lat: string;
  lon: string;
};

function PinDrop({
  onPick,
}: {
  onPick: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      onPick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export function HostPage() {
  const { t } = useI18n();
  const [query, setQuery] = useState("");
  const [hits, setHits] = useState<Hit[]>([]);
  const [pin, setPin] = useState<{ lat: number; lng: number } | null>({
    lat: 37.7749,
    lng: -122.4194,
  });
  const [label, setLabel] = useState("San Francisco, CA");

  const center = useMemo<[number, number]>(
    () => [pin?.lat ?? 37.7749, pin?.lng ?? -122.4194],
    [pin],
  );

  async function search() {
    if (!query.trim()) return;
    // Nominatim — free geocoder for host search in Cursor/VS Code (no Google Maps).
    const url = new URL("https://nominatim.openstreetmap.org/search");
    url.searchParams.set("q", `${query.trim()}, California`);
    url.searchParams.set("format", "json");
    url.searchParams.set("limit", "6");
    url.searchParams.set("viewbox", "-123.15,38.85,-121.20,36.90");
    url.searchParams.set("bounded", "1");
    const res = await fetch(url.toString(), {
      headers: {
        Accept: "application/json",
        "User-Agent": "AroundTheWorldBayArea/1.0 (local-dev)",
      },
    });
    const data = (await res.json()) as Hit[];
    setHits(data);
  }

  return (
    <div>
      <section className="hero">
        <h1>{t("host")}</h1>
        <p>{t("hostHint")}</p>
      </section>

      <div className="host" style={{ marginTop: "1rem" }}>
        <input
          value={query}
          placeholder={t("searchPlaceholder")}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") void search();
          }}
        />
        <div style={{ marginTop: "0.75rem" }}>
          <button className="btn" type="button" onClick={() => void search()}>
            Search
          </button>
        </div>
        {hits.length > 0 && (
          <div className="grid" style={{ marginTop: "1rem" }}>
            {hits.map((hit) => (
              <button
                key={`${hit.lat}-${hit.lon}`}
                className="card"
                type="button"
                style={{ textAlign: "left", cursor: "pointer" }}
                onClick={() => {
                  setPin({ lat: Number(hit.lat), lng: Number(hit.lon) });
                  setLabel(hit.display_name);
                  setHits([]);
                }}
              >
                {hit.display_name}
              </button>
            ))}
          </div>
        )}
      </div>

      <div className="map-wrap" style={{ marginTop: "1rem" }}>
        <MapContainer center={center} zoom={11} scrollWheelZoom>
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <PinDrop
            onPick={(lat, lng) => {
              setPin({ lat, lng });
              setLabel(`${lat.toFixed(4)}, ${lng.toFixed(4)}`);
            }}
          />
          {pin && <Marker position={[pin.lat, pin.lng]} />}
        </MapContainer>
      </div>

      <p className="muted" style={{ marginTop: "0.75rem" }}>
        {label}
        {pin ? ` · ${pin.lat.toFixed(5)}, ${pin.lng.toFixed(5)}` : ""}
      </p>
      <button className="btn ghost" type="button" disabled>
        Publish (sign-in coming next)
      </button>
    </div>
  );
}
