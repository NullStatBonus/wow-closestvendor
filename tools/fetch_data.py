"""Download the pinned build inputs into tools/data/ (git-ignored).

pfQuest is pinned to a commit; wago tables to a client build. Re-running
with the same pins fetches identical inputs. Standard library only.
"""
import os
import sys
import urllib.request

PFQUEST_COMMIT = "104f35678ca39ab1fb78b655f815cc7016f5e0c8"
PFQUEST_FILES = ["db/meta.lua", "db/units.lua", "db/enUS/units.lua", "db/items.lua", "LICENSE"]
WAGO_BUILDS = {"era": "1.15.9.70576", "forever": "1.60.1.70790"}
WAGO_TABLES = ["UiMapAssignment", "ItemEffect", "SpellName", "ItemSparse", "CreatureFamily"]
# Forever links items to effects through ItemXItemEffect and to pet diets through Item.ItemPetFoodID (names in ItemPetFood).
WAGO_EXTRA = {"forever": ["ItemXItemEffect", "Item", "ItemPetFood"]}

DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")


def get(url, dest):
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f:
        f.write(r.read())
    print(f"{os.path.getsize(dest):>9}  {os.path.relpath(dest, DATA)}")


def main():
    for p in PFQUEST_FILES:
        get(f"https://raw.githubusercontent.com/shagu/pfQuest/{PFQUEST_COMMIT}/{p}",
            os.path.join(DATA, "pfquest", p))
    for flavor, build in WAGO_BUILDS.items():
        for t in WAGO_TABLES + WAGO_EXTRA.get(flavor, []):
            get(f"https://wago.tools/db2/{t}/csv?build={build}",
                os.path.join(DATA, "wago", flavor, f"{t}.csv"))


if __name__ == "__main__":
    sys.exit(main())
