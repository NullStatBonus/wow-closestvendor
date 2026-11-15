# Addon presentation and interaction design

Shared presentation contract **v1**, adapted for Closest Vendor (CVN) from the KeepThat (KT) reference on 2026-11-15.

This is the CVN copy of the shared reference for addon settings, notices, previews and positioning. It uses the same vocabulary and structure as KT's `DESIGN.md` and records CVN's own logic and capabilities. **Shared** means a common design vocabulary, not shared SavedVariables, a suite launcher or a required runtime library.

KT is the reference implementation. CVN adopts the same principles and keeps its own gameplay, notification semantics, defaults, renderer and persistence scope. Where CVN differs from KT, section 12 states the difference and the reason. The values below describe code decisions, not measured screenshots.

## 1. Product principles

1. **Explain each decision.** State the page purpose, settings scope and next action. Keep the text short.
2. **Stay recognizably native.** Use existing Blizzard/Ace controls, popups and button chrome. Do not reskin the game or other addons.
3. **Keep the interface compact.** Size controls for their contents; use the available width for readable explanations, not oversized sliders and buttons.
4. **Use color for meaning.** Name the state as well as coloring it. A low status row is red **and** says Low.
5. **Preserve player choices.** Disabled controls retain their values. Appearance changes do not reset warnings, buying or navigation choices.
6. **Make experiments safe.** Previews use the real drawing code with made-up state. Samples never buy, set a waypoint or answer a question. Move has an explicit save and rollback.
7. **Remain independently installable.** Missing APIs, fonts, waypoint addons, NorgannonDB or other optional integrations must have a fallback or an explained unavailable action.

### Help text: ASD-STE100

Use ASD-STE100 principles for help text. Keep the context that a player needs to act. Remove repeated explanations.

- Use one instruction per sentence. Start with a command verb: Select, Clear, Set or Press.
- Use no more than 20 words in an instruction sentence. Use no more than 25 words in a descriptive sentence.
- Use short paragraphs. Keep page introductions to one or two sentences.
- Use active voice. Name the control or action.
- Use the same term for the same function. Match control labels exactly.
- Use approved vocabulary where applicable. Treat game terms, addon names and control labels as technical names.
- Do not use contractions, idioms or promotional claims.
- State the condition first when it changes the action.
- Explain disabled controls with a reason and one next action.
- Put detailed reference information in the README. Do not repeat it beside every control.

Keep purpose, scope, prerequisites and action results visible. Put optional detail in hover help. Do not remove necessary context to reduce the word count.

| Context | Concise copy pattern |
| --- | --- |
| Page purpose | “Choose how a recommendation becomes a waypoint.” |
| Disabled feature | “Enable Supplies on Home to edit this value.” |
| Locked position | “Unlock the position before moving.” |
| Active Move | “Move status window — Done saves; Cancel restores.” |
| Buying consequence | “Turning off Ask before buying allows purchases without confirmation.” |
| Preview | “Samples cannot buy or set waypoints.” |
| Troubleshooting | “Turn recording on, repeat the problem, then open the report to copy it.” |

Every player-facing sentence is a whole `L["..."]` string (see `docs/localization.md`). Review vocabulary and sentence length during localization and UI review.

## 2. Visual vocabulary

All dimensions below are logical UI units at normal addon scale, not physical monitor pixels. Blizzard UI scale and addon scale affect the rendered result.

| Role | Decision |
| --- | --- |
| Spacing base | 4 units (`Presentation.SPACE`) |
| Compact inset | 8 units (`Presentation.PAD`) |
| Content inset token | 12 units (`Presentation.CONTENT_PAD`) |
| Section separation token | 16 units (`Presentation.SECTION`) |
| Primary content | `#DDDDDD` (0.867) |
| Supporting text | Approximately `#AAAAAA` (section notes, hover help) |
| Low status row | Red `(1, 0.25, 0.25)` text and warning symbol |
| Persistent custom surface | Pure black, `#000000`; the player may choose another color |
| Compact notification (Toast) | 280 wide × at least 40 high |
| Compact icon | 28 × 28 |

The 12/16-unit values are shared layout tokens, not a claim that every native Ace widget uses those exact margins. CVN settings delegate geometry to AceConfig; blank description rows and headers separate sections. The status window, Toast and Warning use explicit measured geometry.

### Typography

Use client font objects instead of shipping a new font or hard-coding a font file.

