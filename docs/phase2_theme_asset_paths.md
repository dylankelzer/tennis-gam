# Phase 2 Theme Asset Paths

The theme layer now expects the following semantic asset paths.

## Base UI
- `res://assets/ui/kenney_base/panel_primary.png`
- `res://assets/ui/kenney_base/panel_secondary.png`
- `res://assets/ui/kenney_base/button_primary_idle.png`
- `res://assets/ui/kenney_base/button_primary_pressed.png`

## Card Frames
- `res://assets/ui/frames/card_frame_attack.png`
- `res://assets/ui/frames/card_frame_skill.png`
- `res://assets/ui/frames/card_frame_power.png`

## Icons
- `res://assets/icons/kenney_icons/energy.png`
- `res://assets/icons/kenney_icons/health.png`
- `res://assets/icons/kenney_icons/attack.png`
- `res://assets/icons/kenney_icons/defense.png`

## Backgrounds
- `res://assets/ui/backgrounds/hardcourt.png`
- `res://assets/ui/backgrounds/grass.png`
- `res://assets/ui/backgrounds/clay.png`
- `res://assets/ui/backgrounds/tarmac.png`

## Notes
- The current repo aliases existing imported art into these filenames so the code can stabilize around the semantic names first.
- `ThemeManager` still exposes compatibility keys like `panel_fill` and `card_border` internally so older callers continue to work during the transition.
- Divider visuals currently reuse `res://assets/ui/kenney_base/panel_secondary.png` because no dedicated divider asset was listed in the canonical folders yet.
- The new icon files currently reuse the previously imported tennis-ball textures as placeholders until final icon art is dropped in.
