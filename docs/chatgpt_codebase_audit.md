# Court of Chaos Codebase Audit

## 1. Project Summary
Court of Chaos is a Godot 4.6 tennis roguelike deckbuilder built around tennis scoring, rally pressure, route progression, and data-driven combat content. The project combines:
- a tennis-specific combat simulation (`MatchState`)
- a run/map/checkpoint system (`RunState`)
- a large scene/controller script for top-level UI (`main.gd`)
- data/resource-backed content libraries for cards and enemies
- a growing suite of headless simulation smoke tests and tooling

Core game identity:
- Points are won by reaching a rally-pressure target or forcing an error.
- Matches are won on tennis score, not Condition.
- Condition is run-level attrition.
- The hand is structured around a 5-slot model: `INITIAL`, `SHOT`, `ENHANCER`, `MODIFIER`, `SPECIAL`.

## 2. Current Architecture Overview

### Main runtime layers
- **Top-level scene/controller**
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/main.gd`
  - Size: `4651` lines
  - Responsibilities: screen transitions, UI refresh, checkpoint/reward/shop/rest flows, combat HUD application, accessibility UI, telemetry hooks, pane visibility logic.
  - This is still the main architectural bottleneck.

- **Run-level simulation / progression**
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/systems/run_state.gd`
  - Size: `2064` lines
  - Responsibilities: run progression, map traversal, rewards, checkpoints, economy, persistence snapshot generation, combat entry/exit.

- **Combat simulation**
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/systems/match_state.gd`
  - Size: `2858` lines
  - Responsibilities: tennis scoring, rally pressure, legality, stamina/costs, point flow, enemy turns, event emission, battle presentation payloads.

- **AI planner**
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/ai/enemy_intent_planner.gd`
  - Size: `212` lines
  - Responsibilities: enemy intent state determination, scoring, projection, schema validation helpers.

- **HUD presenter**
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/ui/combat_hud_presenter.gd`
  - Size: `355` lines
  - Responsibilities: transforms simulation state into combat HUD payloads.

- **Telemetry service**
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/services/telemetry.gd`
  - Size: `309` lines
  - Responsibilities: local-only JSONL telemetry, rolling stats, custom performance monitors.

### Data/content layer
The project has moved partway to resource-driven content:
- cards: `/Users/dylankelzer/Documents/New project/court-of-chaos/data/cards/card_library.tres`
- enemies: `/Users/dylankelzer/Documents/New project/court-of-chaos/data/enemies/enemy_library.tres`

Primary data loaders:
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/card_database.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/enemy_database.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/player_class_database.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/relic_database.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/data/potion_database.gd`

### Core model types
Key core scripts:
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/card_def.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/card_instance.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/deck_state.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/combat_actor_state.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/rally_state.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/tennis_score.gd`
- `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/core/match_event.gd`

## 3. Gameplay/System Summary

### Match flow
Current intended flow:
1. Point setup
2. Determine serve vs return opener context
3. Deal the 5-slot hand with legality constraints
4. Player turn chooses legal cards within stamina
5. Resolve pressure/guard/status/position
6. If point not over, enemy chooses intent and resolves
7. If point ends, tennis score updates
8. Apply Condition changes and between-point cleanup
9. Start next point

### Run flow
Current high-level flow:
- Landing
- Class select
- Transition/loading pane
- Map/major reveal
- Combat
- Reward or checkpoint
- Map
- Repeat through four majors

### Content scale (current shipped libraries)
Validated by current tooling:
- Cards: `93`
- Enemies: `30`

## 4. Strengths
- **Strong simulation identity**: the game no longer feels like generic HP combat with tennis nouns. The serve/return opener, rally pressure, open-court logic, ball state, and tennis score are explicit.
- **Better data hygiene than before**: content validation and reference validation exist and pass on shipped content.
- **Good headless coverage for a solo/indie prototype**: there is a substantial smoke suite covering content, scoring, AI, legality, UI payloads, accessibility, performance pooling, and pane transitions.
- **CI exists and is useful**: PR CI validates content, validates resource references, runs the smoke suite, and performs a Linux export smoke build.
- **Event-driven progress**: match updates are not purely polling-based now; there is an event bus for combat updates.
- **Accessibility and telemetry foundations exist**: both are local-first and test-covered.

## 5. Biggest Architectural Risks

### A. `main.gd` is still too large and too central
This is the single biggest codebase issue.
- It owns too many concerns at once.
- It mixes orchestration, pane visibility, style, view construction, event wiring, and state transition behavior.
- It is still the most likely place for future UI crashes or fragile transitions.

Even after recent improvements, `main.gd` remains a monolith and is the main reason the UI layer is harder to reason about than the simulation layer.

### B. Simulation and presentation are improved, but not fully separated
The project has moved in the right direction, but:
- `RunState` still exposes UI-oriented concepts like reward/checkpoint menu kinds.
- `MatchState` still produces presentation-friendly payloads directly.
- This is practical, but it means the sim layer is not fully presentation-agnostic.

