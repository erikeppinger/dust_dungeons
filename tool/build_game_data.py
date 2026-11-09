"""Checks the game data in game/*.toml and turns it into Dart code and texts.

The TOML files are the source (see game/README.md); generated from them are
lib/game/game_data.dart (the catalog as constants), lib/game/game_texts.dart
(the lookups for names and icons) and the game's texts in lib/l10n/*.arb.

    python tool/build_game_data.py          # check and regenerate (also the art)
    python tool/build_game_data.py --check  # only check; fails if anything is out of date

Needs Python 3.11+ (tomllib) and Pillow for the art build.
"""

import json
import re
import shutil
import subprocess
import sys
import tempfile
import tomllib
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
DATA_OUT = ROOT / "lib" / "game" / "game_data.dart"
TEXTS_OUT = ROOT / "lib" / "game" / "game_texts.dart"
ARB = {"en": ROOT / "lib/l10n/app_en.arb", "de": ROOT / "lib/l10n/app_de.arb"}
LOCK = GAME / "keys.lock"
OVERLORD_ART = ROOT / "assets" / "art" / "bosses" / "overlord"
BOSS_ART = ROOT / "assets" / "art" / "bosses"
PART_KINDS = ("body", "face", "hat", "item", "extra")
TRAIT_FIELDS = ("bpm", "beats", "offbeat", "eighth", "lanes")
GENERATED = "Generated from game/"

# Effects in the order of the Dart `Effects` class: TOML name -> Dart name.
EFFECTS = {
    "hearts": "hearts",
    "damage": "damage",
    "good_damage": "goodDamage",
    "perfect_times": "perfectTimes",
    "free_misses": "freeMisses",
    "wide_timing": "wideTiming",
    "combo_heal": "comboHeal",
    "sneak_attack": "sneakAttack",
    "slower_boss": "slowerBoss",
    "third_miss_free": "thirdMissFree",
    "full_revive": "fullRevive",
    "loot_bonus": "lootBonus",
}
USES = {"revive": "ItemUse.revive", "lift_curse": "ItemUse.liftCurse"}
CURSE_KINDS = {"heart": "CurseKind.heart", "tight_timing": "CurseKind.tightTiming",
               "slot_off": "CurseKind.slotOff"}
REPEATS = {"anytime": "anytime", "daily": "daily", "after_done": "afterDone"}


class DataError(Exception):
    pass


def camel(name, upper=False):
    parts = name.split("_")
    s = parts[0] + "".join(p[:1].upper() + p[1:] for p in parts[1:])
    return s[:1].upper() + s[1:] if upper else s


# ---------------------------------------------------------------- schema --

def validate(value, schema, root, where):
    """A small JSON Schema subset: enough for the files in game/schema."""
    if "$ref" in schema:
        ref = schema["$ref"]
        target = root
        for part in ref.removeprefix("#/").split("/"):
            target = target[part]
        validate(value, target, root, where)
    if "enum" in schema and value not in schema["enum"]:
        raise DataError(f"{where}: {value!r} is not one of {', '.join(map(str, schema['enum']))}")
    kind = schema.get("type")
    checks = {
        "object": lambda v: isinstance(v, dict),
        "string": lambda v: isinstance(v, str),
        "integer": lambda v: isinstance(v, int) and not isinstance(v, bool),
        "number": lambda v: isinstance(v, (int, float)) and not isinstance(v, bool),
        "boolean": lambda v: isinstance(v, bool),
        "array": lambda v: isinstance(v, list),
    }
    kinds = kind if isinstance(kind, list) else [kind] if kind else []
    if kinds and not any(checks[k](value) for k in kinds):
        raise DataError(f"{where}: needs a {' or '.join(kinds)}, not {value!r}")
    kind = kind if isinstance(kind, str) else None
    if kind in ("integer", "number"):
        if "minimum" in schema and value < schema["minimum"]:
            raise DataError(f"{where}: {value} is below {schema['minimum']}")
        if "maximum" in schema and value > schema["maximum"]:
            raise DataError(f"{where}: {value} is above {schema['maximum']}")
    if kind == "string" and len(value) < schema.get("minLength", 0):
        raise DataError(f"{where}: may not be empty")
    if kind == "string" and "pattern" in schema and not re.fullmatch(schema["pattern"], value):
        raise DataError(f"{where}: {value!r} doesn't match {schema['pattern']}")
    if kind == "array":
        if not schema.get("minItems", 0) <= len(value) <= schema.get("maxItems", 1 << 30):
            raise DataError(f"{where}: needs {schema.get('minItems')} to {schema.get('maxItems')} values")
        for i, v in enumerate(value):
            validate(v, schema.get("items", {}), root, f"{where}[{i}]")
    if kind == "object":
        for req in schema.get("required", []):
            if req not in value:
                raise DataError(f"{where}: missing {req!r}")
        props = schema.get("properties", {})
        names = schema.get("propertyNames")
        for k, v in value.items():
            if names:
                if "pattern" in names and not re.fullmatch(names["pattern"], k):
                    raise DataError(f"{where}: key {k!r} must be snake_case (a-z, 0-9, _)")
                if "enum" in names and k not in names["enum"]:
                    raise DataError(f"{where}: {k!r} is not one of {', '.join(names['enum'])}")
            if k in props:
                validate(v, props[k], root, f"{where}.{k}")
            elif isinstance(schema.get("additionalProperties"), dict):
                validate(v, schema["additionalProperties"], root, f"{where}.{k}")
            elif schema.get("additionalProperties") is False:
                known = ", ".join(props) or "nothing"
                raise DataError(f"{where}: unknown field {k!r} (known: {known})")


