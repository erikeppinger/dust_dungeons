"""Checks the pixel art in assets/art and turns it into Dart code.

The PNG and palette files are the source; lib/app/art/art_data.dart is
generated from them (like the database code), so the app draws its art
synchronously and pixel-exact. See docs/ART_GUIDE.md.

    python tool/build_art.py          # check and regenerate
    python tool/build_art.py --check  # only check; fails if art_data.dart is out of date

Needs Pillow (pip install pillow).
"""

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ART = ROOT / "assets" / "art"
OUT = ROOT / "lib" / "app" / "art" / "art_data.dart"

# Palette index -> character in the generated rows; '.' is transparent.
DIGITS = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"


class ArtError(Exception):
    pass


def camel(name, upper=False):
    parts = re.split(r"[_/]", name)
    s = parts[0] + "".join(p.capitalize() for p in parts[1:])
    return s[0].upper() + s[1:] if upper else s


def read_gpl(path):
    """Returns [(name, (r, g, b))] from a GIMP palette."""
    if not path.exists():
        raise ArtError(f"{path.relative_to(ROOT)}: missing")
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "GIMP Palette":
        raise ArtError(f"{path.name}: not a GIMP palette")
    entries = []
    for line in lines[1:]:
        if not line.strip() or line.startswith("#") or ":" in line.split()[0]:
            continue
        parts = line.split()
        if len(parts) < 4:
            raise ArtError(f"{path.name}: every color needs a name: {line!r}")
        name = parts[3]
        if not re.fullmatch(r"[a-z][a-z0-9_]*", name):
            raise ArtError(f"{path.name}: color name {name!r} must be snake_case")
        entries.append((name, tuple(int(p) for p in parts[:3])))
    return entries


def load_palettes(manifest):
    groups = {}
    for group, spec in manifest["palettes"].items():
        palettes = {v: read_gpl(ART / "palettes" / f"{v}.gpl") for v in spec["variants"]}
        source = palettes[spec["source"]]
        names = [n for n, _ in source]
        if len(source) > len(DIGITS):
            raise ArtError(f"{spec['source']}: more than {len(DIGITS)} colors")
        if len(set(names)) != len(names):
            raise ArtError(f"{spec['source']}: color names must be unique")
        colors = [c for _, c in source]
        if len(set(colors)) != len(colors):
            raise ArtError(
                f"{spec['source']}: every color must be different, so pixels map to one name"
            )
        for v, entries in palettes.items():
            if [n for n, _ in entries] != names:
                raise ArtError(
                    f"{v}.gpl: needs the same color names in the same order as "
                    f"{spec['source']}.gpl"
                )
        groups[group] = (spec, palettes, {c: i for i, c in enumerate(colors)})
    return groups


def sprite_rows(path, w, h, lookup):
    if not path.exists():
        raise ArtError(f"{path.relative_to(ROOT)}: missing")
    img = Image.open(path).convert("RGBA")
    if img.size != (w, h):
        raise ArtError(f"{path.relative_to(ROOT)}: is {img.size[0]}x{img.size[1]}, needs {w}x{h}")
    rows = []
    for y in range(h):
        row = ""
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            if a == 0:
                row += "."
                continue
            if a != 255:
                raise ArtError(
                    f"{path.relative_to(ROOT)}: pixel {x},{y} is half transparent "
                    "(alpha must be 0 or 255)"
                )
            if (r, g, b) not in lookup:
                raise ArtError(
                    f"{path.relative_to(ROOT)}: pixel {x},{y} color #{r:02X}{g:02X}{b:02X} "
                    "is not in its palette"
                )
            row += DIGITS[lookup[(r, g, b)]]
        rows.append(row)
    return rows


def expand(entries):
    """A `folder/*` entry stands for every PNG in that folder, by name."""
    for name, spec in entries.items():
        if name.endswith("/*"):
            folder = name[:-2]
            for png in sorted((ART / folder).glob("*.png")):
                yield f"{folder}/{png.stem}", spec
        else:
            yield name, spec


def load_sprites(manifest, groups):
    sprites = {}
    used = set()
    for name, spec in expand(manifest["sprites"]):
        group = spec["palette"]
        if group not in groups:
            raise ArtError(f"{name}: unknown palette {group!r}")
        w, h = spec["size"]
        frames = spec.get("frames", 1)
        variants = spec.get("variants")
        lookup = groups[group][2]
        files = (
            [ART / f"{name}_{i}.png" for i in range(variants)]
            if variants
            else [ART / f"{name}.png"]
        )
        images = []
        for f in files:
            used.add(f.resolve())
            rows = sprite_rows(f, w * frames, h, lookup)
            # A strip of frames side by side becomes one sprite per frame.
            images += [[r[i * w:(i + 1) * w] for r in rows] for i in range(frames)]
        sprites[name] = (spec, images)
    unused = [
        p.relative_to(ROOT).as_posix()
        for p in ART.rglob("*.png")
        if p.resolve() not in used
    ]
    if unused:
        raise ArtError("not listed in assets/art/art.json: " + ", ".join(sorted(unused)))
    return sprites


