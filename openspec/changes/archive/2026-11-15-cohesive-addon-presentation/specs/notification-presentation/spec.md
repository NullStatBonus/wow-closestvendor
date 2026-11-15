## ADDED Requirements

### Requirement: Per-character notification style
Appearance SHALL offer Notification style: Warning or Toast (default for fresh installs; existing users without a valid saved style retain Warning), saved per character and exposed as `appearance.notification-style` (`warning`/`toast`). The choice SHALL apply to every notification (automatic pins, row clicks, auction-house routes, class reminders and test messages) and preserve notice enabled state, triggers, priority, thresholds, timing, buying and routing.

#### Scenario: Default
- **WHEN** the addon has no existing account or character SavedVariables
- **THEN** Toast is selected and a disabled notice setting remains disabled

#### Scenario: Existing user upgrade
- **WHEN** existing account or character SavedVariables have no valid notification style
- **THEN** Warning is selected; valid saved Warning or Toast choices always remain unchanged

#### Scenario: Toast
- **WHEN** Toast is selected and an enabled notice fires
- **THEN** exactly one toast shows the same target, reason and candidate meaning; no duplicate Warning shows

#### Scenario: Persistent choice
- **WHEN** the style is changed through UI or CLI then the character relogs
- **THEN** the selected style persists and another character retains its own choice

#### Scenario: Interactive questions
- **WHEN** a destination or purchase requires confirmation in either style
- **THEN** the original question and acceptance/cancellation semantics remain intact



#### Scenario: Everything follows the style
- **WHEN** notification style is Warning
- **THEN** automatic-pin, row-click, auction-house, class-reminder and test notifications all show as Warnings; the persistent HUD and confirmation questions remain independent

### Requirement: One notification sound
Every notification SHALL play the notification sound (`remindSound`, default whisper ping) once when it shows; a batch shown on one check SHALL play it once. None SHALL be silent. While the on-screen notice is off, nothing SHALL show and no sound SHALL play; the chat line SHALL remain. A confirmation question is not a notification and SHALL play no notification sound.

#### Scenario: Route notification
- **WHEN** the addon pins a vendor without asking and the notice is on
- **THEN** the notification shows in the chosen style and the sound plays once

#### Scenario: Notice off
- **WHEN** the notice is off and a route is pinned
- **THEN** only the chat line appears, with no sound

### Requirement: Newest request wins
Only one notification SHALL be on screen. A new notification SHALL replace any other, live or sample, Toast or Warning. A status window click, a new demo or a preview SHALL first stop any running demo (restoring its previous waypoint) or preview. A click on a demo row SHALL route that row's kind for real.

#### Scenario: Click during a preview
- **WHEN** a sample toast is showing and the player clicks a routable status window row
- **THEN** the sample disappears and the live notification for the click shows

#### Scenario: Automatic route during a preview
- **WHEN** a sample toast is showing and the addon pins a vendor without asking
- **THEN** the live notification replaces the sample

#### Scenario: Click during the demo
- **WHEN** the demo is running and the player clicks a row
- **THEN** the demo stops, its later steps do nothing, and the click routes

### Requirement: Simple notification settings
Appearance SHALL have three tabs: Notifications, Status window and Sound. Notifications SHALL contain Style and one Preview, then the Toast controls; On-screen notice SHALL be on Home. The notification sound SHALL be on the Sound tab. While Style is Warning, the Toast controls SHALL be hidden and one line SHALL explain that Warning has no appearance or position settings.

#### Scenario: Warning selected
- **WHEN** Style is Warning
- **THEN** Toast opacity, scale, Move and Reset position are hidden and the explanation shows

### Requirement: Compact toast presentation
Toast SHALL use the shared compact family with neutral title, secondary context and content-driven height. It SHALL be mouse-transparent outside Move mode, use a separate anchor and dimming/scale settings, and last five seconds with newer messages replacing older ones. Warning SHALL retain the existing notice role and timing. Switching style SHALL NOT change the sound.

#### Scenario: Long route message
- **WHEN** a toast includes a vendor, zone, distance, reason and alternative candidate
- **THEN** all essential content wraps without clipping and the toast remains noninteractive

#### Scenario: Notice off
- **WHEN** notice is off and style is changed to Toast before a route is pinned
- **THEN** no on-screen notification appears and existing chat output is preserved

#### Scenario: New notice
- **WHEN** a newer notice arrives while a toast is showing
- **THEN** it replaces the old notice and gets its full five-second lifetime

#### Scenario: Toast geometry
- **WHEN** a toast is rendered
- **THEN** the baseline is 280 by 40 units with 28-unit icon when applicable; target, zone, distance, reason and alternate candidate wrap into a taller variant as needed

#### Scenario: Toast controls
- **WHEN** Appearance displays toast settings
- **THEN** black is the default surface; background and text/icon opacity accept 0–100, scale accepts 50–200, and Move and Reset position are offered, with no toast lock

