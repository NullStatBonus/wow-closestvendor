# craft-reminders Specification

## Purpose
Remind players who can make an item themselves to make it, instead of sending them to a vendor.

## Requirements

### Requirement: Mages are reminded to conjure
When food or water is low for a mage who knows a conjure spell for it, the addon SHALL remind the mage to conjure it and SHALL NOT ask about a vendor or set a pin for it. A mage who does not know a conjure spell for that kind SHALL get the vendor question as any other class does. The same thresholds and on/off settings as food and water apply.

#### Scenario: Mage knows Conjure Water
- **WHEN** a mage who knows Conjure Water has water at or below the threshold
- **THEN** a reminder says to conjure water and no vendor question or pin appears

#### Scenario: Mage without the spell
- **WHEN** a low-level mage who does not know Conjure Food has food at or below the threshold
- **THEN** the vendor question for food is asked

#### Scenario: Food spell known, water not
- **WHEN** a mage knows Conjure Food but not Conjure Water and both are low
- **THEN** the food reminder is shown and the water question goes to a vendor

### Requirement: Warlocks are reminded to create a healthstone
When a warlock knows a Create Healthstone spell and carries no healthstone of any rank, the addon SHALL remind the warlock to create one. The reminder SHALL have its own on/off setting, on by default, and SHALL NOT ask about a vendor or set a pin. A warlock who does not know the spell SHALL get no reminder.

#### Scenario: No healthstone
- **WHEN** a warlock who knows Create Healthstone has none in the bags
- **THEN** a reminder says to create a healthstone

#### Scenario: Has one
- **WHEN** the warlock carries any healthstone
- **THEN** no reminder is shown

#### Scenario: Spell not known
- **WHEN** a warlock below the level of Create Healthstone has none
- **THEN** no reminder is shown

#### Scenario: Reminder off
- **WHEN** the player switches the healthstone reminder off
- **THEN** no healthstone reminder is shown

### Requirement: Reminders are notices only
A reminder SHALL appear as one chat line and, when the on-screen notice setting is on, a notification in the player's chosen style (Toast or Warning), the same as every other notification. It SHALL NOT show a question, set a waypoint, or remove or replace any pin. It SHALL be shown once and not again until its condition clears and returns. It SHALL NOT appear in combat or in an instance and SHALL appear after combat when still true.

#### Scenario: Shown once
- **WHEN** a reminder was shown and the count stays low
- **THEN** it is not shown again

#### Scenario: Shown again after clearing
- **WHEN** the mage conjures water above the threshold and later falls to the threshold again
- **THEN** the reminder is shown again

#### Scenario: Pin untouched
- **WHEN** a repair pin is active and a conjure reminder appears
- **THEN** the repair pin stays

#### Scenario: In combat
- **WHEN** the condition becomes true during combat
- **THEN** the reminder is shown after combat ends if the condition still holds

#### Scenario: Follows the style
- **WHEN** Notification style is Toast and a mage's food reminder shows
- **THEN** it shows as a Toast, not a Warning

### Requirement: Reminder test command
The addon SHALL provide `/cvn test remind` to show the reminder for the player's class now, regardless of class, count, warning settings, combat or instance. It SHALL be a notification: shown and sounded only while the on-screen notice is on. A class without a real reminder SHALL get a plain test line.

#### Scenario: Test as a mage
- **WHEN** a mage runs `/cvn test remind`
- **THEN** the conjure reminder is shown

#### Scenario: Test as a warrior
- **WHEN** a warrior runs `/cvn test remind`
- **THEN** chat shows a test line, the notification shows it, and the sound plays

#### Scenario: Test always works
- **WHEN** the player runs `/cvn test remind` in combat or with every warning switched off
- **THEN** the reminder and the sound still happen

### Requirement: A reminder plays a sound
A reminder SHALL play the notification sound, once for a batch of reminders shown together, and only while the on-screen notice is on. The default SHALL be the whisper ping. A sound the game cannot play SHALL be skipped without an error.

#### Scenario: Default sound
- **WHEN** a mage's food reminder shows with no setting changed
- **THEN** the whisper ping plays once

#### Scenario: Two reminders at once
- **WHEN** food and water reminders show on the same check
- **THEN** one sound plays

#### Scenario: None
- **WHEN** the sound is set to none
- **THEN** a reminder shows with no sound

#### Scenario: Test reminder
- **WHEN** the player runs `/cvn test remind` with the notice on
- **THEN** the sound plays

#### Scenario: Notice off
- **WHEN** the on-screen notice is off and a reminder is due
- **THEN** the chat line prints and no sound plays

### Requirement: The reminder sound is a choice
The notification sound SHALL be one choice for every notification. The choices SHALL be the whisper ping, the minimap ping, the group invite, the ready check and none; none is silent. The choice SHALL be the Notification sound dropdown on the Appearance Sound tab, for every class, and settable with `/cvn sound <name>`. No other settings page SHALL have a sound control. Choosing one SHALL play it.

#### Scenario: Choosing previews
- **WHEN** the player runs `/cvn sound ping`
- **THEN** the minimap ping plays and is saved

#### Scenario: Unknown name
- **WHEN** the player runs `/cvn sound banana`
- **THEN** chat lists the choices and nothing changes

#### Scenario: One control
- **WHEN** the player opens the Supplies page
- **THEN** it has no sound control