def load(name):
    path = GAME / f"{name}.toml"
    try:
        data = tomllib.loads(path.read_text(encoding="utf-8"))
    except tomllib.TOMLDecodeError as e:
        raise DataError(f"game/{name}.toml: {e}") from e
    schema = json.loads((GAME / "schema" / f"{name}.json").read_text(encoding="utf-8"))
    validate(data, schema, schema, f"game/{name}.toml")
    return data, schema


def dart_enum(path, name):
    src = (ROOT / path).read_text(encoding="utf-8")
    m = re.search(r"enum " + name + r" \{(.*?)\}", src, re.S)
    if not m:
        raise DataError(f"{path}: enum {name} not found")
    body = re.sub(r"//.*", "", m.group(1))
    return [v.strip() for v in body.split(",") if v.strip()]


def same_values(where, schema_values, dart_values):
    if set(schema_values) != set(dart_values):
        raise DataError(f"{where} lists {sorted(schema_values)}, but the code has "
                        f"{sorted(dart_values)}: update the schema or the code")


# ---------------------------------------------------------------- checks --

def texts_in(value, where):
    """Yields (where, en, de) for every text in an item/boss/quest."""
    for k, v in value.items():
        if isinstance(v, dict) and set(v) == {"en", "de"}:
            for lang in ("en", "de"):
                if "{" in v[lang] or "}" in v[lang]:
                    raise DataError(f"{where}.{k}.{lang}: no {{ or }} in texts")
            yield k, v
        elif isinstance(v, dict):
            yield from texts_in(v, f"{where}.{k}")


def check_items(items, bosses_all):
    looks = []
    uses = {}
    for key, it in items.items():
        w = f"game/items.toml: [items.{key}]"
        kind = it.get("kind", "gear")
        if kind == "gear":
            if "slot" not in it:
                raise DataError(f"{w}: gear needs a slot")
            if ("price" in it) == ("dropped_by" in it):
                raise DataError(f"{w}: gear needs either a price (Armory) or dropped_by (loot)")
            for f in ("use", "minutes", "look", "before_fight", "description"):
                if f in it:
                    raise DataError(f"{w}: {f!r} isn't for gear")
            if it.get("two_handed") and it["slot"] != "weapon":
                raise DataError(f"{w}: only weapons can be two-handed")
            if not it.get("effects") and not it.get("against"):
                raise DataError(f"{w}: gear needs effects")
        else:
            for f in ("slot", "two_handed", "dropped_by", "against"):
                if f in it:
                    raise DataError(f"{w}: {f!r} is only for gear")
            if "price" not in it:
                raise DataError(f"{w}: needs a price")
        if kind == "consumable":
            if "use" in it:
                if it.get("effects") or it.get("before_fight"):
                    raise DataError(f"{w}: a consumable with a use has no effects")
                if "description" not in it:
                    raise DataError(f"{w}: a consumable with a use needs a description")
                uses.setdefault(it["use"], []).append(key)
            elif not it.get("effects") or not it.get("before_fight"):
                raise DataError(f"{w}: a consumable needs a use, or effects and before_fight = true")
        elif any(f in it for f in ("use", "before_fight")):
            raise DataError(f"{w}: use and before_fight are only for consumables")
        if kind == "voucher":
            if "minutes" not in it or "name" in it:
                raise DataError(f"{w}: a voucher has minutes and no name (its name says the minutes)")
        elif "minutes" in it:
            raise DataError(f"{w}: minutes are only for vouchers")
        elif "name" not in it:
            raise DataError(f"{w}: needs a name")
        if kind == "hat":
            if "look" not in it:
                raise DataError(f"{w}: a hat needs its look number")
            looks.append(it["look"])
        elif "look" in it:
            raise DataError(f"{w}: look is only for hats")
        if "description" in it and it.get("effects"):
            raise DataError(f"{w}: items with effects get their description from them")
        if kind in ("gear", "consumable"):
            icon = ROOT / "assets" / "art" / "items" / f"{key}.png"
            if not icon.exists():
                raise DataError(f"{w}: needs an icon at assets/art/items/{key}.png")
        if kind in ("gear", "hat") and not it.get("retired"):
            wear = ROOT / "assets" / "art" / "hero" / "wear" / f"{key}.png"
            if not wear.exists():
                raise DataError(
                    f"{w}: needs its look on the hero at assets/art/hero/wear/{key}.png"
                )
        list(texts_in(it, w))
    if sorted(looks) != list(range(1, len(looks) + 1)):
        raise DataError(f"game/items.toml: hat looks must be 1, 2, 3 … without gaps, not {sorted(looks)}")
    for use in USES:
        if len(uses.get(use, [])) != 1:
            raise DataError(f"game/items.toml: exactly one consumable needs use = {use!r}")
    for boss in bosses_all:
        if not any(it.get("dropped_by") == boss and not it.get("retired") for it in items.values()):
            raise DataError(f"game/items.toml: the {boss} boss drops nothing; give it a loot item")


