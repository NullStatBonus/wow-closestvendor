## MODIFIED Requirements

### Requirement: The reminder sound is a choice
The notification sound SHALL be one choice for every notification. The choices SHALL be the whisper ping, the minimap ping, the group invite, the ready check and none (silent), then any sound-pack sounds another installed addon shares. The choice SHALL be the Notification sound dropdown on the Appearance Sound tab and `/cvn sound <name>`. No other page SHALL have a sound control. Choosing one SHALL play it. A missing saved sound-pack sound SHALL play the default and stay saved.

#### Scenario: Choosing previews
- **WHEN** the player runs `/cvn sound ping`
- **THEN** the minimap ping plays and is saved

#### Scenario: Unknown name
- **WHEN** the player runs `/cvn sound banana`
- **THEN** chat lists the choices and nothing changes

#### Scenario: One control
- **WHEN** the player opens the Supplies page
- **THEN** it has no sound control

#### Scenario: Sound-pack sounds are listed
- **WHEN** another addon shares sounds through LibSharedMedia-3.0
- **THEN** the dropdown lists them after the built-in sounds, each labelled with "(sound pack)", and `/cvn sound <name>` accepts their names in any letter case

#### Scenario: No sound packs
- **WHEN** no installed addon shares sounds
- **THEN** only the built-in sounds and none are listed, and nothing else changes

#### Scenario: Sound-pack sound plays
- **WHEN** the player has chosen a sound-pack sound and a notification shows
- **THEN** that sound plays once

#### Scenario: Missing sound-pack sound
- **WHEN** the saved sound-pack sound is no longer shared (the pack is removed or not loaded yet)
- **THEN** a notification plays the whisper ping, the setting keeps the sound-pack choice, and that sound plays again once the pack is back

#### Scenario: Pack that loads late
- **WHEN** the sharing addon loads after Closest Vendor
- **THEN** its sounds appear the next time the dropdown or `/cvn sound` is used, without a reload
