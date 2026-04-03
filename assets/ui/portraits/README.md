Portrait assets can be dropped here and will override the procedural portrait fallback automatically.

Expected folders
- `res://assets/ui/portraits/classes/`
- `res://assets/ui/portraits/enemies/`

Supported formats
- `.png`
- `.webp`
- `.jpg`
- `.jpeg`

Naming
- Class portraits use the class id, for example `novice.png`
- Enemy portraits use the enemy id, for example `melbourne_mirage.png`
- Folder-based art packs are also supported:
  - `classes/novice/portrait.png`
  - `classes/novice/card.png`
  - `enemies/melbourne_mirage/portrait.png`
  - `enemies/melbourne_mirage/hero.png`

Recommended art direction
- Square painted busts work best, ideally `1024x1024` or larger
- Keep the racquet visible in frame
- Use bold rim light / energy color behind the character
- Leave a little breathing room above the head so the card frame does not crowd the art

If a file is missing, the UI falls back to the built-in illustrated portrait tile.