def check_bosses(bosses, all_bosses):
    for b in all_bosses:
        if b not in bosses:
            raise DataError(f"game/bosses.toml: missing [bosses.{b}]")
    for key, boss in bosses.items():
        w = f"game/bosses.toml: [bosses.{key}]"
        if key == "overlord":
            if "forms" in boss:
                raise DataError(f"{w}: the Overlord has weekly looks, not forms")
        else:
            if "forms" not in boss:
                raise DataError(f"{w}: needs two [[bosses.{key}.forms]], for tier 2 and 3")
            for tier in (2, 3):
                art = BOSS_ART / "forms" / f"{key}_{tier}.png"
                if not art.exists():
                    raise DataError(f"{w}: form {tier} has no drawing "
                                    f"assets/art/bosses/forms/{key}_{tier}.png")
        if not (BOSS_ART / f"{key}.png").exists() and key != "overlord":
            raise DataError(f"{w}: has no drawing assets/art/bosses/{key}.png")
        if (key == "overlord") == ("fed_by" in boss):
            raise DataError(f"{w}: every boss but the Overlord needs fed_by")
        if (boss["curse"]["kind"] == "slot_off") != ("slot" in boss["curse"]):
            raise DataError(f"{w}: a slot_off curse needs a slot, and only it")
        list(texts_in(boss, w))


def check_quests(quests):
    icons_src = (ROOT / "lib/features/chores/chore_icons.dart").read_text(encoding="utf-8")
    icons = set(re.findall(r"^\s*'(\w+)': Sprites\.", icons_src, re.M))
    for key, q in quests.items():
        w = f"game/quests.toml: [quests.{key}]"
        if q["points"] % 5:
            raise DataError(f"{w}: points go in steps of 5 (the editor's slider)")
        if q["icon"] not in icons:
            raise DataError(f"{w}: icon {q['icon']!r} isn't in lib/features/chores/chore_icons.dart")
        list(texts_in(q, w))


def check_balance(b):
    w = "game/balance.toml"
    t2, t3 = b["bosses"]["tier_wins"]
    if not 0 < t2 < t3:
        raise DataError(f"{w}: [bosses] tier_wins must grow: tier 2 before tier 3")
    for name in ("hearts", "damage"):
        g = b["hero"][name]
        if g["min"] > g["max"]:
            raise DataError(f"{w}: [hero.{name}] min is above max")
    for name, (perfect, good) in b["timing"].items():
        if perfect >= good:
            raise DataError(f"{w}: [timing] {name}: perfect must be narrower than good")
    if b["points"]["min_base"] > b["points"]["max_base"]:
        raise DataError(f"{w}: [points] min_base is above max_base")