| Text role | CVN implementation |
| --- | --- |
| Settings body | AceConfig medium description → `GameFontHighlight` |
| Settings help/section notes | AceConfig small description → `GameFontHighlightSmall` |
| About title | AceConfig large description → `GameFontHighlightLarge` |
| Section header | Native AceConfig header; retain its normal styling |
| Status window title | `GameFontNormal`, neutral ink |
| Status window rows | `GameFontHighlightSmall` |
| Toast title and message | `GameFontHighlightSmall` / `GameFontHighlight`, neutral ink |
| Warning notice | `GameFontHighlight`, neutral ink |

`Presentation.Font` prefers the requested object, then `GameFontHighlight`, then `GameFontNormal`, each under `pcall`. Missing preferred fonts must not require another addon. Essential copy must wrap or grow instead of relying on truncation or a hover tooltip.

### Semantic color

CVN has one semantic state color: **low** is red. It is not a brand color.

- A status window row whose count is at or below its warning threshold is drawn in red, with a red `!` symbol and a visible **Low:** label. Rows that are not low use neutral `#DDDDDD` ink.
- A row uses the same test as its warning (`Triggers.Conditions`, `Reagents.Low`, `Professions.Within`), so a red row and a warning cannot disagree.
- Display-only rows (Soul Shards, Blinding Powder, Conjured Food and Water) are never low and never red.
- Titles, Toast text, Warning text and settings explanations stay neutral.
- Do not copy KT's Endgame purple / Leveling green into CVN. Do not reuse CVN's red for anything except low.

## 3. Settings window and control sizing

CVN uses **AceConfig/AceConfigDialog with AceGUI**, the same renderer as KT, with a tree navigation sidebar and a scrolling content pane. Ace libraries are bundled in `ClosestVendor/Libs/`.

| Element | Current CVN decision |
| --- | --- |
| Standalone initial window | **600 × 460** logical units (same as KT) |
| Window title | **Closest Vendor** only |
| Scope information | Visible on Advanced, not a title suffix |
| Navigation | Ace tree; native initial sidebar width |
| Window behavior | Resizable; content remains reachable by scrolling |
| Sliders | 1.5 Ace control widths |
| Dropdowns | 1.5 Ace control widths (bounded, never full-page) |
| Action buttons (Preview, Move, Reset position, Background color) | 1.5 Ace control widths |
| Toggles with explanatory labels | Full width |
| Body/help content | Full width; prose wraps |
| Color picker | Native color picker; a chat fallback note when unavailable |

Ace's control-width multiplier is 170 units in the bundled renderer: 1.5 widths is approximately 255. These are renderer-relative choices, not instructions to modify Ace libraries.

### Choosing a control

- A boolean uses a checkbox; a bounded numeric adjustment uses a slider; a color uses the native color picker.
- A dropdown selects from a real list: ammo grade, waypoint method, destination preference, instance search origin, notification style, notification sound and status window row mode.
- Short actions look like buttons, not full-page bars. Keep complete labels when translated; widen or reflow if necessary.
- Do not shrink fonts or remove context to make the default window fit. Wrap explanations and scroll long pages.

## 4. Page context and information architecture

Every top-level page must work when opened directly. The player should not need to remember a previous page or hover every control to understand the current page.

Show the active scope in Advanced. CVN settings are saved for this character; vendors, trainers and auctioneers learned are shared by the account. Repeat the scope only when it changes a decision.

The common reading order is:

1. Page heading.
2. A purpose statement of one or two short sentences.
3. Sections for each task, with a section note before the related controls.
4. Current-state guidance where it changes the next action (for example, “Your class does not use equipped ammo.”).

### Top-level pages

| Order | CVN page | Purpose and ownership |
| --- | --- | --- |
| 1 | Home | Every switch that decides whether the addon acts |
| 2 | Restock | Ammo, Reagents and Supplies child pages: counts, items and merchant buying |
| 3 | Navigation | Waypoint method, instance search origin and auction house |
| 4 | Appearance | Notifications, Status window and Sound tabs |
| 5 | Advanced | Settings scope and troubleshooting |
| 6 | About | Purpose, version and command discovery |

Restock nests its three pages the way KT nests Materials → profession. Sound is an Appearance tab because it belongs with notification style. Advanced stays for rarely used settings only. CVN has no Materials or Integrations page.

### Home

Home describes the outcome: CVN suggests the closest vendor, trainer or auction house when you need one. It never sells items for the player.

- **Bag space, Durability, Profession training:** each toggle is followed by its threshold slider, disabled while the warning is off, and a note that says what triggers the suggestion.
- **Ammo, Reagents, Supplies:** switches. A note directs players to Restock for counts, individual items and merchant buying.
- **How to act:** Destination on another map (Ask which one / Navigate without asking) and Preferred target. This is the largest behavior choice, so it is on Home.
- **Where to show it:** On-screen notice. Turning notifications on is feature activation, so it is on Home, not Appearance.

