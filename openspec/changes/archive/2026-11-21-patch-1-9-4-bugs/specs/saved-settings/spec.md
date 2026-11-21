## ADDED Requirements

### Requirement: Retired saved keys are dropped
At load the addon SHALL remove the account-level `hearth`, `lastOutside`, `professions` and `log` keys that settings per character replaced, and the retired `toastLocked` setting. It SHALL keep the account-level `cfg` and `hud` as the seed for a new character.

#### Scenario: Old account keys
- **WHEN** a character logs in and the account still holds `hearth`, `lastOutside`, `professions` or `log`
- **THEN** those keys are removed and the seed settings stay

