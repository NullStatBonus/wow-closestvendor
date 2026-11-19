# Store listing

Copy-ready text and field values for the CurseForge and Wago projects. Create the projects first, then add their IDs to both TOC files (see [publishing.md](publishing.md)). Confirm category names and field limits on the site forms, and pick the closest match if a name differs.

## Fields

| Field | Value |
|---|---|
| Project name | Closest Vendor |
| Slug / URL name | closest-vendor (use whatever is free) |
| Summary (one line, keep under 250 characters) | A gentle nudge when it is time to repair, restock ammo, reagents, food or water, or make bag space, with the closest vendor or trainer one click away. For WoW Forever and Classic Era. |
| Main category | Map & Minimap |
| Additional categories | Bags & Inventory, Miscellaneous |
| Game versions | Classic Era (1.15.x) and WoW Forever (1.60.x). The packager reads `## Interface` from each TOC: 11509 for `ClosestVendor_Vanilla.toc`, 16001 for `ClosestVendor_Camelot.toc`. |
| License | MIT |
| Source code URL | `https://github.com/NullStatBonus/wow-closestvendor` |
| Issues URL | `https://github.com/NullStatBonus/wow-closestvendor/issues` |
| Relations | Optional dependencies: TomTom (`tomtom` on CurseForge), WaypointUI (`waypointui` on CurseForge) and NorgannonDB. The addon works without any of them. |
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
- A profession is near its skill limit and you are high enough level to learn the next tier: it offers the closest trainer you have visited. With NorgannonDB installed, it offers only trainers who teach that tier, Artisan included; without it, Artisan is left to you.

**Restock without the trip planning.** At any merchant, it can fill your quiver or ammo pouch. It can also top up your class reagents (off by default). It buys only what you can afford and tells you in chat.

**See it at a glance.** An optional status window shows what is low. Click a row to set a waypoint, or click its arrow to pick another seller. You can make the background see-through, and the window is gentle on OLED screens.

**Get started.** Install it and type `/cvn`. Every threshold is a setting under Options, AddOns, **Closest Vendor**. The full command list is in the README.

**Good to know**

- It ships with about 900 vendors and learns the ones you open.
- TomTom and WaypointUI are optional. Classic Era needs TomTom to show an arrow. Choose the waypoint method with `/cvn nav` (for example, the game's own waypoint even when TomTom is installed).
- Settings are saved per character. The vendors, trainers and auctioneers the addon learns are shared by the whole account.
- One question at a time, and No means no: it moves on to your next need and does not ask again until things change. It waits while you are dead or in combat, and drops a question when you change zone or enter a dungeon.
- Vendors, trainers and auction houses that will not deal with you (Unfriendly or Hostile) are skipped once you have seen them.
- Pet food works for hunters with a pet out, in every game language.
- Open a vendor or trainer once so the addon learns it. This matters most in WoW Forever's new zones.
- If the NorgannonDB addon is installed, its vendors in WoW Forever's new zones and its profession trainers (with the tier each teaches) are used too. Nothing is copied from it.
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

### Appearance and safe previews

Every route message and reminder is a notification: a compact Toast (default) or a Warning, with one sound you choose, including sounds from any SharedMedia pack you have. Toasts wrap long routes and offer their own position, scale and dimming. Low status window rows are red with a visible Low label. `/cvn settings` opens the bundled settings tree with Home, feature pages, Appearance, Advanced and About. Settings remain per character.

Use `/cvn demo` for a tour of real routes, questions and notifications that puts your waypoint back at the end, or `/cvn preview notice/hud/prompt` for one safe sample. Samples cannot buy or navigate. Move uses Done to save and Cancel/Escape to restore; lock blocks moving. `/cvn help appearance` lists typed settings commands. Clearing the debug report requires confirmation and keeps learned places and settings.
