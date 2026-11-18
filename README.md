# brainrot-tycoon-roblox

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Hellboys87/brainrot-tycoon-roblox/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Hellboys87/brainrot-tycoon-roblox/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Base Tycoon** — a 3D Roblox brainrot game in the genre Steal a Brainrot began. Absurd meme-born characters (the Brainrots) wander a central plaza: catch one, carry it home on your back while the Tsunami Wave sweeps the map, and set it on a pad at your base, where it earns Coins every second. Six rarities (Common, Rare, Epic, Legendary, Mythic, Brainrot God), Golden and Diamond mutations that multiply earnings, a shop for rarer Brainrots and base upgrades, base locking to stop other players stealing your cast, and a rebirth ladder that resets your base for a permanent earnings multiplier. Progress saves with DataStore.

The world, the cast and every system are built procedurally from the Luau source under `src/` (Rojo layout): a server core (catalog, economy, bases, stealing, waves, rebirths, saving) and a client (HUD, shop, prompts, sounds). `game.rbxl` is built from that source with Rojo, so the scripts in the place and the files under `src/` are the same text.

## How to play

1. **Catch one.** Wild Brainrots wander the central plaza. Walk up to one and hold the Catch prompt — it hops onto your back (and slows you down a little).
2. **Carry it home.** Run it back to your own base (your name is on the sign). Step inside and it settles onto a free display pad, where it earns Coins every second.
3. **Grow the cast.** Open the SHOP to buy a random Brainrot of any rarity tier — Common up to Brainrot God — plus extra pads and a speed boost. Every spawn can roll a Golden (x5) or Diamond (x10) mutation.
4. **Lock up.** Other players can steal Brainrots from an unlocked base, and you can steal from theirs. Hit LOCK BASE for 60 seconds of force-field safety (then it needs to recharge).
5. **Mind the wave.** A Tsunami Wave sweeps the map about every 90 seconds. If it catches you in the open while carrying, you drop your Brainrot and it runs back to the plaza — shelter inside a base.
6. **Rebirth.** Trade your Coins and placed Brainrots for a permanent x2 earnings multiplier. The cost quadruples each time; the multiplier never resets.

Coins, rebirths, extra pads and your placed Brainrots save automatically (DataStore), so your base is waiting when you come back.

## Run it

```sh
rojo build default.project.json --output game.rbxl   # build the place from src/
# open game.rbxl in Roblox Studio and press Play, or publish it as your experience
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts  # hand the entry in (writes out/dossier.json)
```

---
<sub>Entered on [make.fun](https://make.fun/?ref=9xcq3bkm&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
