# Design

- `Adapter.stackSize` and `Adapter.ammoSpace` set a flag when the stack size is not a number. Core resets it before each purchase part and reads it after.
- A part is retried only if the flag is set and it asked and bought nothing (the merchant `confirm` and `buy` set `merchantActed`). A part that already asked or bought is never run again, so there is no second question and no double purchase.
- At most three retries per visit; `MERCHANT_SHOW` resets the count and `MERCHANT_CLOSED` clears the pending parts.
- Rejected: retrying on every `GET_ITEM_INFO_RECEIVED` while a merchant is open. It fires constantly and could repeat a question.