Buying controls stay on their Restock pages next to their consequence text.

### Restock: Ammo, Reagents and Supplies

- State that the warning count and the buying target are separate amounts.
- Disabled controls name the switch that enables them: “Enable Buy ammo to edit this value.”
- Explain the buying consequence next to Ask before buying.
- Show class-specific state. A class without equipped ammo, or without vendor-sold reagents, says so instead of showing inert controls as if they work.
- Supplies shows Water only to mana classes, Pet food only to hunters and Healthstone reminder only to warlocks. Mage text explains that a low count reminds the player to conjure instead of visiting a vendor.

### Navigation

Sections are **Waypoint**, **Inside instances** and **Auction house**. Each note explains the routing rule: the TomTom → WaypointUI → game waypoint fallback order, the instance search origin and that an auction-house route places no order.

### Appearance

Keep visual choices separate from feature activation. Appearance uses three standard AceGUI tabs:

1. **Notifications** — Style (Toast / Warning) and one Preview. With Toast: background opacity, text and icon opacity, scale, Move and Reset position. With Warning these are hidden, and one line explains that Warning has no appearance or position settings.
2. **Status window** — Lock position, background opacity, text and icon opacity, scale, Preview, Move, Reset position, Background color, and one Show mode per row group (Ammo, Reagents, Supplies, Bag space, Durability, Professions).
3. **Sound** — one control, **Notification sound**: Whisper ping (default), Minimap ping, Group invite, Ready check or None. Choosing one plays it. It applies to every notification. `/cvn sound <name>` sets the same value.

Toast controls are disabled while On-screen notice (on Home) is off, with the reason. Preview and Move remain available.

### Advanced

- State where settings are saved: this character. Learned places are shared by the account.
- Troubleshooting reads: **record → repeat the problem → open the report → Ctrl+A/Ctrl+C → turn recording off**.
- Clearing the log asks for confirmation and removes diagnostic entries only; settings and learned places are kept.

### About

Show addon name, runtime TOC version and a short purpose statement, then common commands with one short explanation each. State that legacy `/cvn test` commands are live integration tests and may set a real waypoint.

## 5. Notifications: Toast or Warning, and prompts

A notification is a notification. Every route message (pin without asking, row click, auction-house route), class reminder and test message goes through one path: it shows in the player's **Style** and plays the player's **Sound**. New installs default to **Toast**; existing installs keep **Warning**.

| Part | Toast (default) | Warning |
| --- | --- | --- |
| Panel | 280 wide; minimum height 40; pure black at background opacity | 800 × 40 frame, no fill |
| Icon | 28 × 28 map icon, left inset 8, top inset 8 | None |
| Title | **Closest Vendor**, left 44, top inset 8, width 228, neutral | None |
| Message | Left 44, top 24, width 228; wraps | Centered, width 760; wraps |
| Height | `max(40, 32 + messageHeight + 8)` | `max(40, messageHeight + 16)` |
| Default anchor | TOP, x = 0, y = −200 | TOP, x = 0, y = −200 |
| Strata | HIGH | HIGH |
| Mouse | Transparent | Transparent |
| Live lifetime | Five seconds | Five seconds |
| Visible limit | One; a new notice replaces the old one | One |

Rules:

- One sound for every notification: Whisper ping (default), Minimap ping, Group invite, Ready check or None. Notifications shown together on one check play it once.
- On-screen notice off: nothing on screen and no sound. The chat line always prints.
- Changing style changes nothing else.
- The newest wins: a notification replaces any other notification, live or sample, in either style. A status window click, a new demo or a preview also stops a running demo (restoring its previous waypoint) or preview first. A click on a demo row routes for real.

Confirmation questions (Navigate here?, Buy ammo?, Buy reagents?) remain native StaticPopups with their real Accept/Cancel semantics. They are not notifications and play no notification sound. Do not convert a consequential prompt into a disappearing, mouse-transparent notice.

## 6. Opacity, scale and migration

Use the same labels as KT wherever applicable:

| Control | Public units | New-install default |
| --- | --- | --- |
| Status window background opacity | Integer 0–100 | 80 |
| Status window text and icon opacity | Integer 20–100 | 100 |
| Status window scale | Integer 50–200; 100 is normal | 100 |
| Status window Lock position | on/off | off |
| Toast background opacity | Integer 0–100 | 100 |
| Toast text and icon opacity | Integer 0–100 | 100 |
| Toast scale | Integer 50–200; 100 is normal | 100 |

