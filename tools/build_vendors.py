"""Generate ClosestVendor/Data/Vendors.lua from pfQuest (MIT) and wago UiMapAssignment.

Keeps only units listed in pfQuest's vendor/repair lists that have a coordinate, a name
and a known UI map. Output is sorted and deterministic. Standard library only.
"""
import csv
import io
import os
import re
import sys

import fetch_data

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "ClosestVendor", "Data", "Vendors.lua")
REAGENTS_LUA = os.path.join(ROOT, "ClosestVendor", "Reagents.lua")
FACTION = {"A": 1, "H": 2}  # anything else (AH, empty) -> 0, usable by both
# Standard vendor ammo (Ice Threaded ammo is reputation-only and left out).
ARROWS = (2512, 2515, 3030, 11285, 18042)  # Rough, Sharp, Razor, Jagged, Thorium Headed
BULLETS = (2516, 2519, 3033, 11284, 15997)  # Light Shot, Heavy Shot, Solid Shot, Accurate Slugs, Thorium Shells


def parse_meta_list(text, name):
    """{unitId: faction} from pfDB["meta"][name]."""
    m = re.search(r'\["%s"\] = \{(.*?)\n  \},' % re.escape(name), text, re.S)
    if not m:
        raise ValueError(f"meta list {name!r} not found")
    return {int(i): f for i, f in re.findall(r'\[(\d+)\] = "([A-Z]*)"', m.group(1))}


def parse_first_coords(text, wanted):
    """{unitId: (x_percent, y_percent, zoneId)} using each unit's first coordinate."""
    out = {}
    for m in re.finditer(r"^  \[(\d+)\] = \{\n(.*?)^  \},$", text, re.S | re.M):
        uid = int(m.group(1))
        if uid not in wanted:
            continue
        c = re.search(r"\{ ([\d.]+), ([\d.]+), (\d+), \d+ \}", m.group(2))
        if c:
            out[uid] = (float(c.group(1)), float(c.group(2)), int(c.group(3)))
    return out


def parse_item_sellers(text, item_ids):
    """Set of NPC ids that sell any of item_ids, from pfDB["items"]["data"][id]["V"]."""
    sellers = set()
    for item in item_ids:
        m = re.search(r"^  \[%d\] = \{\n(.*?)^  \},$" % item, text, re.S | re.M)
        if not m:
            continue
        v = re.search(r'\["V"\] = \{(.*?)\n    \},', m.group(1), re.S)
        if v:
            sellers.update(int(x) for x in re.findall(r"\[(\d+)\]", v.group(1)))
    return sellers


def load_reagents(path=REAGENTS_LUA):
    """[(itemId, bit, name)] from the one-item-per-line table in ClosestVendor/Reagents.lua."""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    items = [(int(i), int(b), n) for i, b, n in re.findall(
        r'\{ id = (\d+), bit = (\d+), class = "[A-Z]+", name = "([^"]+)"', text)]
    if not items:
        raise ValueError("no reagents found in " + path)
    bits = [b for _, b, _ in items]
    if len(set(bits)) != len(bits) or max(bits) >= 30:
        raise ValueError("reagent bits must be unique and below 30")
    return items


def parse_names(text):
    """{unitId: name} with Lua string escapes resolved."""
    out = {}
    for i, raw in re.findall(r'\[(\d+)\] = "((?:[^"\\]|\\.)*)"', text):
        out[int(i)] = re.sub(r"\\(.)", r"\1", raw)
    return out


def area_to_uimap(csv_text):
    """{AreaID: UiMapID} from UiMapAssignment; error if an area maps to several maps."""
    out = {}
    for row in csv.DictReader(io.StringIO(csv_text)):
        area, ui = int(row["AreaID"]), int(row["UiMapID"])
        if area <= 0:
            continue
        if out.get(area, ui) != ui:
            raise ValueError(f"AreaID {area} maps to several UiMapIDs")
        out[area] = ui
    return out


