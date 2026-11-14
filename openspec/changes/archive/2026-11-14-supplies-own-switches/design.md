# Design

- Gates removed in `Triggers.Update` and `Triggers.Reminders` (supplies and reminders), `Status.Rows` (supply rows) and the `Controller.Evaluate` scan guard. Reagents keep the ammo switch as their master.
- `Supplies.Evaluate` already checks each supply's own switch, so no new setting is needed.
- Rejected: one new "Supplies" master switch. Each supply already has a switch, and a fifth setting adds a layer that would hide them.
