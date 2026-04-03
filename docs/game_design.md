# Court of Chaos - Game Design Snapshot

## High concept

`Court of Chaos` is a tennis-themed roguelike deckbuilder built in Godot. Runs move across a branching path of matches, recovery stops, events, elites, and bosses. Combat is turn-based and card-driven: every card represents a tennis action, tactical adjustment, or conditioning move.

Each major also changes the rules of play through court-surface modifiers and a seeded championship twist for its final.

## Core loop

1. Choose any class.
2. Enter a major tournament and pick a route across a branching path.
3. Play shot cards to win rallies, control tempo, and survive enemy patterns.
4. After fights, add specialty shots to your deck or improve stats.
5. Beat a major final to move deeper into the tournament nightmare.
6. Clear runs to unlock the next class in the roster order.

## Stat model

These stats keep the game rooted in sport language instead of generic RPG labels.

- `Stamina`: energy available each turn.
- `Endurance`: max health and resistance to fatigue-based effects.
- `Strength`: direct damage and power-shot scaling.
- `Control`: accuracy of technical shots, debuffs, and combo setup.
- `Footwork`: guard/block efficiency and positioning tools.
- `Focus`: draw consistency, retain, and recovery from disruption.

## Combat vocabulary

- `Guard`: blocks incoming damage during a rally.
- `Momentum`: temporary offensive tempo that increases damage.
- `Pressure`: makes the opponent more vulnerable to the next damaging shot.
- `Spin`: delayed setup value that upgrades certain shot cards.
- `Fatigue`: reduces usable stamina or weakens recovery.
- `Open Court`: the target is out of position, enabling bonus effects.

## Class unlock order

The roster unlocks in the exact order requested. The current implementation assumes each completed run unlocks the next class.

1. Novice
2. Pusher
3. Slicer
4. Power
5. All-Arounder
6. Baseliner
7. Serve and Volley
8. Master
9. Alcaraz

## Class identities

- `Novice`: forgiving starter with flexible basics and simple recovery.
- `Pusher`: attrition specialist that wins long exchanges and punishes impatience.
- `Slicer`: control class focused on low skids, debuffs, and awkward ball placement.
- `Power`: explosive striker that converts stamina into huge hits.
- `All-Arounder`: adaptive toolkit with balanced stats and pattern-switching bonuses.
- `Baseliner`: topspin-heavy rally class that dominates from the back of the court.
- `Serve and Volley`: fast tempo class that chains serves into net pressure.
- `Master`: advanced technical class with retention, foresight, and efficiency.
- `Alcaraz`: late-game unlock built around speed, variety, burst, and highlight-reel combo turns.

## Cards and rewards

Cards are the main source of power growth. Rewards should lean heavily on specialty shots, tactical drills, and signature sequences instead of abstract spells.

Examples:

- `Topspin Drive`
- `Slice Drag`
- `Kick Serve`
- `Drop Shot`
- `Approach Shot`
- `Net Rush`
- `Inside-Out Forehand`
- `Second Wind`

Permanent upgrades can later come from coaching perks, equipment, string setups, shoes, and tournament boons.

The current prototype now includes string-setup modifier cards that equip a match-long racquet profile, such as polyester, natural gut, hybrid, or kevlar.

It also includes racquet-weight modifier cards, such as lead-tape builds, counterweighted handles, head-light control molds, extra-long leverage frames, and heavier pro-stock frames, which trade extra shot power and stability for faster Condition loss and added wear over time.

The combat HUD now surfaces the active string bed and frame build as dedicated equipment badges so the player can read their live loadout without scanning the whole summary block.

String setups and racquet builds can also carry class-specific synergy bonuses during a match, letting the right player archetype unlock extra pressure, accuracy, guard, or reduced endurance tax from a favored setup.

The current UI layer now also supports framed card-style buttons for hand, route, and reward selection, plus texture-ready portrait slots. Portrait art can be dropped into `/Users/dylankelzer/Documents/New project/court-of-chaos/assets/ui/portraits/classes` and `/Users/dylankelzer/Documents/New project/court-of-chaos/assets/ui/portraits/enemies` to replace the procedural portrait fallback without touching game logic.

The progression layer now includes a bitcoin economy. Regular wins pay out bitcoin, elite wins pay out a larger amount, and those funds can be spent at checkpoint shops on:

- buying new cards
- upgrading an existing card into its stronger `+` version
- improving the run-wide racquet workshop level so future frame modifiers hit harder and stabilize better

Rest checkpoints now offer a meaningful endurance choice instead of only flat healing, letting the player raise max Condition before the next branch.

## Character model direction

Playable classes should read like tennis legends translated into grounded high fantasy, then fused with monster ancestry. The detailed per-class model briefs live in `/Users/dylankelzer/Documents/New project/court-of-chaos/docs/character_models.md`.

## Enemies

The enemy roster mixes recognizable tennis archetypes with surreal racquet-wielding monsters.

### Human-style rivals

- Counterpunchers
- Junkball tricksters
- Baseline grinders
- Net rushers
- Mirror-match rivals
- Phantom coaches

### Monster opponents

- Moonball goblins
- Ball-machine imps
- Clay trolls
- Racquet wraiths
- Volley vampires
- Court titans

## Encounter ladder

Majors use a branching path with nodes such as:

- Regular combat
- Elite combat
- Boss combat
- Rest / training
- Event
- Shop
- Treasure

The included scaffold generates four majors in calendar order: Australian Open, Roland-Garros, Wimbledon, and the US Open. Each major is a mini tournament that funnels through qualifying, main-draw rounds, and a major final. Regular and elite nodes pull from major-specific encounter pools.

The current prototype also includes:

- Hardcourt modifiers that speed up serve and power patterns
- Clay modifiers that reward topspin and turn long rallies into fatigue battles
- Grass modifiers that amplify serve, slice, and net play
- Seeded reveal cards that preview featured opponents in each major draw
- Featured seeds that can be forced into the path and pay out better when defeated
- A weighted randomized final-rule variant for every major final
- Surface-tuned UI palettes and simple synthesized reveal stingers for each major

## First production target

The first milestone for implementation is not full content parity with a finished deckbuilder. It is a playable vertical slice with:

- 4 Grand Slam majors
- 9 classes defined and unlockable
- 20+ cards
- 15+ enemies across regular, elite, and boss categories
- Branching act generation
- One complete combat loop with a hand, discard, draw, stamina, guard, enemy intents, and status resolution

The project now includes that first vertical slice using the extracted PDF architecture as the guide:

- `RefCounted` simulation objects for match state, deck state, rally state, and tennis scoring
- A rally-pressure combat model instead of generic HP trading inside encounters
- Deterministic seeded encounter generation and act paths
- A clickable map screen that locks and unlocks paths like an STS-style run
- Persistent unlock saves for class progression between runs

The next production steps are content depth, reward variety, animation, and broader meta-progression.
