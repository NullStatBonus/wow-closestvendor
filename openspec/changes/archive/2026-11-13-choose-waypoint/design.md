# Design

- `Nav.Set` and `Nav.Select` take the preference. The adapter list is reordered with the preferred adapter first, so fallback is the same loop as before. Chat is never a preference, and an unknown value is ignored.
- Rejected: hiding the other adapters. A missing preferred method would then leave only chat.
