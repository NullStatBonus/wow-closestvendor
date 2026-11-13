# Store listing

Copy-ready text and field values for the CurseForge and Wago projects. Create the projects first, then add their IDs to both TOC files (see [publishing.md](publishing.md)). Confirm category names and field limits on the site forms, and pick the closest match if a name differs.

## Fields

| Field | Value |
|---|---|
| Project name | Closest Vendor |
| Slug / URL name | closest-vendor (use whatever is free) |
| Summary (one line, keep under 250 characters) | A gentle nudge when it is time to repair, restock ammo or reagents, or make bag space, with the closest vendor or trainer one click away. For WoW Forever and Classic Era. |
| Main category | Map & Minimap |
| Additional categories | Bags & Inventory, Miscellaneous |
| Game versions | Classic Era (1.15.x) and WoW Forever (1.60.x). The packager reads `## Interface` from each TOC: 11509 for `ClosestVendor_Vanilla.toc`, 16001 for `ClosestVendor_Camelot.toc`. |
| License | MIT |
| Source code URL | `https://github.com/NullStatBonus/wow-closestvendor` |
| Issues URL | `https://github.com/NullStatBonus/wow-closestvendor/issues` |
| Relations | Optional dependencies: TomTom (`tomtom` on CurseForge) and WaypointUI (`waypointui` on CurseForge). The addon works without either. |
| Tags | vendor, repair, ammo, reagent, food, water, profession, trainer, navigation, waypoint, quality of life, classic, forever |
| Release type | Release (use Beta for pre-release tags) |
| Changelog | Taken from `CHANGELOG.md` by the packager; nothing to type. |
| Donations | none |

## Description

Paste this into the description box (CurseForge and Wago both take Markdown or HTML; use the Markdown editor if offered).

---

**A gentle nudge, right when you need it.**

Closest Vendor tells you when it is a good time to repair, restock or make bag space. It offers the closest vendor and always asks first. You do not have to remember to check.

**It speaks up when:**

- Your bags are nearly full: it offers the closest vendor you can sell to.
- Your gear is wearing out: it offers the closest repair vendor.
- Your ammo is running low: it offers the closest vendor that sells it.
- A class reagent is running low: it offers the closest vendor that sells it.
- Food, water or pet food is running low: it offers the closest vendor that sells it. Mages and warlocks who can make their own get a reminder with a sound instead.
- A profession is near its skill limit: it offers the closest trainer you have visited.

**Restock without the trip planning.** At any merchant, it can fill your quiver or ammo pouch. It can also top up your class reagents (off by default). It buys only what you can afford and tells you in chat.

**See it at a glance.** An optional status window shows what is low. Click a row to set a waypoint. You can make the background see-through, and the window is gentle on OLED screens.

**Get started.** Install it and type `/cvn`. Every threshold is a setting under Options, AddOns, **Closest Vendor**. The full command list is in the README.

**Good to know**

- It ships with about 900 vendors and learns the ones you open.
- TomTom and WaypointUI are optional. Classic Era needs TomTom to show an arrow.
- Pet food works for hunters with a pet out, in every game language.
- Open a vendor or trainer once so the addon learns it. This matters most in WoW Forever's new zones.
- Problems? Type `/cvn debug on`, repeat the problem, then type `/cvn log` and post the report.

---

## Screenshots to capture

1. The question with a vendor name and zone (`/cvn test sell`).
2. The repair question (`/cvn test repair`).
3. The settings page under Options, AddOns.
4. A TomTom arrow or the map waypoint after answering Yes.
5. The ammo question for a hunter (`/cvn test arrows`).
6. The chat line after an ammo purchase.
7. The status window with a few lines, one of them red.
8. The Status window settings page.

Use 1920x1080 or larger, UI scale unchanged, with the chat frame showing nothing private.

## After creating the projects

Both IDs are in both TOC files (`## X-Curse-Project-ID`, `## X-Wago-ID`). With the repository secrets `CF_API_TOKEN` and `WAGO_API_TOKEN` set, every `vX.Y.Z` tag publishes to both sites (see publishing.md). Update the pasted description and summary on each site whenever this file changes; the sites do not read it.