### C. UI transition complexity is still high
The recent `Start Tournament` crash work strongly suggests the project can still hit instability when:
- one pane is tearing down
- another pane is building
- a full UI refresh happens in the same frame
- Godot layout/scene tree mutation overlaps with state changes

This is better now, but still a real area of risk.

### D. Test suite is broad but mostly smoke-style
The test suite is valuable, but most coverage is still scenario-based smoke testing rather than deep, isolated unit testing with narrow assertions.

## 6. Stability Status
Recent stability work added:
- deferred `Begin Tournament` transition path
- deferred run-start finalization
- coalesced full UI refresh queue
- pane transition smoke covering landing/class select/combat/reward/shop/rest/map handoffs

### Current stability read
- Headless flow is stable.
- `Begin Tournament` now passes deterministic end-to-end smoke.
- Full suite currently passes.
- The project still emits non-blocking Godot warnings at shutdown (`ObjectDB instances leaked at exit`).
- That warning does not currently fail the suite, but it suggests cleanup lifecycle is not completely tidy.

## 7. Testing/Tooling Status

### Tooling present
- Content validator:
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/tools/validate_content.gd`
- Resource/path/case validator:
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/tools/validate_reference_paths.gd`
- Test runner:
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/tools/run_tests.gd`
- Telemetry analyzer scaffolding:
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/tools/analyze_telemetry_balance.gd`
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/scripts/tools/telemetry_balance_analyzer.gd`

### CI
- Workflow:
  - `/Users/dylankelzer/Documents/New project/court-of-chaos/.github/workflows/ci.yml`
- Current CI stages:
  1. validate content
  2. validate reference paths
  3. run smoke suite
  4. export Linux smoke build

## 8. UX/Product Risks
- **Main player misunderstanding risk** was historically “Condition looks like HP.” This is improved, but should still be watched in playtests.
- **The 5-slot hand model** is mechanically distinctive, but can become friction if not explained clearly in UI.
- **Pane density and typography** have improved, but the UI still relies on a lot of dynamic visibility changes inside one main scene.
- **Class and style balance** is still uneven over wide seed windows, even though all classes have at least one full-tour clear in small deterministic samples.

## 9. Performance/Complexity Notes
Recent work improved combat HUD churn by:
- pooling card widgets
- pooling status and potion rows
- reducing same-frame rebuilds
- adding a debug perf panel

Still true:
- the UI layer is node-heavy
- `main.gd` remains layout-heavy
- more presenters/views should be extracted if the project continues growing

## 10. What Looks Production-Ready vs Prototype-Heavy

### More production-ready
- content validation
- reference path validation
- CI baseline
- headless regression suite
- core tennis scoring model
- legality model for the five-slot hand
- telemetry/accessibility foundations

### Still prototype-heavy
- `main.gd` monolith
- scene-level orchestration strategy
- some UI/layout code paths
- balance instrumentation/reporting still early
- some tests rely more on scenario flow than narrow public APIs

## 11. Recommended Refactor Priorities
1. **Split `main.gd` by pane/controller responsibility**
   - class select presenter/controller
   - combat HUD/controller
   - reward/checkpoint/shop/rest presenter/controller
   - map screen presenter/controller

2. **Keep reducing same-frame scene churn**
   - preserve deferred/coalesced refresh pattern
   - avoid direct `_refresh_ui()` calls inside input/state callbacks

3. **Move more UI-facing formatting out of sim state**
   - keep `RunState` and `MatchState` focused on rules/state
   - let presenters build labels and menus

4. **Tighten test seams around public APIs**
   - reduce reliance on private-ish internal state in probes over time

5. **Continue telemetry/reporting work**
   - local balancing dashboards are the right next design tool

## 12. Questions For External Analysis (good prompts for ChatGPT)
1. What is the cleanest way to split a 4.6k-line Godot `main.gd` into pane-specific controllers without overengineering?
2. How should a Godot roguelike structure a screen-state machine when one scene hosts many fullscreen panes?
3. What parts of `RunState` and `MatchState` should remain presentation-aware, and what should move into presenters/view-models?
4. How would you redesign the current smoke-heavy test suite into a more layered unit/integration test strategy?
5. What is the best way to eliminate the lingering `ObjectDB instances leaked at exit` warning in a project with many pooled UI widgets and deferred refreshes?
6. What telemetry schema would you recommend for balancing a tennis deckbuilder with rally pressure, encounter outcomes, and card win correlation?

## 13. Fast Takeaway
This is a promising and unusually ambitious Godot prototype with a real mechanical identity and better tooling than many projects at this stage. The simulation layer is in decent shape. The content/tooling/testing story is becoming solid. The biggest issue is still the UI orchestration layer, centered in `main.gd`, which remains too large and too responsible for everything. If the next refactor effort is focused there, the codebase should become much easier to evolve safely.
