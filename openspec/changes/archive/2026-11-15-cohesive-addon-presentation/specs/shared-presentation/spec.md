## ADDED Requirements

### Requirement: Local visual contract
The addon SHALL implement shared visual tokens locally, use existing client font objects and guarded fallbacks, and retain native settings, tooltip and button chrome. It SHALL work independently of sibling addons. New controls SHALL use verified Blizzard/Ace patterns before custom controls, recording the inspected source and fallback.

#### Scenario: Independent installation
- **WHEN** only this addon is installed
- **THEN** its UI loads and works without sibling addons or a suite library

#### Scenario: Missing control API
- **WHEN** a preferred standard control or font object is unavailable
- **THEN** the supported fallback works or the unavailable action is explained without a dead control or Lua error



#### Scenario: Shared geometry
- **WHEN** an owned compact frame is laid out
- **THEN** spacing uses a 4-unit base, 8-unit compact padding, 12-unit content padding and 16-unit section gaps where applicable

#### Scenario: Font and ink roles
- **WHEN** owned text is drawn on black
- **THEN** compact supporting text uses GameFontHighlightSmall, body uses GameFontHighlight and headings use GameFontNormal with available fallbacks; primary/secondary ink approximate #DDDDDD/#AAAAAA while essential details remain readable

### Requirement: Meaningful color and readable content
The addon SHALL pair semantic color with visible text or a symbol, preserve configured colors and meanings, and use neutral titles except existing material item-quality names. Owned notices and explanations SHALL wrap or grow for long content, with complete action labels. It SHALL NOT globally reskin game or third-party frames.

#### Scenario: Long localized text
- **WHEN** a notice contains a long localized name and explanation
- **THEN** the essential recommendation and actions are fully readable without clipping

#### Scenario: Unavailable item icon
- **WHEN** item data or an icon is not cached
- **THEN** a safe fallback appears and the meaning remains readable

#### Scenario: Category distinction
- **WHEN** a KeepThat category or CV low state is displayed
- **THEN** its category or warning is named rather than inferred from an addon brand color


### Requirement: Independent visual dimming
Persistent custom surfaces SHALL default to pure black and support independent background and text/icon opacity. Background opacity zero SHALL draw no background, border, texture or accent fill. Text and icons SHALL follow their own opacity, including newly created elements. Native tooltip chrome is outside these custom-surface settings. Existing saved whole-toast opacity SHALL be migrated so effective brightness is preserved, without enabling a disabled feature.

#### Scenario: Background off
- **WHEN** background opacity is zero with any chosen color
- **THEN** no fill, border, texture or accent is drawn and text/icons retain their own opacity

#### Scenario: New elements
- **WHEN** text/icon opacity is reduced before a new row or toast is created
- **THEN** new and existing text/icons use the same configured opacity

#### Scenario: Upgrade
- **WHEN** an old saved appearance is loaded
- **THEN** configured colors, enabled states and effective opacity are preserved