def check_overlords(o):
    w = "game/overlords.toml"
    parts = o["parts"]
    for kind, keys in parts.items():
        if len(set(keys)) != len(keys):
            raise DataError(f"{w}: [parts] {kind} lists a key twice")
    for scheme in parts["scheme"]:
        if scheme not in o["schemes"]:
            raise DataError(f"{w}: [parts] scheme {scheme!r} has no [schemes] entry")
    for body in parts["body"]:
        if body not in o["traits"]:
            raise DataError(f"{w}: body {body!r} needs [traits.{body}]")
    for key in o["traits"]:
        if key not in parts["body"]:
            raise DataError(f"{w}: [traits.{key}] is for no body in [parts]")
    sizes = {**{k: len(v) for k, v in parts.items()},
             "name": len(o["names"]), "title": len(o["titles"])}
    previous = None
    for era in o["eras"]:
        where = f"{w}: [[eras]] {era['from']}"
        try:
            monday = date.fromisoformat(era["from"])
        except ValueError as e:
            raise DataError(f"{where}: {e}") from e
        if monday.weekday() != 0:
            raise DataError(f"{where}: must be a Monday")
        for kind, size in sizes.items():
            if era[kind] > size:
                raise DataError(f"{where}: {kind} = {era[kind]}, but there are only {size}")
            if previous and era[kind] < previous[kind]:
                raise DataError(f"{where}: {kind} may only grow from one era to the next")
        if previous:
            if monday <= date.fromisoformat(previous["from"]):
                raise DataError(f"{where}: eras must be in order")
            if all(era[k] == previous[k] for k in sizes):
                raise DataError(f"{where}: changes nothing")
        previous = era
    for key, h in o["holidays"].items():
        where = f"{w}: [holidays.{key}]"
        if ("day" in h) == ("dates" in h):
            raise DataError(f"{where}: needs either day or dates")
        if h.get("day", "easter") not in ("easter", "hanukkah"):
            month, day = map(int, h["day"].split("-"))
            try:
                date(2024, month, day)
            except ValueError as e:
                raise DataError(f"{where}: day {h['day']!r}: {e}") from e
        days = []
        for text in h.get("dates", []):
            try:
                days.append(date.fromisoformat(text))
            except ValueError as e:
                raise DataError(f"{where}: date {text!r}: {e}") from e
        if days != sorted(set(days)):
            raise DataError(f"{where}: dates must be in order, each once")
        if h["scheme"] not in o["schemes"]:
            raise DataError(f"{where}: scheme {h['scheme']!r} has no [schemes] entry")
        for effect in h["boon"]:
            if effect not in EFFECTS:
                raise DataError(f"{where}: boon {effect!r} is not an effect "
                                f"({', '.join(EFFECTS)})")
    for kind, key in overlord_art_keys(o):
        if not (OVERLORD_ART / kind / f"{key}.png").exists():
            raise DataError(f"{w}: {kind} {key!r} has no drawing "
                            f"assets/art/bosses/overlord/{kind}/{key}.png")


def overlord_art_keys(o):
    """(kind, key) of every part that needs a drawing."""
    keys = {(kind, k) for kind in PART_KINDS for k in o["parts"][kind]}
    for h in o["holidays"].values():
        keys |= {("hat", h["hat"]), ("item", h["item"]), ("extra", h["extra"])}
    return sorted(keys)


def check_lock(keys):
    if not LOCK.exists():
        return []
    gone = []
    for line in LOCK.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        kind, key = line.split()
        if (kind, key) not in keys:
            gone.append(f"{kind} {key}")
    if gone:
        raise DataError("these keys were shipped and are stored on phones; they can't go away "
                        "(set `retired = true` for an item instead): " + ", ".join(gone))


# -------------------------------------------------------------- generate --

def dart_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return repr(v)
    if isinstance(v, list):
        return "[" + ", ".join(dart_value(x) for x in v) + "]"
    return str(v)


def effects_code(effects):
    if not effects:
        return "Effects.none"
    args = [f"{EFFECTS[k]}: {dart_value(effects[k])}" for k in EFFECTS if k in effects]
    return "Effects(" + ", ".join(args) + ")"


def ident(key):
    return camel(key) + "Item"


def color_int(hex_color):
    return "0xFF" + hex_color[1:].upper()


def generate_overlords(o):
    out = ["", "// ---- Overlords (game/overlords.toml) ----", ""]
    lists = {"body": "overlordBodies", "face": "overlordFaces", "hat": "overlordHats",
             "item": "overlordItems", "extra": "overlordExtras", "scheme": "overlordSchemeOrder"}
    for kind, name in lists.items():
        keys = ", ".join(f"'{k}'" for k in o["parts"][kind])
        out.append(f"const {name} = <String>[{keys}];")
    out += ["", "const overlordEras = <OverlordEra>["]
    for era in o["eras"]:
        y, m, d = map(int, era["from"].split("-"))
        counts = ", ".join(str(era[k]) for k in ("body", "face", "hat", "item", "extra", "scheme"))
        out.append(f"  OverlordEra({y}, {m}, {d}, parts: [{counts}], "
                   f"names: {era['name']}, titles: {era['title']}),")
    out += ["];", "", "/// Main and light color by scheme.",
            "const overlordSchemes = <String, (int, int)>{"]
    for key, sc in o["schemes"].items():
        out.append(f"  '{key}': ({color_int(sc['main'])}, {color_int(sc['light'])}),")
    out += ["};", "", "/// How each body plays.", "const overlordTraits = <String, BossTrait>{"]
    for key, t in o["traits"].items():
        args = ", ".join(
            f"{f}: {dart_value(float(t[f]) if f in ('offbeat', 'eighth', 'lanes') else t[f])}"
            for f in TRAIT_FIELDS if f in t)
        out.append(f"  '{key}': BossTrait({args}),")
    out += ["};", "", "const overlordHolidays = <String, OverlordHoliday>{"]
    for key, h in o["holidays"].items():
        if "dates" in h:
            days = ", ".join("({}, {}, {})".format(*map(int, t.split("-"))) for t in h["dates"])
            day = f"dates: [{days}]"
        elif h["day"] in ("easter", "hanukkah"):
            day = f"{h['day']}: true"
        else:
            month, d = map(int, h["day"].split("-"))
            day = f"month: {month}, day: {d}"
        out.append(f"  '{key}': OverlordHoliday({day}, hat: '{h['hat']}', item: '{h['item']}', "
                   f"extra: '{h['extra']}', scheme: '{h['scheme']}', "
                   f"boon: {effects_code(h['boon'])}),")
    out += ["};", "", "/// How many days a holiday boon lasts.",
            f"const overlordBoonDays = {o['boons']['days']};", ""]
    return out


