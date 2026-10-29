# Art guide

How to draw art for Homework & Chores so it fits the 16-bit look and works in the app.
For how the art gets into the code, see [design/art-assets.md](design/art-assets.md).

> **Status (0.7.2):** the icons, map tiles and launcher shield are PNG files in `assets/art`.
> The hero and the bosses are still drawn in Dart code; they are waiting to be redrawn as
> sprites (step 5 of the plan). That is a good first job for an art contributor.

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
| **Only colors from the palette** | Seasons and day/night are swapped by color; a stray shade breaks the swap. `tool/build_art.py` rejects it. |
| **Alpha is 0 or 255, nothing between** | Half-transparent edges look blurry when scaled up. |
| **No anti-aliasing, no gradients, no blur** | Shade with palette steps and dithering instead. |
| **No text in the art** | The app is in English and German; text belongs in the UI. |
| **File names in `snake_case`**, variants numbered from 0 | `grass_0.png` … `grass_3.png`. |

## What there is
Every sprite is listed in **`assets/art/art.json`** with its size, palette group and number of
variants. A new sprite needs a line there.

| What | Size | Palette | Files |
|---|---|---|---|
| Tab icons | 12×12 | `mask` | `icons/tab_*.png`. One color: draw in black, the app tints them. |
| Coin, hearts | 12×12 | `ui` | `icons/coin.png`, `icons/heart.png`, `icons/heart_empty.png` |
| Launcher icon | 16×16 | `app` | `icons/app_shield.png`; run `python tool/generate_icon.py` after changing it |
| Ground tiles | 16×16 | `map` | `map/grass_0..3`, `map/water_0..3`, `map/sand_0..3`: fill the whole tile |
| Overlays | 16×16 | `map` | `map/forest_0..1`, `map/hill`, `map/mountain`: transparent background, drawn on grass |
| Bridges | 16×16 | `map` | `map/bridge_across`, `map/bridge_along`: drawn on water |
| Landmarks | 16×16 | `map` | `map/camp`, `map/lair`, `map/lair_sign` (on unexplored lairs), `map/castle`, `map/castle_won` |
| Hero *(planned)* | 32×32 | `hero` | layers, recolored with the Wardrobe colors |
| Boss *(planned)* | 48×48 (Overlord 64×64) | `bosses` | a strip of frames: `idle_0`, `idle_1`, `hit`, `defeated` |

A **strip** is one PNG with the frames side by side, left to right, with no gaps (a boss strip is
192×48). `art.json` gives the frame count as `"frames": 4`.

Drawn by the app, not as files: roads (they join to their neighbours), foam on the shores, fog of
war, the seam where the season changes between weeks, the small "plain" map in the Hall of Fame,
and the frames and bars of the UI.

## Palettes
Palettes live in `assets/art/palettes/` as GIMP `.gpl` files, which all the editors above can
open. Every color has a name; the app uses the names, so keep them when you change a color.

- **`map_meadow.gpl`**: draw **every map sprite in the meadow palette**. The app paints it in
  `map_autumn.gpl`, `map_snow.gpl` or `map_desert.gpl` by swapping each color for the one at the
  same position. So a new tile gets all four seasons for free. A new color goes into all four
  files at the same position (shared colors like `rock` are simply the same in all four).
- **`ui_day.gpl`**: draw the coin and hearts with it; `ui_night.gpl` is their night version.
- **`mask.gpl`**: one color, for tab icons.
- **`app.gpl`**: the launcher shield.
- *(planned)* **`hero_keys.gpl`**: the hero is drawn with key colors (skin, hair, cape, each with a
  shade) that the app replaces with the player's choices. **`bosses.gpl`**: outline and shading
  shared by all bosses.

Within the source palette of a group (meadow, day) every color must be different, so each pixel
maps to exactly one name. Keep a single sprite to **16 colors or fewer**, outline included.

## Drawing rules
1. **Outline:** one pixel, the darkest color of the palette, all the way around. Inner lines may
   use a darker shade of the fill instead of the outline color.
2. **Light from the top left:** highlight on the top and left edges, shade on the bottom and right.
3. **Silhouette first:** every boss must be recognizable as a solid black shape. Color is never
   the only way to tell two things apart (this is an accessibility rule of the whole app).
4. **Both moods:** check the sprite on `#F3E5C3` (day) and `#1C1A30` (night). The outline must
   stay visible on night; if it vanishes, add a lighter rim inside it.
5. **Map tiles tile:** ground tiles must join seamlessly with themselves and each other on all
   four sides. Variants of one tile should differ in small details only, so no pattern stands out.
6. **Leave a gap at the bottom of bosses:** the bottom 2 pixel rows stay empty for the ground shadow.
7. **Animation is small:** `idle_1` differs from `idle_0` by one or two pixels of bobbing. `hit`
   leans or flashes and must not change the silhouette much. `defeated` lies flat or turns to dust.

## Checking your art
```bash
python tool/build_art.py
```
(Needs Python with Pillow: `pip install pillow`, and Flutter on the PATH.) It checks every PNG
against `art.json` and the palettes, with errors naming the file and pixel, then regenerates
`lib/app/art/art.g.dart`. **Commit the PNGs and the generated file together.** `flutter test`
fails if they don't match.

Then run the app in debug mode (`flutter run`) and open **Settings → About → Art gallery**.
It shows every sprite in every palette of its group, on day and night, at 1×, 2× and 4×.

## License and credits
Art becomes part of the app, which is GPL-3.0. Contribute only art you made yourself (licensed under
the GPL-3.0, or released as CC0), or CC0 art from elsewhere. Add a line to `assets/art/CREDITS.md`:
file names, author, license and source. No art traced from or "inspired by" a specific existing
game: the look should be our own.
