# TC-04 — Stock Management
**Module:** Product Stocks, Transactions, Lots (FIFO), Checkpoints, Stock Locations, Stock Person  
**Based on:** EPIC-05, EPIC-19

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-04-01 — Stock Deposit

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-04-01-01 | Deposit stock for a product | Product with `enable_stock=true`; stock record exists | 1. Navigate to `/stocks/:id`<br>2. Click Deposit<br>3. Enter quantity and note<br>4. Submit | `product_stock.amount` increases by deposited qty; transaction record created with `transaction_type=deposit` | ⏳ |
| TC-04-01-02 | Deposit creates a new lot | Stock enabled product | 1. Deposit stock | New `StockLot` created with `remaining_quantity = deposited qty` and `created_at` timestamp | ⏳ |
| TC-04-01-03 | Deposit with note | — | 1. Enter note in deposit form | Transaction saved with `note` field populated | ⏳ |
| TC-04-01-04 | Deposit quantity must be positive | — | 1. Enter 0 or negative quantity | 422; validation error "must be greater than 0" | ⏳ |
| TC-04-01-05 | Non-stock product cannot be deposited | Product with `enable_stock=false` | 1. Attempt to navigate to stock deposit for non-stock product | 404 or redirect | ⏳ |

---

## TC-04-02 — Stock Withdrawal

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-04-02-01 | Withdraw stock | Product with available stock > 0 | 1. Click Withdraw<br>2. Enter qty<br>3. Submit | `product_stock.amount` decreases; transaction record created with `transaction_type=withdraw` | ⏳ |
| TC-04-02-02 | Withdraw more than available | Stock = 5 | 1. Withdraw 10 | 422; "insufficient stock" or validation error | ⏳ |
| TC-04-02-03 | FIFO withdrawal consumes oldest lot first | Two lots: lot1 qty=5 (older), lot2 qty=3 (newer) | 1. Withdraw 7 | Lot1 fully consumed (remaining=0); lot2 remaining=1 | ⏳ |
| TC-04-02-04 | Withdraw matches lot allocations | Order line withdrawal | 1. Withdraw via order line | `order_line_lot_allocations` created matching lots consumed | ⏳ |

---

## TC-04-03 — Stock Reset

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-04-03-01 | Reset stock to specific value | Admin; stock exists | 1. Click Reset<br>2. Enter new quantity<br>3. Submit | `product_stock.amount` set to new value; transaction recorded with `transaction_type=reset` | ⏳ |
| TC-04-03-02 | Reset to zero | — | 1. Reset with qty=0 | `product_stock.amount = 0`; all lots zeroed out | ⏳ |
| TC-04-03-03 | Reset requires permission | User without stock management permission | 1. Attempt stock reset | 403 Forbidden | ⏳ |

---

## TC-04-04 — Stock Transactions

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-04-04-01 | Transaction list shows all types | Deposit, withdraw, reset performed | 1. Navigate to stock transaction list for a product | All transaction records visible with type, qty, date, note | ⏳ |
| TC-04-04-02 | Transaction list is paginated | More than 25 transactions | 1. Navigate to transactions | Pagination controls present; older records accessible via next page | ⏳ |
| TC-04-04-03 | Transaction filter by type | Mixed transactions | 1. Filter by `deposit` | Only deposit transactions shown | ⏳ |
| TC-04-04-04 | Transaction filter by date range | — | 1. Apply date range | Only transactions in range shown | ⏳ |
| TC-04-04-05 | Transactions are append-only | Any transaction | 1. Inspect for edit/delete options | No edit or delete button on individual transactions | ⏳ |

---

## TC-04-05 — Stock Checkpoint

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-04-05-01 | Create checkpoint | Admin; stock has history | 1. Navigate to stock checkpoint UI<br>2. Set checkpoint date<br>3. Submit | Checkpoint created; `stock_checkpoint.amount` = current stock at that date | ⏳ |
| TC-04-05-02 | Stock at-date query respects checkpoints | Checkpoint created | 1. Query stock before checkpoint date | Returns checkpoint amount; not current amount | ⏳ |
| TC-04-05-03 | Checkpoint date cannot be in the future | — | 1. Set checkpoint date to tomorrow | 422; validation error | ⏳ |

---

## TC-04-06 — Stock Index & Overview

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-04-06-01 | Stock index shows all stock-enabled products | Products with `enable_stock=true` | 1. Navigate to `/stocks` | All stock-enabled products listed with current amount and stock person | ⏳ |
| TC-04-06-02 | Stock index excludes non-stock products | Products with `enable_stock=false` | 1. Navigate to `/stocks` | Non-stock products not in list | ⏳ |
| TC-04-06-03 | Stock person column visible in index | Stock record with `stock_person_id` set | 1. Navigate to `/stocks` | "Stock Person" column shows person's full name | ⏳ |
| TC-04-06-04 | Stock person "—" when unassigned | Stock with no `stock_person_id` | 1. Navigate to `/stocks` | Stock person cell shows "—" | ⏳ |

---

## TC-04-07 — Stock Assignment (Stock Person & Locations) (EPIC-19)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-04-07-01 | Assign stock person | Stock record exists; users exist | 1. Navigate to `/stocks/:id`<br>2. Select user in Stock Person dropdown<br>3. Submit | `product_stock.stock_person_id` updated | ⏳ |
| TC-04-07-02 | Assign stock locations | Stock locations exist | 1. Select multiple locations in dropdown<br>2. Submit | `ProductStockLocation` join records created for selected locations | ⏳ |
| TC-04-07-03 | Remove stock location | Stock record with assigned locations | 1. Deselect a location<br>2. Submit | Join record removed; only selected locations remain | ⏳ |
| TC-04-07-04 | Clear stock person | Stock person currently assigned | 1. Clear Tom Select dropdown<br>2. Submit | `stock_person_id` set to null | ⏳ |
| TC-04-07-05 | Tom Select used for all dropdowns | Stock show page | 1. Inspect stock show page | Tom Select library active on stock_person and stock_location dropdowns | ⏳ |