def lua_str(s):
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def pfquest_records(meta, units, names, assignment_csv, items, reagents=None):
    """Normalize pfQuest into records: {id, name, map, mx, my, faction, repair, ammo, reagents}.
    ammo: 0 none, 1 arrows, 2 bullets, 3 both. reagents: bitmask over the Reagents.lua table.

    A different data source only has to produce the same records and call render().
    Returns (records, stats).
    """
    vendors = parse_meta_list(meta, "vendor")
    repair = parse_meta_list(meta, "repair")
    wanted = set(vendors) | set(repair)
    coords = parse_first_coords(units, wanted)
    name_of = parse_names(names)
    area_map = area_to_uimap(assignment_csv)
    arrow_sellers = parse_item_sellers(items, ARROWS)
    bullet_sellers = parse_item_sellers(items, BULLETS)
    reagent_table = load_reagents() if reagents is None else reagents
    reagent_sellers = {(i, b): parse_item_sellers(items, (i,)) for i, b, _ in reagent_table}

    records, stats = [], {"listed": len(wanted), "kept": 0, "no_coords": 0, "no_name": 0, "no_map": 0,
                          "reagents_without_seller": [n for i, b, n in reagent_table
                                                      if not reagent_sellers[(i, b)] & wanted]}
    for uid in sorted(wanted):
        if uid not in coords:
            stats["no_coords"] += 1
            continue
        x, y, zone = coords[uid]
        if uid not in name_of:
            stats["no_name"] += 1
            continue
        if zone not in area_map:
            stats["no_map"] += 1
            continue
        records.append({
            "id": uid, "name": name_of[uid], "map": area_map[zone], "mx": x / 100, "my": y / 100,
            "faction": FACTION.get(vendors.get(uid, repair.get(uid, "")), 0),
            "repair": uid in repair,
            "ammo": (1 if uid in arrow_sellers else 0) + (2 if uid in bullet_sellers else 0),
            "reagents": sum(1 << b for (i, b), sellers in reagent_sellers.items() if uid in sellers)})
        stats["kept"] += 1
    return records, stats


def render(records, source_note):
    """Write the data file text for normalized records (source independent)."""
    seen, lines = set(), []
    for r in sorted(records, key=lambda r: r["id"]):
        if r["id"] in seen:
            raise ValueError(f"duplicate npc id {r['id']}")
        seen.add(r["id"])
        if not (0 <= r["mx"] <= 1 and 0 <= r["my"] <= 1):
            raise ValueError(f"npc {r['id']}: coordinates outside 0-1")
        if r["faction"] not in (0, 1, 2):
            raise ValueError(f"npc {r['id']}: bad faction")
        if r["ammo"] not in (0, 1, 2, 3):
            raise ValueError(f"npc {r['id']}: bad ammo code")
        reagents = r.get("reagents", 0)
        if not (isinstance(reagents, int) and 0 <= reagents < 1 << 30):
            raise ValueError(f"npc {r['id']}: bad reagent mask")
        lines.append("    {%d, %s, %d, %.4f, %.4f, %d, %s, %d, %d}," % (
            r["id"], lua_str(r["name"]), r["map"], r["mx"], r["my"], r["faction"],
            "true" if r["repair"] else "false", r["ammo"], reagents))
    header = (
        "-- Generated by tools/build_vendors.py. Do not edit.\n"
        f"-- {source_note}\n"
        "-- Record: {npcId, name, uiMapID, mx, my, faction (0 both, 1 Alliance, 2 Horde), repair, ammo (0 none, 1 arrows, 2 bullets, 3 both), reagents (bitmask, see Reagents.lua)}\n"
        "local _, ns = ...\n"
        "ns.ShippedVendors = {\n")
    return header + "\n".join(lines) + "\n}\n"


def build(meta, units, names, assignment_csv, items, source_note):
    records, stats = pfquest_records(meta, units, names, assignment_csv, items)
    return render(records, source_note), stats


def main():
    d = os.path.join(fetch_data.DATA)
    read = lambda *p: open(os.path.join(d, *p), encoding="utf-8").read()
    note = (f"Source: pfQuest {fetch_data.PFQUEST_COMMIT[:12]} (MIT, see THIRD_PARTY.md); "
            f"wago UiMapAssignment era build {fetch_data.WAGO_BUILDS['era']}")
    text, stats = build(
        read("pfquest", "db", "meta.lua"), read("pfquest", "db", "units.lua"),
        read("pfquest", "db", "enUS", "units.lua"),
        read("wago", "era", "UiMapAssignment.csv"), read("pfquest", "db", "items.lua"), note)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(stats)


if __name__ == "__main__":
    sys.exit(main())
