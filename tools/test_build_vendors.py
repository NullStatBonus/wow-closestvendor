import unittest

import build_vendors as b

META = '''pfDB["meta"] = {
  ["repair"] = {
    [20] = "A",
  },
  ["auctioneer"] = {
    [80] = "AH",
    [81] = "A",
    [82] = "H",
    [83] = "A",
    [84] = "A",
    [85] = "A",
    [86] = "A",
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
  [80] = {
    ["coords"] = {
      [1] = { 30, 40.5, 12, 0 },
    },
  },
  [81] = {
    ["coords"] = {
      [1] = { 10, 20, 14, 0 },
    },
  },
  [82] = {
    ["coords"] = {
      [1] = { 60, 70, 12, 0 },
    },
  },
  [83] = {
    ["coords"] = {},
  },
  [84] = {
    ["coords"] = {
      [1] = { 1, 2, 999, 0 },
    },
  },
  [86] = {
    ["coords"] = {
      [1] = { 3, 4, 12, 0 },
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
  [80] = "Neutral Auctioneer",
  [81] = "Alliance Auctioneer",
  [82] = "Horde Auctioneer",
  [83] = "No Coords Auctioneer",
  [84] = "Unmapped Auctioneer",
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
  [17020] = {
    ["V"] = {
      [10] = 0,
      [20] = 0,
    },
  },
  [17032] = {
    ["V"] = {
      [20] = 0,
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
        self.assertIn('{10, "Horde Seller", 37, 0.5050, 0.2500, 2, false, 1, 1},', text)

    def test_repair_flag_and_faction(self):
        text, _ = self.run_build()
        self.assertIn('{20, "Remy \\"Two Times\\" Smith", 85, 0.8000, 0.9025, 1, true, 3, 5},', text)
        self.assertIn('{40, "Both Factions", 37, 0.0500, 0.0600, 0, false, 2, 0},', text)

    def test_drops_missing_coords_name_or_map(self):
        text, stats = self.run_build()
        self.assertNotIn("No Coords", text)
        self.assertNotIn("Unmapped Zone", text)
        self.assertNotIn("{60,", text)  # no name
        self.assertEqual((stats["no_coords"], stats["no_map"], stats["no_name"]), (1, 1, 1))
        self.assertEqual(stats["kept"], 4)  # 80-84 are not in the vendor lists

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
        self.assertIn('{9, "From Elsewhere", 2482, 0.5000, 0.2500, 0, true, 3, 0},', text)

    def test_render_rejects_bad_records(self):
        ok = {"id": 1, "name": "A", "map": 1, "mx": 0.5, "my": 0.5, "faction": 0, "repair": False, "ammo": 0}
        for bad in ({"mx": 1.5}, {"my": -0.1}, {"faction": 3}, {"ammo": 4}, {"ammo": -1}):
            with self.assertRaises(ValueError):
                b.render([dict(ok, **bad)], "x")
        with self.assertRaises(ValueError):
            b.render([ok, dict(ok)], "x")  # duplicate id

    def test_ammo_codes(self):
        text, _ = self.run_build()
        self.assertIn("37, 0.5050, 0.2500, 2, false, 1, 1}", text)  # 10: arrows only
        self.assertIn("1, true, 3, 5}", text)                       # 20: arrows and bullets
        self.assertIn("0, false, 2, 0}", text)                      # 40: bullets only

    def test_non_ammo_items_do_not_count(self):
        # 70 sells item 9999 (not ammo): listed vendor, no ammo.
        sellers = b.parse_item_sellers(ITEMS, b.ARROWS + b.BULLETS)
        self.assertNotIn(70, sellers)
        self.assertEqual(sellers, {10, 20, 40})

    def test_empty_item_block_does_not_steal_next_items_sellers(self):
        # [2515] = {} is empty and sits between two items with sellers.
        self.assertEqual(b.parse_item_sellers(ITEMS, (2515,)), set())
        self.assertEqual(b.parse_item_sellers(ITEMS, (2516,)), {20, 40})

    def test_reagent_mask(self):
        # 10 sells Arcane Powder (bit 0); 20 also Rune of Portals (bit 2); 40 sells neither.
        text, stats = self.run_build()
        self.assertIn('{10, "Horde Seller", 37, 0.5050, 0.2500, 2, false, 1, 1},', text)
        self.assertIn("1, true, 3, 5},", text)
        self.assertIn('{40, "Both Factions", 37, 0.0500, 0.0600, 0, false, 2, 0},', text)
        self.assertNotIn("Arcane Powder", stats["reagents_without_seller"])
        self.assertIn("Flash Powder", stats["reagents_without_seller"])  # no seller in the fixture

    def test_reagent_table_is_read_from_the_addon_file(self):
        table = b.load_reagents()
        self.assertEqual(dict((i, bit) for i, bit, _ in table)[17020], 0)
        self.assertEqual(len({bit for _, bit, _ in table}), len(table))

    def test_render_rejects_bad_reagent_mask(self):
        ok = {"id": 1, "name": "A", "map": 1, "mx": 0.5, "my": 0.5, "faction": 0, "repair": False, "ammo": 0}
        for bad in (-1, 1 << 30, "x"):
            with self.assertRaises(ValueError):
                b.render([dict(ok, reagents=bad)], "x")
        self.assertIn("false, 0, 7},", b.render([dict(ok, reagents=7)], "x"))

    def test_auctioneers_written(self):
        text, stats = self.run_build()
        self.assertIn("ns.ShippedAuctioneers = {", text)
        self.assertIn('{80, "Neutral Auctioneer", 37, 0.3000, 0.4050, 0},', text)  # neutral: both factions
        self.assertIn('{81, "Alliance Auctioneer", 85, 0.1000, 0.2000, 1},', text)
        self.assertIn('{82, "Horde Auctioneer", 37, 0.6000, 0.7000, 2},', text)
        self.assertEqual(stats["auctioneers"], 3)

    def test_auctioneers_without_coords_name_or_map_dropped(self):
        text, _ = self.run_build()
        for name in ("No Coords Auctioneer", "Unmapped Auctioneer"):
            self.assertNotIn(name, text)
        self.assertNotIn("{86,", text)  # no name
        self.assertNotIn("{85,", text)  # listed, but no unit record at all
        # vendors are not auctioneers, and the other way round
        self.assertNotIn("{80, \"Neutral Auctioneer\", 37, 0.3000, 0.4050, 0, false", text)
        self.assertNotIn("Horde Seller", text.split("ns.ShippedAuctioneers")[1])

    def test_auctioneers_byte_identical_and_sorted(self):
        a, _ = self.run_build()
        c, _ = self.run_build()
        self.assertEqual(a, c)
        part = a.split("ns.ShippedAuctioneers = {")[1]
        ids = [int(l.split("{")[1].split(",")[0]) for l in part.splitlines() if l.startswith("    {")]
        self.assertEqual(ids, sorted(ids))
        self.assertEqual(len(ids), 3)

    def test_render_rejects_bad_auctioneers(self):
        ok = {"id": 1, "name": "A", "map": 1, "mx": 0.5, "my": 0.5, "faction": 0}
        for bad in ({"mx": 1.5}, {"my": -0.1}, {"faction": 3}):
            with self.assertRaises(ValueError):
                b.render_auctioneers([dict(ok, **bad)])
        with self.assertRaises(ValueError):
            b.render_auctioneers([ok, dict(ok)])

    def test_reagent_table_ignores_display_only(self):
        ids = [i for i, _, _ in b.load_reagents()]
        for display in (6265, 5530, 5349, 5350):
            self.assertNotIn(display, ids)

    def test_ambiguous_area_is_an_error(self):
        with self.assertRaises(ValueError):
            b.area_to_uimap("UiMapID,AreaID\n1,5\n2,5\n")


if __name__ == "__main__":
    unittest.main()
