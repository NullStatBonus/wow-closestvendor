# Design

- The unit filter in the frame's event handler gains `UNIT_PET`. The game always passes the unit, so tests now pass `"player"`.
- The guard is in `Controller.Evaluate`, not `supplyState()`: the status window and the test commands read supplies on their own and must still get counts.
- Rejected: caching one bag scan per event for both the controller and the window. It saves about 100 calls per burst and adds a stale-count risk.
