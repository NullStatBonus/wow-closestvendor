"""The store listing and README must agree with the code on the numbers and commands they quote."""
import os
import re
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def read(*p):
    with open(os.path.join(ROOT, *p), encoding="utf-8") as f:
        return f.read()


class Docs(unittest.TestCase):
    def setUp(self):
        self.listing = read("docs", "listing.md")
        self.readme = read("README.md")
        core = read("ClosestVendor", "Core.lua")
        self.defaults = {k: int(v) for k, v in re.findall(r"(bagThreshold|durThreshold|ammoThreshold|tradeThreshold|reagentThreshold) = (\d+)", core)}

    def test_defaults_are_found(self):
        self.assertEqual(self.defaults, {"bagThreshold": 2, "durThreshold": 20, "ammoThreshold": 200, "tradeThreshold": 10, "reagentThreshold": 5})

    def test_readme_quotes_the_real_defaults(self):
        self.assertIn(f"(default **{self.defaults['bagThreshold']}**)", self.readme)
        self.assertIn(f"(default **{self.defaults['durThreshold']}%**)", self.readme)
        self.assertIn(f"(default **{self.defaults['ammoThreshold']}**)", self.readme)
        self.assertIn(f"(default **{self.defaults['tradeThreshold']}**)", self.readme)
        self.assertIn(f"(default **{self.defaults['reagentThreshold']}**)", self.readme)

    def test_vendor_count_claim_matches_the_data(self):
        n = len(re.findall(r"^    \{\d+, ", read("ClosestVendor", "Data", "Vendors.lua"), re.M))
        self.assertTrue(850 <= n <= 950, n)  # "about 900"
        self.assertIn("about 900", self.listing)
        self.assertIn("about 900", self.readme)

    def test_summary_fits(self):
        row = next(l for l in self.listing.splitlines() if l.startswith("| Summary"))
        summary = row.split("|")[2].strip()
        self.assertLessEqual(len(summary), 250)
        self.assertGreater(len(summary), 100)

    def test_listing_interface_numbers_match_the_tocs(self):
        for name, number in (("Vanilla", "11509"), ("Camelot", "16001")):
            self.assertIn(f"## Interface: {number}", read("ClosestVendor", f"ClosestVendor_{name}.toc"))
            self.assertIn(f"{number} for `ClosestVendor_{name}.toc`", self.listing)

    def test_listed_triggers_and_navigation_match_the_readme(self):
        for word in ("TomTom", "WaypointUI"):
            self.assertIn(word, self.listing, word)
        for word in ("TomTom", "WaypointUI", "Mount Hyjal", "Riverglades", "Zephras Isle", "Darkspear Islands", "Shen'dralas"):
            self.assertIn(word, self.readme, word)


if __name__ == "__main__":
    unittest.main()
