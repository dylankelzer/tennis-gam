# Court of Chaos

A Godot 4 starter project for a tennis-themed roguelike deckbuilder inspired by the structure of modern path-based card battlers.

## What is included

- A compact game design document in `/Users/dylankelzer/Documents/New project/court-of-chaos/docs/game_design.md`
- Data-driven player classes with the requested unlock order
- Tennis shot cards and archetype passives
- Enemy archetypes for human rivals and racquet monsters
- Character model briefs that fuse real-world tennis inspirations with high-fantasy monster lineages
- A run/path generator with regular fights, elites, events, rest nodes, treasure, shops, and bosses
- A playable vertical slice with four Grand Slam majors, seeded tournament reveals, surface-based combat modifiers, featured-seed encounter pressure, weighted randomized final twists, light audiovisual presentation, enemy intents, card rewards, and a clickable STS-style map
- Persistent class unlock saves stored under `user://saves/court_of_chaos_save.json`

## Open in Godot

1. Open Godot 4.2 or newer.
2. Import `/Users/dylankelzer/Documents/New project/court-of-chaos/project.godot`.
3. Run the project.

## Headless smoke test

To verify the core UI and gameplay loop from the terminal, run:

```bash
"/Users/dylankelzer/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path "/Users/dylankelzer/Documents/New project/court-of-chaos" --script "res://scripts/tests/main_flow_smoke.gd"
```

That smoke test drives a deterministic flow through:

- landing screen
- run start
- first combat
- reward selection and deck growth
- second combat entry
- return to idle via reset

To verify the bitcoin checkpoint economy, run:

```bash
"/Users/dylankelzer/Downloads/Godot.app/Contents/MacOS/Godot" --headless --path "/Users/dylankelzer/Documents/New project/court-of-chaos" --script "res://scripts/tests/checkpoint_economy_smoke.gd"
```

That smoke test verifies:

- bitcoin payout from combat wins
- shop checkpoint purchases and upgrades
- rest checkpoint endurance growth
- continued progression back into combat after each checkpoint

## Current scope

This project now includes the first playable loop:

- Choose any class
- Traverse a clickable major-tournament map
- Fight turn-based tennis encounters with a hand, draw/discard, stamina, guard, status resolution, and telegraphed enemy intents
- Adapt to hardcourt, clay, and grass effects that change pressure, accuracy, and rally texture
- Read each major's featured field and randomized championship rule before the final
- See each major use its own visual palette and synthesized stinger when the draw or final reveal appears
- Use framed shot cards, framed reward picks, and a restyled tournament map that now share the same tennis-fantasy asset language as combat
- Draft new cards after fights and special nodes
- Earn bitcoin from regular and elite match wins, then spend it at checkpoint shops on card buys, card upgrades, and racquet workshop tuning
- Use rest checkpoints to raise endurance directly instead of only taking flat healing
- Find string-setup modifier cards that equip polyester, gut, hybrid, or kevlar effects for the match
- Read active strings and frame weight from live combat badges instead of hunting through the match log
- Find racquet-weight modifier cards like lead tape, pro-stock frames, head-light control molds, counterweighted handles, and extra-long builds that hit harder but drain Condition faster when points go badly
- Hit class-specific equipment synergies in combat, so the right frame build or string setup gives extra payoff beyond the base modifier
- Drop custom portrait PNGs into `/Users/dylankelzer/Documents/New project/court-of-chaos/assets/ui/portraits/classes` and `/Users/dylankelzer/Documents/New project/court-of-chaos/assets/ui/portraits/enemies` to override the procedural portrait tiles
- Persist class unlock progression between runs

It still does **not** yet include full audiovisual polish, dedicated event scenes, card upgrades, or imported 3D character assets.
