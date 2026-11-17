## 1. Purchases

- [x] 1.1 Give ammo purchases their own dialog; close both purchase dialogs on MERCHANT_CLOSED
- [x] 1.2 At Yes, buy only if `merchantItemId(index)` still matches each planned item
- [x] 1.3 Tests in `test_ammo`, `test_reagents`, `test_core`; mutation-checked

## 2. Declined requests

- [x] 2.1 `Triggers.Release(trigger, id)` ends the matching active request and restores a covered sell
- [x] 2.2 No/Escape (`reason == "clicked"`) and no vendor release the request; the next check runs shortly after
- [x] 2.3 Tests in `test_triggers`, `test_controller`, `test_core`; mutation-checked

## 3. Death

- [x] 3.1 Evaluate and the trainer check treat dead or ghost like combat; PLAYER_ALIVE and PLAYER_UNGHOST check again
- [x] 3.2 Tests in `test_controller` and `test_core`; mutation-checked

## 4. Docs

- [x] 4.1 Test plan in-game checks
- [ ] 4.2 In-game verification on both clients
