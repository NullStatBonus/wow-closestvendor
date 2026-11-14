# Design

- `reagentsEnabled` replaces `ammoEnabled` as the gate for reagent questions in `Triggers.Update` and the status window reagent rows. `ammoEnabled` now gates ammo only.
- Migration in `Core.init`, before the defaults fill: if `reagentsEnabled` is nil and `ammoEnabled` is set, copy it. A new character gets the default (on).
- Rejected: keeping one combined switch on the Ammo page. A reagent switch that lives on the Ammo page is confusing.
