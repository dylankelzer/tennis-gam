# Repo Alignment Note

This pass aligned the active theme, FX, and unit asset pipelines to the canonical folders declared in `AGENTS.md`.

## Aligned Now
- `res://assets/ui/kenney_base/`
- `res://assets/ui/frames/`
- `res://assets/icons/kenney_icons/`
- `res://assets/fx/slashes/`
- `res://assets/fx/impacts/`
- `res://assets/fx/status/`
- `res://assets/units/player/`
- `res://assets/units/enemy/`

## Unit Mapping
- `novice` -> `res://assets/units/player/novice/`
- `grinder` -> `res://assets/units/enemy/grinder/`

## Cleanup Note
- The older `res://assets/characters/` folder now only contains stale `.import` sidecars.
- Runtime references were moved to `res://assets/units/...` in:
  - `res://scripts/data/unit_database.gd`
  - `res://scripts/tools/generate_combat_assets.gd`
