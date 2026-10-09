# Sniper Arena

A free-for-all sniper deathmatch for [BLOX](https://blox.galtapps.site) (Roblox-compatible, Luau + Rojo layout).

- 3-minute rounds, first to 15 kills wins; headshots one-shot, body shots take two.
- First-person rifle with scope, 5-round magazine, bolt-action cooldown, auto reload.
- Phone-first controls (FIRE / SCOPE / R buttons); mouse + R/Q/E on desktop.
- Mirrored arena with two sniper towers, a central bunker and cover; moving practice dummies.

## Layout
- `src/server` — player setup, server-authoritative shooting, round loop, practice targets
- `src/client` — weapon controls, scope/crosshair, HUD, kill feed, tracers
- `src/shared/Config.luau` — tuning (damage, round time, kills to win, ...)
- `src/workspace` — generated map; regenerate with `bun tools/gen-map.ts`
