"""Tests for tool/build_game_data.py: broken data must fail with a clear message.

    python -m unittest tool/test_build_game_data.py
"""

import copy
import json
import sys
import tomllib
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_game_data as g  # noqa: E402


def load(name):
    data = tomllib.loads((g.GAME / f"{name}.toml").read_text(encoding="utf-8"))
    schema = json.loads((g.GAME / "schema" / f"{name}.json").read_text(encoding="utf-8"))
    return data, schema


class GameDataTest(unittest.TestCase):
    def setUp(self):
        self.items, self.item_schema = load("items")
        self.bosses, self.boss_schema = load("bosses")
        self.quests, self.quest_schema = load("quests")
        self.balance, self.balance_schema = load("balance")
        self.boss_names = g.dart_enum("lib/domain/fight/boss.dart", "BossFamily")

    def fails(self, check, message):
        with self.assertRaises(g.DataError) as e:
            check()
        self.assertIn(message, str(e.exception))

    def check_items(self, items):
        data = {"items": items}
        g.validate(data, self.item_schema, self.item_schema, "game/items.toml")
        g.check_items(items, self.boss_names)

    def test_the_real_data_passes(self):
        self.check_items(self.items["items"])
        g.check_bosses(self.bosses["bosses"], self.boss_names)
        g.check_quests(self.quests["quests"])
        g.check_balance(self.balance)

    def test_unknown_effect(self):
        items = copy.deepcopy(self.items["items"])
        items["turbo_mop"]["effects"]["laser_beam"] = 1
        self.fails(lambda: self.check_items(items), "unknown field 'laser_beam'")

    def test_missing_icon(self):
        items = copy.deepcopy(self.items["items"])
        items["golden_mop"] = {"slot": "weapon", "price": 10,
                               "name": {"en": "Golden Mop", "de": "Goldener Mopp"},
                               "effects": {"damage": 1}}
        self.fails(lambda: self.check_items(items), "assets/art/items/golden_mop.png")

    def test_missing_german(self):
        items = copy.deepcopy(self.items["items"])
        del items["turbo_mop"]["name"]["de"]
        self.fails(lambda: self.check_items(items), "missing 'de'")

    def test_price_and_boss(self):
        items = copy.deepcopy(self.items["items"])
        items["turbo_mop"]["dropped_by"] = "dust"
        self.fails(lambda: self.check_items(items), "either a price")

    def test_braces_in_text(self):
        items = copy.deepcopy(self.items["items"])
        items["turbo_mop"]["name"]["en"] = "Turbo {Mop}"
        self.fails(lambda: self.check_items(items), "no { or }")

    def test_two_handed_shield(self):
        items = copy.deepcopy(self.items["items"])
        items["sponge_shield"]["two_handed"] = True
        self.fails(lambda: self.check_items(items), "only weapons can be two-handed")

    def test_boss_without_loot(self):
        items = copy.deepcopy(self.items["items"])
        items["trash_can_lid"]["retired"] = True
        self.fails(lambda: self.check_items(items), "the trash boss drops nothing")

    def test_hat_looks_without_gaps(self):
        items = copy.deepcopy(self.items["items"])
        items["hat_crown"]["look"] = 7
        self.fails(lambda: self.check_items(items), "without gaps")

    def test_unknown_quest_icon(self):
        quests = copy.deepcopy(self.quests["quests"])
        quests["dusting"]["icon"] = "rocket_launch_x"
        self.fails(lambda: g.check_quests(quests), "rocket_launch_x")

    def test_quest_points_in_steps_of_five(self):
        quests = copy.deepcopy(self.quests["quests"])
        quests["dusting"]["points"] = 17
        self.fails(lambda: g.check_quests(quests), "steps of 5")

    def test_missing_boss(self):
        bosses = copy.deepcopy(self.bosses["bosses"])
        del bosses["trash"]
        self.fails(lambda: g.check_bosses(bosses, self.boss_names), "missing [bosses.trash]")

    def test_slot_curse_needs_slot(self):
        bosses = copy.deepcopy(self.bosses["bosses"])
        del bosses["kitchen"]["curse"]["slot"]
        self.fails(lambda: g.check_bosses(bosses, self.boss_names), "needs a slot")

    def test_timing_perfect_narrower_than_good(self):
        balance = copy.deepcopy(self.balance)
        balance["timing"]["normal"] = [120, 60]
        self.fails(lambda: g.check_balance(balance), "perfect must be narrower")

    def test_removed_key(self):
        keys = {("item", k) for k in self.items["items"] if k != "turbo_mop"}
        keys |= {("boss", k) for k in self.bosses["bosses"]}
        keys |= {("quest", k) for k in self.quests["quests"]}
        self.fails(lambda: g.check_lock(keys), "item turbo_mop")

    def test_schema_enums_match_the_code(self):
        self.fails(lambda: g.same_values("x", ["a", "b"], ["a"]), "update the schema or the code")


if __name__ == "__main__":
    unittest.main()
