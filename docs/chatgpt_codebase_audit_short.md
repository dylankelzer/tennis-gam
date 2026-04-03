# Court of Chaos Short Audit

## Project in one paragraph
Court of Chaos is a Godot 4.6 tennis roguelike deckbuilder. The core loop is: route through a slam bracket, play tennis-themed card combat where points are won by reaching a rally-pressure target or forcing an error, win matches on tennis scoring, and manage Condition as run-level attrition. The project already has meaningful tooling: content validation, reference-path validation, headless smoke tests, CI, telemetry, and accessibility settings.

## Current architecture

### Core runtime files
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/main.gd`
  - `4651` lines
  - Top-level scene/controller
  - Handles pane transitions, UI refresh, class select, map, combat, reward, shop, rest, accessibility UI, telemetry hooks
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/systems/run_state.gd`
  - `2064` lines
  - Run progression, map traversal, rewards, checkpoints, economy, snapshots, combat entry/exit
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/systems/match_state.gd`
  - `2858` lines
  - Combat simulation, tennis scoring, rally pressure, legality, enemy turns, point flow, battle payloads
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/ai/enemy_intent_planner.gd`
  - Enemy intent scoring and state determination
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/ui/combat_hud_presenter.gd`
  - Builds combat HUD payloads from simulation state

### Data/content
- cards: `/Users/dylankelzer/Documents/New project/court-of-chaos/data/cards/card_library.tres`
- enemies: `/Users/dylankelzer/Documents/New project/court-of-chaos/data/enemies/enemy_library.tres`

## What is working well
- The simulation has a real identity now, not just generic HP combat with tennis labels.
- Tennis scoring, serve/return opener logic, rally pressure, and five-slot hand structure are explicit.
- Tooling is solid for the project stage:
  - content validation
  - resource/path validation
  - headless smoke suite
  - CI with export smoke
- Accessibility and telemetry foundations exist.
- Recent stability work improved start-of-run transitions and pane handoffs.

## Biggest problems

### 1. `main.gd` is too large and owns too much
This is the main architectural problem.
It still mixes:
- scene transitions
- pane visibility
- UI construction
- styling
- HUD updates
- checkpoint/reward/shop logic
- accessibility overlay
- telemetry wiring

That makes UI bugs and transition crashes more likely than they need to be.

### 2. The UI layer is still the main stability risk
The core simulation is relatively healthy.
The fragile area is still screen/pane orchestration, especially when one pane tears down while another builds in the same frame.

### 3. Sim and presentation are better separated, but not fully
`RunState` and `MatchState` still expose some presentation-aware concepts. That is practical, but it means the boundary is not clean yet.

## Current stability status
Recent hotfixes added:
- deferred `Begin Tournament` handoff
- deferred run-start finalization
- coalesced full UI refresh queue
- pane transition smoke coverage

Current read:
- headless flow passes
- `Begin Tournament` passes deterministic smoke
- pane transitions for landing/class select/combat/reward/shop/rest/map now have explicit smoke coverage
- full suite currently passes

Known warning still present:
- `ObjectDB instances leaked at exit`
- currently non-blocking, but worth tracing later

## Most important files to review first
1. `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/main.gd`
2. `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/systems/run_state.gd`
3. `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/systems/match_state.gd`
4. `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/ui/combat_hud_presenter.gd`
5. `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/ai/enemy_intent_planner.gd`

## Best refactor direction

### First priority
Split `main.gd` into pane-specific controllers/presenters:
- class select
- combat HUD
- reward/checkpoint/shop/rest
- map

### Second priority
Keep reducing same-frame UI churn:
- fewer direct full refreshes
- more deferred/coalesced refresh behavior
- narrower pane-specific refreshes

### Third priority
Move formatting/presentation logic out of sim state where practical.

## Questions to ask ChatGPT
1. What is the cleanest way to split a 4.6k-line Godot `main.gd` into smaller pane-specific controllers?
2. How should a Godot game structure fullscreen pane transitions when one scene hosts many states?
3. Which responsibilities should stay in `RunState` and `MatchState`, and which should move into presenters?
4. What is the best way to eliminate the lingering `ObjectDB instances leaked at exit` warning?
5. What should the first three low-risk refactors be to improve stability and maintainability?

## Fast takeaway
The project is ambitious and further along than a lot of prototypes in terms of systems, tooling, and test coverage. The main issue is no longer the tennis combat model. The main issue is that too much of the app still flows through one very large scene/controller script. If that layer gets split cleanly, the project should become much easier to stabilize and evolve.