def generate_data(items, bosses, quests, balance, overlords):
    out = [
        "// GENERATED by tool/build_game_data.py from game/*.toml. Do not edit:",
        "// change the TOML files and run `python tool/build_game_data.py`.",
        "",
        "import '../domain/default_chores.dart';",
        "import '../domain/fight/boss.dart';",
        "import '../domain/fight/difficulty.dart';",
        "import '../domain/fight/echo_duel.dart';",
        "import '../domain/fight/items.dart';",
        "import '../domain/fight/overlord.dart';",
        "import '../domain/fight/shop.dart';",
        "import '../domain/recurrence.dart';",
        "",
        "// ---- Items (game/items.toml) ----",
        "",
    ]
    for key, it in items.items():
        kind = it.get("kind", "gear")
        dart_kind = {"gear": "gear", "consumable": "consumable", "hat": "hat",
                     "voucher": "consumable"}[kind]
        args = [f"'{key}'", f"ItemKind.{dart_kind}", str(it.get("price", 0))]
        if "slot" in it:
            args.append(f"slot: GearSlot.{it['slot']}")
        if it.get("two_handed"):
            args.append("twoHanded: true")
        if "dropped_by" in it:
            args.append(f"dropsFrom: BossFamily.{it['dropped_by']}")
        if it.get("effects"):
            args.append(f"effects: {effects_code(it['effects'])}")
        if it.get("against"):
            general = it.get("effects", {})
            entries = ", ".join(
                f"BossFamily.{b}: {effects_code({**general, **e})}" for b, e in it["against"].items()
            )
            args.append(f"against: {{{entries}}}")
        if "use" in it:
            args.append(f"use: {USES[it['use']]}")
        if kind == "voucher":
            args.append("use: ItemUse.screenMinutes")
            args.append(f"minutes: {it['minutes']}")
        if it.get("before_fight"):
            args.append("beforeFight: true")
        if "look" in it:
            args.append(f"look: {it['look']}")
        if it.get("retired"):
            args.append("retired: true")
        out.append(f"const {ident(key)} = ShopItem({', '.join(args)});")

    def listing(name, doc, keys):
        out.extend(["", f"/// {doc}", f"const {name} = <ShopItem>["] +
                   [f"  {ident(k)}," for k in keys] + ["];"])

    live = {k: it for k, it in items.items() if not it.get("retired")}
    gear = [k for k, it in items.items() if it.get("kind", "gear") == "gear"]
    listing("armoryGear", "Gear sold in the Armory.",
            [k for k in gear if k in live and "price" in items[k]])
    boss_order = list(bosses)
    listing("lootItems", "Gear that bosses drop, by boss.",
            sorted((k for k in gear if k in live and "dropped_by" in items[k]),
                   key=lambda k: boss_order.index(items[k]["dropped_by"])))
    listing("allGear", "All gear, retired too (owners keep it).", gear)
    listing("fightConsumables", "Consumables for fights, sold in the Armory.",
            [k for k, it in live.items() if it.get("kind") == "consumable"])
    listing("preFightConsumables", "Consumables picked on a fight's start screen.",
            [k for k, it in live.items() if it.get("before_fight")])
    listing("screenVouchers", "Screen-time vouchers.",
            [k for k, it in live.items() if it.get("kind") == "voucher"])
    listing("hats", "Hats by their look number (1, 2, …).",
            sorted((k for k, it in items.items() if it.get("kind") == "hat"),
                   key=lambda k: items[k]["look"]))
    listing("shopItems", "Everything that can be owned.", list(items))
    for use, name in (("revive", "reviveItem"), ("lift_curse", "curseLiftItem")):
        key = next(k for k, it in items.items() if it.get("use") == use)
        out += ["", f"const {name} = {ident(key)};"]

    out += ["", "// ---- Bosses (game/bosses.toml) ----", "",
            "const bossStyles = <BossFamily, BossStyle>{"]
    for key, boss in bosses.items():
        t = boss["tempo"]
        out.append(f"  BossFamily.{key}: BossStyle(baseBpm: {t['bpm']}, "
                   f"offbeatChance: {float(t['offbeat'])!r}, eighthChance: {float(t['eighth'])!r}),")
    out += ["};", "", "/// Forms at tier 2 and 3 (chore bosses).",
            "const bossForms = <BossFamily, List<BossForm>>{"]
    for key, boss in bosses.items():
        if "forms" not in boss:
            continue
        forms = []
        for f in boss["forms"]:
            args = ", ".join(
                f"{k}: {dart_value(float(f[k]) if k in ('offbeat', 'eighth') else f[k])}"
                for k in ("bpm", "beats", "offbeat", "eighth") if k in f)
            trait = f", trait: BossTrait({args})" if args else ""
            forms.append(f"BossForm(main: {color_int(f['main'])}, "
                         f"light: {color_int(f['light'])}{trait})")
        out.append(f"  BossFamily.{key}: [{', '.join(forms)}],")
    out += ["};", "", "const bossCurses = <BossFamily, Curse>{"]
    for key, boss in bosses.items():
        c = boss["curse"]
        slot = f", GearSlot.{c['slot']}" if "slot" in c else ""
        out.append(f"  BossFamily.{key}: Curse(BossFamily.{key}, {CURSE_KINDS[c['kind']]}{slot}),")
    out += ["};", ""]

    out += ["// ---- Built-in quests (game/quests.toml) ----", "",
            "const defaultChores = <SeedChore>["]
    for key, q in quests.items():
        r = q["repeat"]
        ctor = "SeedChore.suggestion" if q.get("suggested") else "SeedChore"
        out.append(f"  {ctor}('{key}', '{q['icon']}', {q['color']}, {q['points']}, "
                   f"RepeatType.{REPEATS[r['type']]}, {r.get('every', 1)}),")
    out += ["];", "", "/// The boss each built-in quest feeds.",
            "const seedFamilies = <String, BossFamily>{"]
    out += [f"  '{key}': BossFamily.{q['boss']}," for key, q in quests.items()]
    out += ["};", ""]

    out += ["// ---- Balance (game/balance.toml) ----", ""]
    for section in ("hero", "bosses", "loot", "rounds", "curses", "points"):
        for name, value in balance[section].items():
            if isinstance(value, dict):
                for sub, v in value.items():
                    out.append(f"const {camel(section + '_' + name + '_' + sub)} = {dart_value(v)};")
            else:
                out.append(f"const {camel(section + '_' + name)} = {dart_value(value)};")
    for name, (perfect, good) in balance["timing"].items():
        out.append(f"const {camel('timing_' + name)} = "
                   f"TimingWindows(perfectMs: {perfect}, goodMs: {good});")
    out += ["", "const difficultyPresets = <Difficulty, DifficultyPreset>{"]
    for name, p in balance["difficulty"].items():
        out.append(f"  Difficulty.{name}: DifficultyPreset(bossHealth: {float(p['boss_health'])!r}, "
                   f"timingMs: {p['timing_ms']}, tempo: {float(p['tempo'])!r}),")
    out += ["};"]
    out += generate_overlords(overlords)
    return "\n".join(out)


