## ADDED Requirements

### Requirement: Rows
The status window SHALL show one line per tracked item that applies to the player: ammo (arrows or bullets) when the player uses a ranged weapon, each watched class reagent, bag space, durability, and each known profession below its cap. A value the game cannot read SHALL hide its row and never show as zero. Each line SHALL show the item name and its count or value.

#### Scenario: One line per item
- **WHEN** a mage with two watched reagents has the window showing everything
- **THEN** there is a line each for bag space, durability, and the two reagents, and none for ammo

#### Scenario: Unreadable value
- **WHEN** a value cannot be read
- **THEN** its row is not shown

#### Scenario: Low is marked
- **WHEN** a row's value is at or past its trigger threshold
- **THEN** the row is visibly marked as low, using the same threshold as the warning for that item

### Requirement: Row visibility modes
Each row group SHALL have a mode: `low` (its rows shown only while low), `always` or `never`, default `low`, and every row SHALL follow the mode of its group. The window SHALL be shown only while at least one row qualifies under its mode; with nothing to show, no window appears.

#### Scenario: Only low rows
- **WHEN** ammo is low, bags are not, and both are in mode `low`
- **THEN** the window shows the ammo row only

#### Scenario: Mixed modes
- **WHEN** durability is `always`, reagents are `low` and not low, and bags are `never`
- **THEN** the window shows the durability row only

#### Scenario: Nothing to show
- **WHEN** no row qualifies
- **THEN** the window is hidden

#### Scenario: Rows that do not apply to the class
- **WHEN** the Status window settings page is shown for a class without ammo, or for a class with neither class reagents nor display-only items
- **THEN** it still lists the Ammo and Reagents rows, the one that does not apply greyed out with a tooltip saying why ("Your class does not use ammo." or "Your class does not use reagents."), and changing it is impossible and never writes a mode

#### Scenario: Window refreshes
- **WHEN** bags, gear, skills or spells change
- **THEN** the rows are recomputed once after a short delay, not once per event

### Requirement: Row groups
Every row SHALL belong to one of five groups, keyed `ammo`, `reagents` (each class reagent and display-only item), `bags`, `durability` and `professions` (each profession row). The Status window settings page SHALL list one mode dropdown per group in the order Ammo, Reagents, Bag space, Durability, Professions, and `/cvn hud row <ammo|reagents|professions|bags|durability> low/always/never` SHALL set a group's mode. A saved mode under any other key SHALL be ignored.

#### Scenario: One mode for every profession
- **WHEN** the character has Mining near its cap and Cooking far from it, and Professions is `always`
- **THEN** both profession rows are shown; with Professions `low` only Mining is shown, and with `never` neither

#### Scenario: Stale per-row keys
- **WHEN** the saved row modes hold `prof:Mining = always` from an earlier build
- **THEN** it is ignored and the Professions group keeps its own mode