def ident_of(name, spec):
    """The Dart name: the file name, after the entry's `prefix` if it has one."""
    stem = name.split("/")[-1]
    return camel(f"{spec['prefix']}_{stem}" if "prefix" in spec else stem)


def hex_color(c):
    return "Color(0xFF%02X%02X%02X)" % c


def generate(groups, sprites):
    out = [
        "// GENERATED by tool/build_art.py from assets/art. Do not edit:",
        "// change the PNG or palette files and run `python tool/build_art.py`.",
        "",
        "part of 'art.dart';",
        "",
    ]
    for group, (spec, palettes, _) in groups.items():
        cls = camel(group, upper=True) + "Palette"
        names = [n for n, _ in palettes[spec["source"]]]
        out += [
            f"/// The {group} palettes; colors in the order of the .gpl files.",
            f"class {cls} {{",
            f"  const {cls}(this.colors);",
            "",
            "  final List<Color> colors;",
            "",
        ]
        for i, n in enumerate(names):
            out.append(f"  Color get {camel(n)} => colors[{i}];")
        out += ["}", ""]
        for v, entries in palettes.items():
            out.append(f"const _{camel(v)} = [")
            out += [f"  {hex_color(c)}, // {n}" for n, c in entries]
            out += ["];", f"const {camel(v)} = {cls}(_{camel(v)});", ""]
    out += ["abstract final class Sprites {"]
    names = {}
    for name, (spec, images) in sprites.items():
        ident = ident_of(name, spec)
        if ident in names:
            raise ArtError(f"{name} and {names[ident]} would have the same name")
        names[ident] = name
        many = spec.get("variants") or spec.get("frames", 1) > 1
        if many:
            out.append(f"  static const {ident} = [")
            for rows in images:
                out.append("    Sprite([")
                out += [f"      '{r}'," for r in rows]
                out.append("    ]),")
            out.append("  ];")
        else:
            out.append(f"  static const {ident} = Sprite([")
            out += [f"    '{r}'," for r in images[0]]
            out.append("  ]);")
        out.append("")
    out += [
        "  /// Every sprite with its palette group, for the art gallery.",
        "  static const all = <String, (List<Sprite>, String)>{",
    ]
    for name, (spec, _) in sprites.items():
        ident = ident_of(name, spec)
        many = spec.get("variants") or spec.get("frames", 1) > 1
        out.append(f"    '{name}': ({ident if many else f'[{ident}]'}, '{spec['palette']}'),")
    out += ["  };", "}", "", "/// Every palette of each group, for the art gallery."]
    out.append("const paletteGroups = <String, Map<String, List<Color>>>{")
    for group, (spec, palettes, _) in groups.items():
        out.append(f"  '{group}': {{")
        out += [f"    '{v}': _{camel(v)}," for v in palettes]
        out.append("  },")
    out += ["};", ""]
    return "\n".join(out)


def dart_format(code):
    """Formats like `dart format`, so formatting lib/ leaves the file as is."""
    dart = shutil.which("dart")
    if dart is None:
        raise ArtError("dart not found: install Flutter and put it on the PATH")
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "art_data.dart"
        path.write_text(code, encoding="utf-8", newline="\n")
        subprocess.run([dart, "format", str(path)], check=True, capture_output=True)
        return path.read_text(encoding="utf-8")


def main():
    check = "--check" in sys.argv
    try:
        manifest = json.loads((ART / "art.json").read_text(encoding="utf-8"))
        groups = load_palettes(manifest)
        sprites = load_sprites(manifest, groups)
        code = dart_format(generate(groups, sprites))
    except ArtError as e:
        print(f"Art error: {e}", file=sys.stderr)
        return 1
    count = sum(len(images) for _, images in sprites.values())
    if check:
        current = OUT.read_text(encoding="utf-8") if OUT.exists() else ""
        if current != code:
            print("lib/app/art/art_data.dart is out of date: run python tool/build_art.py",
                  file=sys.stderr)
            return 1
        print(f"Art OK: {count} sprites, {len(groups)} palette groups.")
        return 0
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(code, encoding="utf-8", newline="\n")
    print(f"Wrote {OUT.relative_to(ROOT).as_posix()}: {count} sprites, "
          f"{len(groups)} palette groups.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
