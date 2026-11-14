# Design

- `suppliesEnabled` is checked next to the ammo switch in `Triggers.Update`, `Triggers.Reminders`, `Status.Rows` and the `Controller.Evaluate` scan guard. `Supplies.Evaluate` keeps checking each item switch.
- Rejected: replacing the item switches by a threshold of 0. Every other warning has a checkbox and a slider, and a switch keeps the number you set.