def generate_texts(items, bosses, quests, overlords):
    """The lookups and the ARB entries: {arb key: (source file, {lang: text})}."""
    arb = {}
    item_names, item_descs, item_flavors, sprites = [], [], [], []
    for key, it in items.items():
        c = camel(key, upper=True)
        if "name" in it:
            arb[f"gameItem{c}"] = ("items", it["name"])
            item_names.append(f"  '{key}' => l.gameItem{c},")
        if "description" in it:
            arb[f"gameItem{c}Desc"] = ("items", it["description"])
            item_descs.append(f"  '{key}' => l.gameItem{c}Desc,")
        if "flavor" in it:
            arb[f"gameItem{c}Flavor"] = ("items", it["flavor"])
            item_flavors.append(f"  '{key}' => l.gameItem{c}Flavor,")
        if it.get("kind", "gear") in ("gear", "consumable"):
            sprites.append(f"  '{key}' => Sprites.{camel(key)},")
    boss_names, fed_by, trophies, curses, form_names = [], [], [], [], []
    for key, boss in bosses.items():
        c = camel(key, upper=True)
        arb[f"gameBoss{c}"] = ("bosses", boss["name"])
        boss_names.append(f"  BossFamily.{key} => l.gameBoss{c},")
        arb[f"gameCurse{c}"] = ("bosses", boss["curse"]["name"])
        curses.append(f"  BossFamily.{key} => l.gameCurse{c},")
        if "fed_by" in boss:
            arb[f"gameBoss{c}FedBy"] = ("bosses", boss["fed_by"])
            fed_by.append(f"  BossFamily.{key} => l.gameBoss{c}FedBy,")
        if "trophy" in boss:
            arb[f"gameBoss{c}Trophy"] = ("bosses", boss["trophy"])
            trophies.append(f"  BossFamily.{key} => l.gameBoss{c}Trophy,")
        for tier, form in enumerate(boss.get("forms", []), start=2):
            arb[f"gameBoss{c}Form{tier}"] = ("bosses", form["name"])
            form_names.append(f"  (BossFamily.{key}, {tier}) => l.gameBoss{c}Form{tier},")
    quest_titles = []
    for key, q in quests.items():
        c = camel(key, upper=True)
        arb[f"gameQuest{c}"] = ("quests", q["title"])
        quest_titles.append(f"  '{key}' => l.gameQuest{c},")

    names, titles = [], []
    for i, t in enumerate(overlords["names"]):
        arb[f"gameOverlordName{i}"] = ("overlords", t)
        names.append(f"  {i} => l.gameOverlordName{i},")
    for i, t in enumerate(overlords["titles"]):
        arb[f"gameOverlordTitle{i}"] = ("overlords", t)
        titles.append(f"  {i} => l.gameOverlordTitle{i},")
    traits, trait_descs = [], []
    for key, t in overlords["traits"].items():
        c = camel(key, upper=True)
        arb[f"gameOverlordTrait{c}"] = ("overlords", t["name"])
        arb[f"gameOverlordTrait{c}Desc"] = ("overlords", t["description"])
        traits.append(f"  '{key}' => l.gameOverlordTrait{c},")
        trait_descs.append(f"  '{key}' => l.gameOverlordTrait{c}Desc,")
    holidays, holiday_trophies, holiday_settings = [], [], []
    for key, h in overlords["holidays"].items():
        c = camel(key, upper=True)
        arb[f"gameHoliday{c}"] = ("overlords", h["name"])
        arb[f"gameHoliday{c}Trophy"] = ("overlords", h["trophy"])
        arb[f"gameHoliday{c}Setting"] = ("overlords", h["setting"])
        holidays.append(f"  '{key}' => l.gameHoliday{c},")
        holiday_trophies.append(f"  '{key}' => l.gameHoliday{c}Trophy,")
        holiday_settings.append(f"  '{key}' => l.gameHoliday{c}Setting,")

    def lookup(doc, sig, cases, exhaustive=False):
        return [f"/// {doc}", f"{sig} => switch (key) {{"] + cases + \
            ([] if exhaustive else ["  _ => null,"]) + ["};", ""]

    out = [
        "// GENERATED by tool/build_game_data.py from game/*.toml. Do not edit:",
        "// change the TOML files and run `python tool/build_game_data.py`.",
        "",
        "import '../app/art/art.dart';",
        "import '../domain/fight/boss.dart';",
        "import '../l10n/app_localizations.dart';",
        "",
    ]
    out += lookup("An item's name, by key.",
                  "String? gameItemName(AppLocalizations l, String key)", item_names)
    out += lookup("The written description of an item without effects.",
                  "String? gameItemDescription(AppLocalizations l, String key)", item_descs)
    out += lookup("An item's optional fun line.",
                  "String? gameItemFlavor(AppLocalizations l, String key)", item_flavors)
    out += lookup("An item's pixel icon.", "Sprite? gameItemSprite(String key)", sprites)
    out += lookup("A boss's name.", "String gameBossName(AppLocalizations l, BossFamily key)",
                  boss_names, exhaustive=True)
    out += lookup("Which quests feed a boss.",
                  "String? gameBossFedBy(AppLocalizations l, BossFamily key)", fed_by)
    out += lookup("A boss's own trophy name, if it has one.",
                  "String? gameBossTrophy(AppLocalizations l, BossFamily key)", trophies)
    out += ["/// A boss's name in its form at [tier] (2 or 3).",
            "String? gameBossFormName(AppLocalizations l, BossFamily key, int tier) =>",
            "    switch ((key, tier)) {"] + form_names + ["  _ => null,", "};", ""]
    out += lookup("The name of a boss's curse.",
                  "String gameCurseName(AppLocalizations l, BossFamily key)", curses,
                  exhaustive=True)
    out += lookup("A built-in quest's title, by seed key.",
                  "String? gameQuestTitle(AppLocalizations l, String key)", quest_titles)
    out += lookup("An Overlord's name, by number.",
                  "String? gameOverlordName(AppLocalizations l, int key)", names)
    out += lookup("An Overlord's title, by number.",
                  "String? gameOverlordTitle(AppLocalizations l, int key)", titles)
    out += lookup("The name of an Overlord body's trait.",
                  "String? gameOverlordTrait(AppLocalizations l, String key)", traits)
    out += lookup("What an Overlord body's trait does.",
                  "String? gameOverlordTraitDescription(AppLocalizations l, String key)",
                  trait_descs)
    out += lookup("A holiday Overlord's name.",
                  "String? gameHolidayName(AppLocalizations l, String key)", holidays)
    out += lookup("A holiday Overlord's trophy.",
                  "String? gameHolidayTrophy(AppLocalizations l, String key)", holiday_trophies)
    out += lookup("A holiday, as the settings name it.",
                  "String? gameHolidaySetting(AppLocalizations l, String key)", holiday_settings)
    return "\n".join(out), arb


