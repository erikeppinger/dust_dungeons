# Art as files (0.7.2) — migration plan

**Goal:** someone who draws pixel art, but does not write Dart, can add or change the app's art.
The drawing rules are in [ART_GUIDE.md](../ART_GUIDE.md); this document covers the code side and
the order of work.

## Where the art is today (0.7.1)
| Art | Where | How it's drawn | Editable by an artist? |
|---|---|---|---|
| Tab icons, coin, hearts | `lib/app/theme/pixel.dart` (`PixelArt`) | Text grids (`'.kkyyyyyykk.'`) | Barely: it's a code file |
| Quest map tiles, camp, lair, castle | `lib/features/world/quest_map.dart` (`_grass`, `_forest`, …) | Pixel by pixel in Dart, seasons from `_Palette` | No |
| Bosses (8 + Overlord) | `lib/features/fight/boss_art.dart` | Smooth vector shapes, **not pixel art** | No |
| Hero and hats | `lib/features/fight/hero_art.dart` | Smooth vector shapes, **not pixel art** | No |
| Launcher icon, splash | `tool/generate_icon.py` | Text grid → PNG and vector | Barely |
| Frames, bars, badges | `lib/app/theme/pixel.dart` | Geometry (`PixelBorder`, `PixelBar`) | Not art: stays code |

The hero and bosses still look like 0.5.0: they predate the 16-bit look and stand out next to it.

## Target layout
```
assets/art/
  palettes/   ui_day.gpl  ui_night.gpl  map_meadow.gpl  map_autumn.gpl  map_snow.gpl
              map_desert.gpl  hero_keys.gpl  bosses.gpl
  icons/      tab_quests.png  tab_quest_log.png  …  coin.png  heart.png  heart_empty.png
  map/        tile_grass_0..3.png  tile_forest_0..3.png  tile_hill_*.png  tile_mountain_*.png
              tile_water_*.png  tile_sand_*.png  tile_path.png  tile_bridge.png
              camp.png  lair_closed.png  lair_open.png  castle.png
  hero/       hero_base.png  hat_<id>.png
  bosses/     boss_dust.png  …  boss_overlord.png      (frame strips)
  CREDITS.md
lib/app/art/
  sprites.dart        names of all sprites, sizes and frame counts (one table)
  sprite_cache.dart   loads PNGs, swaps palettes, caches ui.Image per (sprite, palette)
  art_gallery.dart    debug-only screen showing every sprite on day and night
tool/check_art.py     validates assets against the table and palettes
```

## How the code uses the files
- **Loading:** PNGs are decoded once with `dart:ui` and kept as `ui.Image`, then drawn with
  `drawImageRect` and `FilterQuality.none` (sharp pixels). Screens load only what they show.
  That's under 100 files of a few hundred bytes each, so startup time does not change.
- **Palette swap:** recoloring works on the raw RGBA bytes. Each color in the source palette is
  mapped to the same position in the target palette, then the bytes become a `ui.Image` again
  (`decodeImageFromPixels`), cached per (sprite, palette). This handles:
  - the four map seasons, from tiles drawn once in meadow colors
  - the hero's skin, hair and cape from the Wardrobe (replacing today's `avatarSkins` / `avatarHair` / `avatarCapes` color lists)
- **What stays in code:**
  - map generation, routing, fog of war, seam dithering between weeks, and the plain (simplified) map
  - layout and animation timing
  - frames, bars and badges
  - which tile variant goes where (from the existing week seed, so maps stay the same)
- **Accessibility does not change:** sprites stay `ExcludeSemantics` with the same labels on
  the widgets around them.

## Tests
- **`tool/check_art.py`** (for contributors, and later in CI): checks every sprite listed in
  `sprites.dart` for the right size and frame count, palette colors only, alpha 0 or 255, and
  that no PNG in the folder is unused.
- **`test/art_test.dart`** checks the same table from the Dart side: every listed asset exists and
  decodes to the listed size, and the palette swap maps every source color.
- **Golden comparison for the move:** a test renders a fixed week map and the tab icons before and
  after the move and compares the pixels. Icons and tiles are exported from today's code, so the
  first step must change nothing visible.
- The accessibility audit and the integration test run as usual.

## Order of work
1. **Infrastructure:** the sprite table, cache, palette swap, `check_art.py` and the debug gallery.
   Export today's Dart colors into the `.gpl` palettes.
2. **Icons:** a script turns the `PixelArt` grids into PNGs, and the code switches to the files.
   The goldens must match.
3. **Map:** a script renders each tile type once from today's painter (four variants where tiles
   have random detail), in meadow colors. `WeekPainter` switches to drawing tiles from the cache.
   The goldens must match except for variant choice.
4. **Launcher icon:** `generate_icon.py` reads `icons/app_shield.png` instead of its grid.
5. **Hero and bosses, redrawn as pixel sprites:** this is new art, not a conversion, so it's the
   biggest step and the natural first job for an art contributor. It can ship later (0.7.3) without
   blocking steps 1–4: until a sprite exists, the current vector painter is used as the fallback.
6. **Docs:** ART_GUIDE status note removed; ARCHITECTURE and CONTRIBUTING updated.

## Open questions
- Should step 5 (redrawing hero and bosses) be done by us in 0.7.2, or left for 0.7.3 or for a contributor?
- An animated `idle` (two frames) costs a timer per boss on screen. Fine for the Arena list?
  The alternative is to animate only in fights.
