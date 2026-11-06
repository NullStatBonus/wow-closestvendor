import unittest

import build_vendors as b

META = '''pfDB["meta"] = {
  ["repair"] = {
    [20] = "A",
  },
  ["vendor"] = {
    [10] = "H",
    [20] = "A",
    [30] = "AH",
    [40] = "",
    [50] = "A",
    [60] = "A",
    [70] = "A",
  },
}
'''

UNITS = '''pfDB["units"]["data"] = {
  [5] = {
    ["coords"] = {},
    ["fac"] = "AH",
  },
  [10] = {
    ["coords"] = {
      [1] = { 50.5, 25, 12, 270 },
      [2] = { 10, 10, 12, 270 },
    },
    ["fac"] = "H",
  },
  [15] = {
    ["coords"] = {
      [1] = { 1, 1, 12, 270 },
    },
  },
  [20] = {
    ["coords"] = {
      [1] = { 80, 90.25, 14, 0 },
    },
  },
  [30] = {
    ["coords"] = {},
  },
  [40] = {
    ["coords"] = {
      [1] = { 5, 6, 12, 0 },
    },
  },
  [50] = {
    ["coords"] = {
      [1] = { 5, 6, 999, 0 },
    },
  },
  [60] = {
    ["coords"] = {
      [1] = { 7, 8, 12, 0 },
    },
  },
  [70] = {
    ["coords"] = {
      [1] = { 7, 8, 12, 0 },
    },
  },
}
'''

NAMES = r'''pfDB["units"]["enUS"] = {
  [10] = "Horde Seller",
  [15] = "Not A Vendor",
  [20] = "Remy \"Two Times\" Smith",
  [30] = "No Coords",
  [40] = "Both Factions",
  [50] = "Unmapped Zone",
  [70] = "Normal Seller",
}
'''

ITEMS = '''pfDB["items"]["data"] = {
  [2512] = {
    ["V"] = {
      [10] = 0,
      [20] = 0,
    },
  },
  [2515] = {},
  [2516] = {
    ["V"] = {
      [20] = 0,
      [40] = 0,
    },
  },
  [9999] = {
    ["V"] = {
      [70] = 0,
    },
  },
}
'''

CSV = "UiMapID,AreaID\n37,12\n85,14\n99,0\n"


class Build(unittest.TestCase):
    def run_build(self, **over):
        args = dict(meta=META, units=UNITS, names=NAMES, assignment_csv=CSV, items=ITEMS, source_note="test")
        args.update(over)
        return b.build(**args)

    def test_empty_coords_do_not_steal_next_units_coords(self):
        # unit 30 has `coords = {}`; it must not pick up unit 40's coordinate.
        c = b.parse_first_coords(UNITS, {30, 40})
        self.assertNotIn(30, c)
        self.assertEqual(c[40], (5.0, 6.0, 12))

    def test_only_listed_vendors_kept(self):
        text, _ = self.run_build()
        self.assertNotIn("Not A Vendor", text)  # id 15 is in neither list

    def test_first_coordinate_divided_to_0_1(self):
        text, _ = self.run_build()
        self.assertIn('{10, "Horde Seller", 37, 0.5050, 0.2500, 2, false, 1},', text)

    def test_repair_flag_and_faction(self):
        text, _ = self.run_build()
        self.assertIn('{20, "Remy \\"Two Times\\" Smith", 85, 0.8000, 0.9025, 1, true, 3},', text)
        self.assertIn('{40, "Both Factions", 37, 0.0500, 0.0600, 0, false, 2},', text)

    def test_drops_missing_coords_name_or_map(self):
        text, stats = self.run_build()
        self.assertNotIn("No Coords", text)
        self.assertNotIn("Unmapped Zone", text)
        self.assertNotIn("{60,", text)  # no name
        self.assertEqual((stats["no_coords"], stats["no_map"], stats["no_name"]), (1, 1, 1))
        self.assertEqual(stats["kept"], 4)

    def test_sorted_and_byte_identical(self):
        a, _ = self.run_build()
        c, _ = self.run_build()
        self.assertEqual(a, c)
        ids = [int(l.split("{")[1].split(",")[0]) for l in a.splitlines() if l.startswith("    {")]
        self.assertEqual(ids, sorted(ids))

    def test_any_source_can_use_render(self):
        # A different data source only has to produce normalized records.
        recs = [
            {"id": 9, "name": "From Elsewhere", "map": 2482, "mx": 0.5, "my": 0.25, "faction": 0, "repair": True, "ammo": 3},
            {"id": 3, "name": "Another", "map": 2482, "mx": 0.1, "my": 0.2, "faction": 1, "repair": False, "ammo": 0},
        ]
        text = b.render(recs, "Source: some other dataset")
        self.assertIn("-- Source: some other dataset", text)
        self.assertLess(text.index("{3,"), text.index("{9,"))  # sorted
        self.assertIn('{9, "From Elsewhere", 2482, 0.5000, 0.2500, 0, true, 3},', text)

    def test_render_rejects_bad_records(self):
        ok = {"id": 1, "name": "A", "map": 1, "mx": 0.5, "my": 0.5, "faction": 0, "repair": False, "ammo": 0}
        for bad in ({"mx": 1.5}, {"my": -0.1}, {"faction": 3}, {"ammo": 4}, {"ammo": -1}):
            with self.assertRaises(ValueError):
                b.render([dict(ok, **bad)], "x")
        with self.assertRaises(ValueError):
            b.render([ok, dict(ok)], "x")  # duplicate id

    def test_ammo_codes(self):
        text, _ = self.run_build()
        self.assertIn("37, 0.5050, 0.2500, 2, false, 1}", text)  # 10: arrows only
        self.assertIn("1, true, 3}", text)                       # 20: arrows and bullets
        self.assertIn("0, false, 2}", text)                      # 40: bullets only

    def test_non_ammo_items_do_not_count(self):
        # 70 sells item 9999 (not ammo): listed vendor, no ammo.
        sellers = b.parse_item_sellers(ITEMS, b.ARROWS + b.BULLETS)
        self.assertNotIn(70, sellers)
        self.assertEqual(sellers, {10, 20, 40})

    def test_empty_item_block_does_not_steal_next_items_sellers(self):
        # [2515] = {} is empty and sits between two items with sellers.
        self.assertEqual(b.parse_item_sellers(ITEMS, (2515,)), set())
        self.assertEqual(b.parse_item_sellers(ITEMS, (2516,)), {20, 40})

    def test_ambiguous_area_is_an_error(self):
        with self.assertRaises(ValueError):
            b.area_to_uimap("UiMapID,AreaID\n1,5\n2,5\n")


if __name__ == "__main__":
    unittest.main()