def updated_arb(path, lang, entries):
    """The ARB file with the generated entries replaced; hand-written ones stay."""
    data = json.loads(path.read_text(encoding="utf-8"))
    ours = {k[1:] for k, v in data.items()
            if k.startswith("@") and isinstance(v, dict)
            and str(v.get("description", "")).startswith(GENERATED)}
    kept = {k: v for k, v in data.items() if k not in ours and k.lstrip("@") not in ours}
    for key in entries:
        if key in kept:
            raise DataError(f"{path.name}: {key!r} is written by hand; remove it, the tool owns it")
    for key, (source, text) in entries.items():
        kept[key] = text[lang]
        kept[f"@{key}"] = {"description": f"{GENERATED}{source}.toml"}
    return json.dumps(kept, ensure_ascii=False, indent=2) + "\n"


def dart_format(files):
    dart = shutil.which("dart")
    if dart is None:
        raise DataError("dart not found: install Flutter and put it on the PATH")
    with tempfile.TemporaryDirectory() as tmp:
        paths = []
        for name, code in files.items():
            p = Path(tmp) / name
            p.write_text(code, encoding="utf-8", newline="\n")
            paths.append(str(p))
        subprocess.run([dart, "format", *paths], check=True, capture_output=True)
        return {name: (Path(tmp) / name).read_text(encoding="utf-8") for name in files}


