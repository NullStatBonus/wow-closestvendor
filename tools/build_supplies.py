"""Generate ClosestVendor/Data/Supplies.lua: food, drink, healthstone and pet diet items.

Food and drink come from the client data (Wago ItemEffect + SpellName, Classic Era and WoW Forever
unioned): an item whose use spell is named "Food" is food, "Drink" is drink. Pet diets of items come
from Item.ItemPetFoodID (WoW Forever client data, names in ItemPetFood). The diets each pet family eats come
from CreatureFamily.PetFoodMask in the client data (language-neutral family id). Output is sorted and
deterministic. Standard library only. Item mask bits: see ClosestVendor/Supplies.lua.
"""
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "tools", "data", "wago")
OUT = os.path.join(ROOT, "ClosestVendor", "Data", "Supplies.lua")

FOOD, WATER, HEALTHSTONE = 1, 2, 256
DIETS = ["Meat", "Fish", "Bread", "Cheese", "Fruit", "Fungus"]
DIET_BIT = {d: 1 << (i + 2) for i, d in enumerate(DIETS)}
# Healthstones of every rank, including the talent-improved ones (Minor .. Major).
# CreatureFamily.PetFoodMask bits, in the game's order: 1 Meat, 2 Fish, 4 Cheese, 8 Bread, 16 Fungus, 32 Fruit.
# Higher bits (raw meat and fish, removed in 3.0.2) are ignored.
FAMILY_BITS = {1: "Meat", 2: "Fish", 4: "Cheese", 8: "Bread", 16: "Fungus", 32: "Fruit"}
HEALTHSTONES = {5509, 5510, 5511, 5512, 9421, *range(19004, 19014)}
HEALTHSTONE_SPELLS = {"Minor Healthstone", "Lesser Healthstone", "Healthstone", "Greater Healthstone",
                      "Major Healthstone"}


def read_csv(path):
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def load_wago(flavors=("era", "forever"), base=DATA):
    """(effects, names, item_ids) unioned over the flavors: effects [(itemId, spellId)], names {spellId: name}."""
    effects, names, items = [], {}, set()
    for fl in flavors:
        rows = read_csv(os.path.join(base, fl, "ItemEffect.csv"))
        if rows and "ParentItemID" in rows[0]:  # Era links an effect to its item directly
            effects += [(int(r["ParentItemID"]), int(r["SpellID"])) for r in rows if r["TriggerType"] == "0"]
        else:  # Forever uses a link table
            spell = {r["ID"]: int(r["SpellID"]) for r in rows if r["TriggerType"] == "0"}
            for r in read_csv(os.path.join(base, fl, "ItemXItemEffect.csv")):
                if r["ItemEffectID"] in spell:
                    effects.append((int(r["ItemID"]), spell[r["ItemEffectID"]]))
        for r in read_csv(os.path.join(base, fl, "SpellName.csv")):
            names.setdefault(int(r["ID"]), r["Name_lang"])
        for r in read_csv(os.path.join(base, fl, "ItemSparse.csv")):
            items.add(int(r["ID"]))
    return effects, names, items


def load_diets(base=DATA):
    """[(itemId, diet, name)]: the pet diet of each item, from the client data (WoW Forever).

    Item.ItemPetFoodID points into ItemPetFood (id, name); only the six diets in DIETS count, so the
    removed raw meat and raw fish types are ignored. Classic Era has no such column; the item ids are the same.
    """
    fl = os.path.join(base, "forever")
    types = {int(r["ID"]): r["Name_lang"] for r in read_csv(os.path.join(fl, "ItemPetFood.csv"))}
    names = {int(r["ID"]): r["Display_lang"] for r in read_csv(os.path.join(fl, "ItemSparse.csv"))}
    out = []
    for r in read_csv(os.path.join(fl, "Item.csv")):
        food = int(r["ItemPetFoodID"] or 0)
        if not food:
            continue
        diet = types.get(food)
        if diet is None:
            raise ValueError(f"item {r['ID']}: pet food type {food} is not in ItemPetFood")
        # An Item row with no ItemSparse row has no name or tooltip: it is not an item a player can hold.
        if diet in DIET_BIT and int(r["ID"]) in names:
            out.append((int(r["ID"]), diet, names[int(r["ID"])]))
    if not out:
        raise ValueError("no pet diets found in the Item table")
    return out


def load_families(flavors=("era", "forever"), base=DATA):
    """{familyId: supply diet bits} unioned over the flavors; families that eat nothing are left out."""
    out = {}
    for fl in flavors:
        for r in read_csv(os.path.join(base, fl, "CreatureFamily.csv")):
            bits = sum(DIET_BIT[d] for b, d in FAMILY_BITS.items() if int(r["PetFoodMask"]) & b)
            if bits:
                out[int(r["ID"])] = out.get(int(r["ID"]), 0) | bits
    if not out:
        raise ValueError("no pet families with a diet found")
    return out


def build(effects, names, items, diets):
    """{itemId: mask}. Fails when a diet item or healthstone is unknown to the client data."""
    mask = {}
    for item, spell in effects:
        name = names.get(spell)
        if name == "Food":
            mask[item] = mask.get(item, 0) | FOOD
        elif name == "Drink":
            mask[item] = mask.get(item, 0) | WATER
        elif name in HEALTHSTONE_SPELLS and item in HEALTHSTONES:
            mask[item] = mask.get(item, 0) | HEALTHSTONE
    for item in HEALTHSTONES:
        if not mask.get(item, 0) & HEALTHSTONE:
            raise ValueError(f"healthstone {item} has no healthstone use spell in the client data")
    for item, diet, name in diets:
        if item not in items:
            raise ValueError(f"pet diet item {item} ({name}) is not in the client item data")
        mask[item] = mask.get(item, 0) | DIET_BIT[diet]
    return mask


def render(mask, families):
    lines = ["-- Generated by tools/build_supplies.py. Do not edit.",
             "-- Sources: Wago ItemEffect/SpellName/ItemSparse/CreatureFamily (Classic Era and WoW Forever) for food,",
             "-- drink, healthstones and pet families; Item/ItemPetFood (Forever) for the diets of items.",
             "-- Item id = mask: 1 food, 2 drink, 4 Meat, 8 Fish, 16 Bread, 32 Cheese, 64 Fruit, 128 Fungus, 256 healthstone.",
             "local _, ns = ...",
             "ns.SupplyItems = {"]
    for item in sorted(mask):
        lines.append(f"    [{item}] = {mask[item]},")
    lines.append("}")
    lines += ["-- Pet family id (UnitCreatureFamily) = diet bits: 4 Meat, 8 Fish, 16 Bread, 32 Cheese, 64 Fruit, 128 Fungus.",
              "ns.PetFamilies = {"]
    for fam in sorted(families):
        lines.append(f"    [{fam}] = {families[fam]},")
    lines.append("}")
    return "\n".join(lines) + "\n"


def main():
    effects, names, items = load_wago()
    mask = build(effects, names, items, load_diets())
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(render(mask, load_families()))
    print(f"{len(mask)} items -> {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    sys.exit(main())
