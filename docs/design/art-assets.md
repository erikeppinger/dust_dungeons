# Art as files (0.7.2)

**Goal:** someone who draws pixel art, but does not write Dart, can add or change the app's art.
The drawing rules are in [ART_GUIDE.md](../ART_GUIDE.md); this document covers the code side and
the order of work.

## Where the art was before (0.7.1)
| Art | Where | How it's drawn | Editable by an artist? |
|---|---|---|---|
| Tab icons, coin, hearts | `lib/app/theme/pixel.dart` (`PixelArt`) | Text grids (`'.kkyyyyyykk.'`) | Barely: it's a code file |
| Quest map tiles, camp, lair, castle | `lib/features/world/quest_map.dart` (`_grass`, `_forest`, …) | Pixel by pixel in Dart, seasons from `_Palette` | No |
| Bosses (8 + Overlord) | `lib/features/fight/boss_art.dart` | Smooth vector shapes, **not pixel art** | No |
| Hero and hats | `lib/features/fight/hero_art.dart` | Smooth vector shapes, **not pixel art** | No |
| Launcher icon, splash | `tool/generate_icon.py` | Text grid → PNG and vector | Barely |
| Frames, bars, badges | `lib/app/theme/pixel.dart` | Geometry (`PixelBorder`, `PixelBar`) | Not art: stays code |

The hero and bosses still look like 0.5.0: they predate the 16-bit look and stand out next to it.

## Layout (as built)
```
assets/art/
  art.json    every sprite: size, palette group, variants or frames
  palettes/   map_meadow.gpl (source)  map_autumn.gpl  map_snow.gpl  map_desert.gpl
              ui_day.gpl (source)  ui_night.gpl  mask.gpl  app.gpl
  icons/      tab_*.png  coin.png  heart.png  heart_empty.png  app_shield.png
  map/        grass_0..3  water_0..3  sand_0..3  forest_0..1  hill  mountain
              bridge_across  bridge_along  camp  lair  lair_sign  castle  castle_won
  CREDITS.md
lib/app/art/
  art.dart          Sprite: paints one sprite in a palette (recorded once, then replayed)
  art_data.dart        GENERATED: palettes and sprites as Dart constants
  art_gallery.dart  debug-only screen showing every sprite on day and night
tool/build_art.py   checks assets/art and writes art_data.dart (--check: only check)
```

## How the code uses the files
**Decision: the PNGs are the source, turned into Dart at build time.** `tool/build_art.py`
reads every PNG listed in `art.json` and checks:
- the size, frame count and variant count
- that every color is in the group's source palette
- that alpha is 0 or 255
- that every color name matches across the palettes of a group
- that no PNG is left unlisted

It then writes `art_data.dart` (deliberately not `*.g.dart`, which `build_runner` deletes as its own), where each sprite is a list of rows with one character per pixel,
holding the palette index. This works like Drift's generated code, and it was chosen over
decoding PNGs at runtime:
- **Drawing stays synchronous:** widgets and painters draw a sprite like before, with no
  loading state.
- **No test changes:** widget tests need no `runAsync` image decoding.
- **Nothing extra in the APK:** the PNGs are not bundled.
- **Readable diffs:** each changed pixel shows up in the generated file.

- **Palette swap:** a sprite is painted with any palette of its group. The index in each row picks
  the color, so meadow tiles become autumn, snow or desert, and the coin and hearts follow day and
  night. Each (sprite, palette) pair is recorded once into a `Picture` and replayed after that.
- **Generated palette classes** (`MapPalette`, `UiPalette`, …) have one getter per color name.
  They replace the old `_Palette` class in `quest_map.dart` and the color fields of `PixelColors`.
- **What stays in code:**
  - map generation, roads, shore foam, fog of war, seam dithering between weeks, and the plain map
  - which tile variant goes where (picked from the tile position, so maps never flicker)
  - frames, bars and badges
  - the hero on the map, until step 5
- **Accessibility does not change:** sprites stay `ExcludeSemantics` with the same labels on
  the widgets around them.

## Tests
- `test/art_test.dart` decodes every PNG with `dart:ui` and checks the generated rows and palettes
  match. So a forgotten `build_art.py` run fails `flutter test`, even without Python.
- `python tool/build_art.py --check` does the same from Python, and later CI can run it.
- The move was checked by eye: the icons and all single tiles (hill, mountain, bridges and
  landmarks) were exported from the old code pixel for pixel. Grass, water and sand now use four
  fixed variants instead of random detail per tile, so the maps look the same in style but not
  pixel for pixel.

## Order of work
1. ✅ Infrastructure: `art.json`, palettes, `build_art.py`, `Sprite`, the gallery (0.7.2).
2. ✅ Icons from files (0.7.2).
3. ✅ Map tiles and landmarks from files (0.7.2).
4. ✅ Launcher icon: `generate_icon.py` reads `icons/app_shield.png` (0.7.2).
5. **Hero and bosses, redrawn as pixel sprites.** This is new art, not a conversion.
   - ✅ The hero, with its gear as layers and the `hero` palette group (0.13.0,
     [design](fight-feedback.md)).
   - ✅ The bosses, as strips of four frames in the `bosses` palette group (0.13.0). All are
     48×48, the Overlord too.
   - ✅ Also from files since 0.13.0: the trophy, the level coin and the quest icons.
6. ✅ Docs: the art guide and CONTRIBUTING updated (0.7.2).

## Open questions (answered)
- **Who redraws hero and bosses (step 5)?** We did, in 0.13.0.
- **Animate idle bosses everywhere?** No: bosses only move in fights, where they bob on the beats
  of their call. Elsewhere they show the idle frame, so no timers run.
