# Art guide

How to draw art for Homework & Chores so it fits the 16-bit look and works in the app.
For where the art lives in the code and how it gets there, see [design/art-assets.md](design/art-assets.md).

> **Status:** this guide describes the asset format introduced in 0.7.2. Until that version
> ships, most art is still drawn in Dart code (see the migration plan).

## The look in one paragraph
A 16-bit console game, not 8-bit: limited palettes but with shading, a dark one-pixel outline
around every sprite, light coming from the **top left**, and no smoothing anywhere. The app has
two moods: **parchment by day** (light mode) and **the dungeon at night** (dark mode). Art must
read well on both backgrounds.

## Tools
Any editor that saves PNG and loads a palette works. Free options:
[LibreSprite](https://libresprite.github.io), [Pixelorama](https://orama-interactive.itch.io/pixelorama),
GIMP. [Aseprite](https://www.aseprite.org) is fine too. Load the palette file for what you draw
(see [Palettes](#palettes)) before you start.

## File format
| Rule | Why |
|---|---|
| **PNG, RGBA, at 1× size** (one image pixel = one game pixel) | The app scales up with sharp edges. Never upscale yourself. |
| **Only colors from the palette** | Seasons and avatar colors are swapped by color; a stray shade breaks the swap. `tool/check_art.py` rejects it. |
| **Alpha is 0 or 255, nothing between** | Half-transparent edges look blurry when scaled up. |
| **No anti-aliasing, no gradients, no blur** | Shade with palette steps and dithering instead. |
| **No text in the art** | The app is in English and German; text belongs in the UI. |
| **File names in `snake_case`**, variants numbered from 0 | `tile_forest_0.png`, `tile_forest_1.png`. |

## Sizes
| What | Size | Frames | Folder |
|---|---|---|---|
| Map tile | 16×16 | 1, up to 4 variants | `assets/art/map/` |
| Map landmark (camp, lair, castle) | 16×16 | 1 (lair: `_closed`, `_open`) | `assets/art/map/` |
| UI icon (tabs, coin, heart) | 12×12 | 1 | `assets/art/icons/` |
| Hero | 32×32 | layers, see below | `assets/art/hero/` |
| Hat (shop item) | 32×32 | 1 | `assets/art/hero/` |
| Boss | 48×48 | strip: `idle_0`, `idle_1`, `hit`, `defeated` | `assets/art/bosses/` |
| Chore Overlord | 64×64 | same strip | `assets/art/bosses/` |

A **strip** is one PNG with the frames side by side, left to right in the order given, with no
gaps (a boss strip is 192×48).

## Palettes
Palettes live in `assets/art/palettes/` as GIMP `.gpl` files, which all the editors above can open.

- **`ui_day.gpl`, `ui_night.gpl`**: icons and anything drawn on panels.
- **`map_meadow.gpl`**: draw **every map tile in the meadow palette**. The app swaps each color
  for its partner in `map_autumn.gpl`, `map_snow.gpl` and `map_desert.gpl` (same order, same
  count). So a new tile gets all four seasons for free. If a season needs a new color, add it to
  all four files at the same position.
- **`hero_keys.gpl`**: the hero is drawn with **key colors** (skin, skin shade, hair, hair shade,
  cape, cape shade). The app replaces them with the colors the player picked in the Wardrobe.
  Everything else on the hero (outline, eyes, tool) uses `ui_day.gpl` colors.
- **`bosses.gpl`**: shared outline and shading colors; each boss family adds its own main and
  light color (listed in the file's comments).

Keep a single sprite to **16 colors or fewer**, outline included.

## Drawing rules
1. **Outline:** one pixel, the darkest color of the palette, all the way around. Inner lines may
   use a darker shade of the fill instead of the outline color.
2. **Light from the top left:** highlight on the top and left edges, shade on the bottom and right.
3. **Silhouette first:** every boss must be recognizable as a solid black shape. Color is never
   the only way to tell two things apart (this is an accessibility rule of the whole app).
4. **Both moods:** check the sprite on `#F3E5C3` (day) and `#1C1A30` (night). The outline must
   stay visible on night; if it vanishes, add a lighter rim inside it.
5. **Map tiles tile:** grass, water, sand and paths must join seamlessly with themselves on all
   four sides. Roads and shores are joined by the app; draw only the tile.
6. **Leave a gap at the bottom of bosses:** the bottom 2 pixel rows stay empty for the ground shadow.
7. **Animation is small:** `idle_1` differs from `idle_0` by one or two pixels of bobbing. `hit`
   leans or flashes and must not change the silhouette much. `defeated` lies flat or turns to dust.

## Checking your art
```bash
python tool/check_art.py
```
Checks every PNG under `assets/art/`: size, frame count, palette colors only, alpha 0 or 255.
Then run the app (`flutter run`) and open **Settings → About → Art gallery** (debug builds only).
It shows every sprite at 1×, 2× and 4× on day and night, all map seasons and all boss frames.

## License and credits
Art becomes part of the app, which is GPL-3.0. Contribute only art you made yourself (licensed under
the GPL-3.0, or released as CC0), or CC0 art from elsewhere. Add a line to `assets/art/CREDITS.md`:
file names, author, license and source. No art traced from or "inspired by" a specific existing
game: the look should be our own.
