# Run Around the World (Bay Area)

## Primary: Cursor / VS Code

```sh
./scripts/dev.sh
```

- Web UI: http://127.0.0.1:5173  
- API: http://127.0.0.1:8081/health  
- Smoke: `./scripts/smoke-api.sh`

### Fresh Bay Area seed

If you still see old/empty listings:

```sh
rm -f Backend/around_the_world.sqlite*
SEED_DEMO=1 ./scripts/run-backend.sh
```

You should see sessions across SF, Peninsula, East Bay, South Bay, and North Bay (all nine counties).

### Web only (API already running)

```sh
cd web
bun install
bun run dev
```

### Env keys (optional)

Copy `web/.env.example` → `web/.env`. Leave blank for local proxy.

---

## Optional: Xcode iOS app

Only needed for Simulator / TestFlight on a Mac:

1. `./scripts/run-backend.sh`
2. Open `ios/AroundTheWorld/AroundTheWorld.xcodeproj`
3. Run on iPhone simulator (iOS 17+)

See `ios/AroundTheWorld/README.md` if the scheme is missing after a pull.

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| Web shows API error | Start `./scripts/run-backend.sh` first |
| Only 3 old games / Brooklyn | Delete `Backend/around_the_world.sqlite*` and restart with `SEED_DEMO=1` |
| Port 5173 or 8081 busy | Kill the old process or change ports |
| Map tiles blank | Needs network to OpenStreetMap tiles |
| bun missing | https://bun.sh |
| Swift missing (API) | Install Swift / Xcode CLT on Mac; Cloud agents use `/opt/swift` |
