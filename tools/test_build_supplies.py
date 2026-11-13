import os
import tempfile
import unittest

import build_supplies as b

NAMES = {1: "Food", 2: "Drink", 3: "Minor Healthstone", 4: "Healthstone", 5: "Other"}
ITEMS = {117, 159, 5512, 5509, 5510, 5511, 9421, 4540, 729, *range(19004, 19014)}
EFFECTS = [(117, 1), (4540, 1), (159, 2), (5512, 3), (5509, 4), (5510, 4), (5511, 4), (9421, 4), (729, 5)] + \
          [(i, 4) for i in range(19004, 19014)]

FAMILIES = {4: 252, 1: 4}


class BuildSupplies(unittest.TestCase):
    def test_kinds_and_diets(self):
        mask = b.build(EFFECTS, NAMES, ITEMS, [(4540, "Bread", "Tough Hunk of Bread"), (729, "Meat", "Stringy Wolf Meat")])
        self.assertEqual(mask[117], b.FOOD)
        self.assertEqual(mask[159], b.WATER)
        self.assertEqual(mask[4540], b.FOOD | b.DIET_BIT["Bread"])  # food and a pet diet
        self.assertEqual(mask[729], b.DIET_BIT["Meat"])  # diet only (raw meat has no use spell)
        self.assertEqual(mask[5512], b.HEALTHSTONE)

    def _forever(self, d, item_rows, types="Name_lang,ID\nMeat,1\nFish,2\nCheese,3\nBread,4\nFungus,5\nFruit,6\n\"Raw Meat\",7\n"):
        fl = os.path.join(d, "forever")
        os.makedirs(fl)
        with open(os.path.join(fl, "ItemPetFood.csv"), "w") as f:
            f.write(types)
        with open(os.path.join(fl, "Item.csv"), "w") as f:
            f.write("ID,ClassID,ItemPetFoodID\n" + item_rows)
        with open(os.path.join(fl, "ItemSparse.csv"), "w") as f:
            f.write("ID,Display_lang\n117,Tough Jerky\n414,Dalaran Sharp\n729,Stringy Vulture Meat\n4540,Tough Hunk of Bread\n")

    def test_diets_come_from_the_client_item_table(self):
        with tempfile.TemporaryDirectory() as d:
            self._forever(d, "117,0,1\n414,0,3\n729,0,7\n4540,0,4\n5,0,0\n999999,0,2\n")
            diets = b.load_diets(d)
        self.assertEqual(sorted(diets), [(117, "Meat", "Tough Jerky"), (414, "Cheese", "Dalaran Sharp"),
                                         (4540, "Bread", "Tough Hunk of Bread")])
        # 729 is Raw Meat (removed type), 5 has no diet, 999999 has no ItemSparse row: all left out

    def test_unknown_pet_food_type_fails_and_names_the_item(self):
        with tempfile.TemporaryDirectory() as d:
            self._forever(d, "117,0,9\n")
            with self.assertRaisesRegex(ValueError, "item 117: pet food type 9"):
                b.load_diets(d)

    def test_no_diets_fails(self):
        with tempfile.TemporaryDirectory() as d:
            self._forever(d, "117,0,0\n")
            with self.assertRaisesRegex(ValueError, "no pet diets"):
                b.load_diets(d)

    def test_diet_item_unknown_to_client_fails(self):
        with self.assertRaisesRegex(ValueError, "item 999999"):
            b.build(EFFECTS, NAMES, ITEMS, [(999999, "Meat", "Nothing")])

    def test_missing_healthstone_fails(self):
        with self.assertRaisesRegex(ValueError, "healthstone"):
            b.build([(117, 1)], NAMES, ITEMS, [])

    def test_render_is_sorted_and_deterministic(self):
        mask = {159: 2, 117: 1}
        out = b.render(mask, FAMILIES)
        self.assertEqual(out, b.render(dict(reversed(list(mask.items()))), FAMILIES))
        self.assertLess(out.index("[117]"), out.index("[159]"))

    def test_family_diets_read_the_game_bit_order(self):
        with tempfile.TemporaryDirectory() as d:
            os.makedirs(os.path.join(d, "era"))
            with open(os.path.join(d, "era", "CreatureFamily.csv"), "w") as f:
                f.write("ID,Name_lang,PetFoodMask\n1,Wolf,1\n2,Cat,3\n10,Moth,0\n21,Turtle,178\n")
            fam = b.load_families(("era",), d)
        self.assertEqual(fam[1], b.DIET_BIT["Meat"])
        self.assertEqual(fam[2], b.DIET_BIT["Meat"] | b.DIET_BIT["Fish"])
        self.assertNotIn(10, fam)  # eats nothing
        self.assertEqual(fam[21], b.DIET_BIT["Fish"] | b.DIET_BIT["Fungus"] | b.DIET_BIT["Fruit"])  # bit 128 ignored


if __name__ == "__main__":
    unittest.main()
