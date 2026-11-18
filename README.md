# brainrot-tycoon-roblox

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Hellboys87/brainrot-tycoon-roblox/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Hellboys87/brainrot-tycoon-roblox/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Base Tycoon** — a 3D Roblox brainrot game in the genre Steal a Brainrot began. Absurd meme-born characters (the Brainrots) wander a central plaza: catch one, carry it home on your back while the Tsunami Wave sweeps the map, and set it on a pad at your base, where it earns Coins every second. Six rarities (Common, Rare, Epic, Legendary, Mythic, Brainrot God), Golden and Diamond mutations that multiply earnings, a shop for rarer Brainrots and base upgrades, base locking to stop other players stealing your cast, and a rebirth ladder that resets your base for a permanent earnings multiplier. Progress saves with DataStore.

The world, the cast and every system are built procedurally from the Luau source under `src/` (Rojo layout): a server core (catalog, economy, bases, stealing, waves, rebirths, saving) and a client (HUD, shop, prompts, sounds). `game.rbxl` is built from that source with Rojo, so the scripts in the place and the files under `src/` are the same text.

## Run it

```sh
rojo build default.project.json --output game.rbxl   # build the place from src/
# open game.rbxl in Roblox Studio and press Play, or publish it as your experience
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts  # hand the entry in (writes out/dossier.json)
```

---
<sub>Entered on [make.fun](https://make.fun/?ref=9xcq3bkm&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