Background opacity at zero draws nothing: no fill, border or texture, whatever the color. Text and icon opacity is independent and affects existing and newly created rows. CVN stores these as whole percentages.

Persistent visuals are OLED-safe: the status window defaults to pure black, has no border or bright fixed fill, and text and icons stay dimmable. The red low color is text only.

Migration preserves existing values. An install with saved data that has no Notification style gets Warning, so existing players keep the notice they had. Legacy `toastLocked` data is ignored so it cannot block Move. Preserve colors, position, row modes and feature states.

## 7. Status window

The status window is CVN's persistent surface. It lists what the player tracks, grouped as Ammo, Reagents, Supplies, Bag space, Durability and Professions. Each group has a Show mode: Only when low, Always or Never.

| Part | Geometry / behavior |
| --- | --- |
| Inset | 8 |
| Title | 16 high, **Closest Vendor**, `GameFontNormal`, neutral |
| Settings cog | 16 × 16, top right; opens settings |
| Row | At least 16 high, text from x = 12; grows for wrapped text |
| Low row | Red text, red `!` at the row's left, **Low:** prefix |
| Width | At least 130; text up to 520 before wrapping |
| Default anchor | LEFT, x = 60, y = 60 |
| Strata | MEDIUM; TOOLTIP during Move |

A routable row click sets a route to the closest source. A display-only row does nothing. Inside an instance, a row click searches from the configured search origin. Rows are hidden when the window has nothing to show.

## 8. Preview and demo

CVN has two tools with different jobs. **Preview** is a safe sample. **Demo** is a tour of real behavior that puts things back afterward.

| Entry point | CVN output |
| --- | --- |
| Appearance, Notifications tab: Preview | One sample notification in your style, with your sound |
| Appearance > Status window: Preview | Made-up status window rows |
| `/cvn preview` | Lists notice, hud and prompt kinds |
| `/cvn preview <kind>` | One safe sample for ten seconds |
| `/cvn demo` | A tour of real routes, questions and notifications, then your previous waypoint is restored |
| Legacy `/cvn test …` | Live integration tests; may set a real waypoint |

### Previews

Previews use the real renderers with made-up content labeled “Preview —”. They work while the real feature is off. They never buy, set a waypoint or change a setting. The sample prompt uses a separate popup ID whose buttons do nothing.

### Demo

The demo runs the production code, one step every five seconds:

1. Pin a sell vendor without asking — notification.
2. Ask about a repair vendor — confirmation question; Yes sets a real waypoint.
3. Pin a food seller without asking.
4. Ask about water (mana classes) or pet food (hunters).
5. Pin an arrow vendor without asking.
6. Click a status window row — your first watched class reagent (a closer auction house can win), or repair for classes without reagents.
7. The class reminder (mage, warlock) or a test notification.

Each step uses real vendor data, the real waypoint provider and your notification style and sound, even while On-screen notice is off. Before each step, the previous step's waypoint is removed (unless something else replaced it) and its question is withdrawn. The status window shows made-up rows during the tour. At the end, the waypoint you had before the demo is set again and real rows return. The demo never changes settings, never buys, and never marks a warning as handled. Running it again stops the older tour.

## 9. Transactional positioning

Use the terms **Move**, **Done**, **Cancel**, **Lock position**, **Reset position**.

| State/action | Required result |
| --- | --- |
| Start Move | Snapshot the original anchor; show a labeled placeholder with Done and Cancel |
| Drag | Change only tentative position; do not save on drag stop |
| Done | Save the final clamped anchor, then leave Move |
| Cancel or Escape | Discard tentative position and restore the original anchor |
| Enable Lock position | Cancel any active status window Move |
| Locked status window | Refuse Move, title drag and Shift-drag; explain unlocking |
| Reset position | Reset only the anchor |
| Normal notification | Keep production Toasts mouse-transparent |

Only the status window has Lock position. Toast has no lock. Move controls are native `UIPanelButtonTemplate` buttons, 112 × 24, in a 240 × 28 strip 4 units below the surface. The settings page also exposes Move and Reset position.

Outside Move, the unlocked status window keeps its existing shortcuts: drag the title, or hold Shift and drag anywhere. These save immediately and respect Lock position.

Do not change colors, opacity, scale, locks or gameplay settings when resetting position.

## 10. Commands, settings parity and diagnostics

CVN uses the shared verbs with the `/cvn` prefix:

| Verb | Purpose |
| --- | --- |
| settings [page] | Open Home or a named page: home, restock, ammo, reagents, supplies, navigation, appearance, sound, advanced, about |
| help [topic] | Explain appearance, diagnostics, bags, ammo, reagents, supplies, navigation or hud commands |
| status | Report effective settings, scope and class availability |
| get / set | Read or change a stable allowlisted public key |
| preview [kind] | Discover or show one safe visual sample |
| demo | Show representative synthetic visuals together |
| debug on/off | Control diagnostic recording |
| log | Open the copyable report |
| log clear | Confirm diagnostic-only clearing |

Bare `/cvn` opens Home. Valid legacy commands (`hud`, `nav`, `buy`, `notice`, `sound`, `food`, `bags`, `test …` and others in the README) remain supported.

UI and CLI share validators, units and refresh behavior through `Presentation.Set`. Reject unknown keys, invalid enums, fractional integers, out-of-range values, missing arguments and surplus input without writes. Do not accept arbitrary Lua paths or executable input.

CVN's public keys are `bags.threshold`, `appearance.notification-style`, `appearance.hud.background-opacity`, `appearance.hud.text-opacity`, `appearance.hud.scale`, `appearance.hud.locked`, `appearance.toast.background-opacity`, `appearance.toast.text-opacity` and `appearance.toast.scale`. All are character scope. The debug report lists every saved setting plus the presentation contract version.

The debug report uses a standard AceGUI Frame with a fill-layout MultiLineEditBox, focused and selected on opening, read-only, with a Ctrl+A/Ctrl+C hint. The native report and chat output remain the fallback when AceGUI is unavailable.

## 11. Reuse boundaries and validation

Adopt the shared terms, roles and interaction contracts locally. Preserve CVN's gameplay defaults and its per-character persistence. Do not add inert controls for features CVN does not have.

CVN's implementation sources:

- [Settings and page content](ClosestVendor/Options.lua)
- [Local tokens, public keys and validation](ClosestVendor/Presentation.lua)
- [Toast rendering and Move](ClosestVendor/Toast.lua)
- [Status window rendering and Move](ClosestVendor/Tracker.lua)
- [Status rows, low test and demo rows](ClosestVendor/Status.lua)
- [Position transaction](ClosestVendor/Move.lua)
- [Warning notice, popups and native adapters](ClosestVendor/Adapter.lua)
- [Copyable report window](ClosestVendor/Report.lua)
- [Change record and coverage](openspec/changes/cohesive-addon-presentation/coverage.md)

Automated validation uses `make test` and `make check`. Before claiming visual acceptance, review on both clients (Vanilla and Camelot/Forever) at matching UI scale, following `docs/test-plan.md`:

- All six pages and their child pages and tabs opened directly; purpose, scope and next action are apparent.
- Compact window, resizing, scrolling, long translations and complete control labels.
- Each class's Ammo, Reagents and Supplies page state.
- Opacity at 0/80/100; scale at 100/150 and the bounds.
- Low rows red with the Low label; display-only rows never red.
- Warning and Toast styles; prompts keep Accept/Cancel.
- Disabled-feature samples, repeat/expiry and concurrent real updates.
- Move edge clamping, Done/Cancel/Escape, lock and combat.

## 12. Differences from KeepThat

| Area | KT | CVN | Reason |
| --- | --- | --- | --- |
| Semantic color | Endgame purple, Leveling green | Low red | Different domain meaning |
| Settings scope | Shared Default profile, optional character profile | Fixed per character; learned places per account | Existing CVN persistence |
| Feature pages | Materials, Integrations | Ammo, Reagents, Supplies, Navigation | Different features |
| Appearance layout | Sections on one page | Three AceGUI tabs | Status window has many row controls; Sound belongs with notifications |
| Persistent surface | None | Status window with Lock position | CVN feature |
| Toast | Category accent, stack of three, 4 s with fades, y = −140 | No accent, one at a time, 5 s, no fade, y = −200 | One route notice at a time; matches existing Warning anchor |
| Notice style | Toast only | Warning or Toast per character, for every notification | Existing players keep Warning |
| Sound | None | One notification sound for every notification | Reminders and routes need an audible cue |
| Demo | Synthetic samples | Real routing tour that restores the previous waypoint | Shows the full range of routes, questions and notifications |
| Preview lifetime | 4 s toast/tint, 15 s tooltip | 10 s; demo steps 5 s | Long enough to read route text |
| Move buttons | 100 × 24, 8-unit gap | 112 × 24, 8-unit gap | Fits translated Done/Cancel |
| Prompts | None | Native StaticPopups kept | Consequential actions |