### Requirement: Display-only items
The addon SHALL track Soul Shards (Warlock), Blinding Powder (Rogue), Conjured Food and Conjured Water (Mage; each summing the counts of every rank's item) as rows that cannot be routed to. They SHALL belong to the Reagents group and SHALL never be low, so they are shown only while Reagents is `always` (hidden at `low` and `never`). They SHALL show only to the class that uses them and who knows the spell that needs or makes them, and a click on one SHALL do nothing.

#### Scenario: Soul shards default hidden
- **WHEN** a warlock has not changed any setting
- **THEN** no soul shard row is shown

#### Scenario: Shown with Reagents always
- **WHEN** a warlock sets Reagents to `always`
- **THEN** the soul shard row is shown, never marked low

#### Scenario: Conjured items are summed
- **WHEN** a mage holds 3 Conjured Water and 10 Conjured Spring Water and the row is shown
- **THEN** the row shows 13

#### Scenario: Click does nothing
- **WHEN** the player clicks a display-only row
- **THEN** no waypoint is set and no question is shown

### Requirement: Click a row to navigate
Clicking a routable row SHALL pin the closest eligible vendor for that item at once, without a question, whatever the map choice mode is, and SHALL use the map preference to choose between a target on the player's map and the closest. It SHALL work in combat. It SHALL print the same notice as an automatic pin, stating why. It SHALL close an open question for another trigger, and SHALL be treated as that condition being handled. A click with no known vendor SHALL say so in chat.

#### Scenario: Pin without asking
- **WHEN** the choice mode is `ask` and the player clicks the arrows row
- **THEN** the closest arrow vendor is pinned and no question is shown

#### Scenario: In combat
- **WHEN** the player clicks a row in combat
- **THEN** the pin is set

#### Scenario: Notice says why
- **WHEN** a row click pins a vendor
- **THEN** chat and the on-screen message read "Navigating to <vendor> (<zone>, N yards) <reason>."

#### Scenario: No known vendor
- **WHEN** no vendor is known for the clicked item
- **THEN** chat says so and nothing is pinned

#### Scenario: Another trigger's pin is kept
- **WHEN** a pin was set by a click and a different trigger later clears
- **THEN** the clicked pin stays until a merchant window opens or the condition resolves

### Requirement: Moving and locking
The window SHALL move when the title is dragged, or when Shift is held and the window is dragged anywhere. It SHALL stay on screen. The position SHALL be saved and restored. A "Lock window position" setting SHALL block all moving, Shift-drag included, and SHALL be the first control on the Status window settings page.

#### Scenario: Drag the title
- **WHEN** the window is unlocked and the player drags the title
- **THEN** the window moves and the position is saved

#### Scenario: Shift-drag
- **WHEN** the window is unlocked and the player holds Shift and drags a row
- **THEN** the window moves

#### Scenario: Locked
- **WHEN** the window is locked
- **THEN** neither dragging the title nor Shift-drag moves it

#### Scenario: Reset
- **WHEN** the player runs `/cvn hud reset`
- **THEN** the window returns to its default position

### Requirement: Cog button
The window SHALL have a small cog button that opens the Closest Vendor settings page. If the page cannot be opened, the addon SHALL say so in chat.

#### Scenario: Open settings
- **WHEN** the player clicks the cog
- **THEN** the Closest Vendor settings page opens

### Requirement: Appearance settings and commands
The addon SHALL provide scale (50 to 200 percent), background opacity (0 to 100 percent, default 80), text and icon opacity (20 to 100 percent, default 100) and background color (default pure black) settings for the window, and the commands `/cvn hud lock`, `/cvn hud unlock`, `/cvn hud reset`, `/cvn hud scale <50-200>`, `/cvn hud opacity <0-100>`, `/cvn hud textopacity <20-100>`, `/cvn hud color <#rrggbb|black|reset>` and `/cvn hud row <group> low/always/never` (see Row groups).

#### Scenario: Scale
- **WHEN** the player runs `/cvn hud scale 150`
- **THEN** the window is 1.5 times its normal size

#### Scenario: Out of range refused
- **WHEN** the player runs `/cvn hud opacity 101` or `/cvn hud textopacity 19`
- **THEN** the setting is unchanged and the reply gives the allowed range

#### Scenario: Saved values put right
- **WHEN** saved settings hold an opacity outside its range or a color that is not six hex digits
- **THEN** the opacity is held to its range and the color is black

#### Scenario: Row mode by command
- **WHEN** the player runs `/cvn hud row professions always`
- **THEN** the Professions group's mode is `always` and `/cvn` reports it

#### Scenario: A single item is not a group
- **WHEN** the player runs `/cvn hud row arcane powder always`
- **THEN** nothing changes and chat names the five groups

### Requirement: OLED-safe appearance
The window SHALL default to a pure black background, SHALL draw no border and no bright fixed fill, and SHALL mark a low row by its text color only. At background opacity 0 it SHALL draw nothing behind the text (no fill, border or texture), whatever the color. Text opacity SHALL apply to the title, the cog and every row, including rows added later, and not to the background.

#### Scenario: Background off
- **WHEN** the background opacity is 0, with any color
- **THEN** only the title, the cog and the row text are drawn

#### Scenario: Dimmed text
- **WHEN** the text opacity is 40
- **THEN** the title, the cog and every row are drawn at 40 percent, and the background keeps its own opacity

#### Scenario: Default color
- **WHEN** the player never chose a color, or the saved one is not a color
- **THEN** the background is pure black

### Requirement: Background color choice
The background color SHALL be chosen with a swatch in the settings page that shows the current color and opens the game's color picker, any color allowed, where the picker exists. `/cvn hud color` with no color SHALL open the game's color picker (or say in chat that there is none), and `/cvn hud color <#rrggbb|black|reset>` SHALL set it everywhere and is the way back to black.

#### Scenario: Color picker
- **WHEN** the game has a color picker and the player clicks the swatch and picks a color
- **THEN** the background takes that color live, the swatch shows the saved color, and Cancel restores the starting color

#### Scenario: No color picker
- **WHEN** the game has no color picker or no settings button
- **THEN** no swatch is shown (no dead control), nothing errors, and `/cvn hud color` still sets and resets the color

#### Scenario: Command opens the picker
- **WHEN** the player types `/cvn hud color` with no color
- **THEN** the game's color picker opens at the saved color and a pick is saved, or, where the game has no picker, chat says so and names `/cvn hud color #rrggbb`

#### Scenario: Swatch missing is explained
- **WHEN** the swatch cannot be built
- **THEN** the debug log and the report say which of the color picker, the page layout, `layout.AddInitializer` or `CreateSettingsButtonInitializer` is missing, and the report says whether the picker and settings button exist

### Requirement: Demo
The addon SHALL accept a `/cvn demo` command that is not listed in help, the README or the listing. Each use SHALL roll a random window setup (random rows, counts and modes, with at least one row low) and one random warning, shown through the real notice, question and pin paths, for 10 seconds, then restore the real window and clear anything the demo pinned. A new use SHALL re-roll and restart the 10 seconds. The demo SHALL NOT change saved settings.

#### Scenario: Demo shows and restores
- **WHEN** the player runs `/cvn demo`
- **THEN** a random window is shown with a random warning and, after 10 seconds, the real window state returns

#### Scenario: Demo does not save
- **WHEN** a demo has finished
- **THEN** saved settings are exactly as before it

#### Scenario: Repeat
- **WHEN** the player runs `/cvn demo` again during a demo
- **THEN** a new setup replaces the old one and the 10 seconds restart