def build():
    items_data, item_schema = load("items")
    bosses_data, boss_schema = load("bosses")
    quests_data, _ = load("quests")
    balance, balance_schema = load("balance")
    overlords, _ = load("overlords")
    items, bosses, quests = items_data["items"], bosses_data["bosses"], quests_data["quests"]

    boss_values = dart_enum("lib/domain/fight/boss.dart", "BossFamily")
    same_values("game/schema/bosses.json",
                boss_schema["properties"]["bosses"]["propertyNames"]["enum"], boss_values)
    same_values("game/schema/items.json (slot)",
                item_schema["$defs"]["item"]["properties"]["slot"]["enum"],
                dart_enum("lib/domain/fight/shop.dart", "GearSlot"))
    same_values("game/schema/balance.json (difficulty)",
                list(balance_schema["properties"]["difficulty"]["properties"]),
                dart_enum("lib/domain/fight/difficulty.dart", "Difficulty"))
    repeat_values = dart_enum("lib/domain/recurrence.dart", "RepeatType")
    for name in REPEATS.values():
        if name not in repeat_values:
            raise DataError(f"RepeatType.{name} is gone from lib/domain/recurrence.dart")

    check_items(items, boss_values)
    check_bosses(bosses, boss_values)
    check_quests(quests)
    check_balance(balance)
    check_overlords(overlords)
    keys = {("item", k) for k in items} | {("boss", k) for k in bosses} | \
        {("quest", k) for k in quests} | \
        {(f"overlord_{kind}", k) for kind, k in overlord_art_keys(overlords)} | \
        {("overlord_scheme", k) for k in overlords["schemes"]} | \
        {("overlord_holiday", k) for k in overlords["holidays"]} | \
        {("overlord_era", e["from"]) for e in overlords["eras"]}
    check_lock(keys)

    data = generate_data(items, bosses, quests, balance, overlords)
    texts, arb_entries = generate_texts(items, bosses, quests, overlords)
    formatted = dart_format({"game_data.dart": data, "game_texts.dart": texts})
    lock = "# Every key ever shipped; written by tool/build_game_data.py.\n" + \
        "".join(f"{kind} {key}\n" for kind, key in sorted(keys))
    return {
        DATA_OUT: formatted["game_data.dart"],
        TEXTS_OUT: formatted["game_texts.dart"],
        ARB["en"]: updated_arb(ARB["en"], "en", arb_entries),
        ARB["de"]: updated_arb(ARB["de"], "de", arb_entries),
        LOCK: lock,
    }, len(items), len(bosses), len(quests)


def main():
    check = "--check" in sys.argv
    art = [sys.executable, str(ROOT / "tool" / "build_art.py")] + (["--check"] if check else [])
    if subprocess.run(art).returncode != 0:
        return 1
    try:
        outputs, n_items, n_bosses, n_quests = build()
    except DataError as e:
        print(f"Game data error: {e}", file=sys.stderr)
        return 1
    stale = [p for p, text in outputs.items()
             if not p.exists() or p.read_text(encoding="utf-8") != text]
    summary = f"{n_items} items, {n_bosses} bosses, {n_quests} quests"
    if check:
        if stale:
            names = ", ".join(p.relative_to(ROOT).as_posix() for p in stale)
            print(f"Out of date: {names}. Run python tool/build_game_data.py", file=sys.stderr)
            return 1
        print(f"Game data OK: {summary}.")
        return 0
    for p in stale:
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(outputs[p], encoding="utf-8", newline="\n")
    print(f"Game data: {summary}; wrote {len(stale)} file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
