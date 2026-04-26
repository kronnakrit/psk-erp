# EPIC-17 — Automatic FIFO Cost Assignment on Order Lines

**Phase:** 17
**Status:** 🟢 Completed
**Goal:** Sales order lines automatically deduct stock in FIFO lot order, stock can go negative when no lots are available, and each order line displays a real-time weighted-average COGS computed from the lots consumed — with the lot picker column removed from the order form entirely.

---

## Legend

| Symbol         | Meaning                  |
| -------------- | ------------------------ |
| 🔴 Not Started | Work has not begun       |
| 🟡 In Progress | Actively being worked on |
| 🟢 Completed   | Done and verified        |
| `[ ]`          | Task not started         |
| `[~]`          | Task in progress         |
| `[x]`          | Task completed           |

---

## Background & Design Decisions

### Current behaviour (EPIC-16)
- The order form displays a **LOT** column — a dropdown that requires the sales staff to manually select a `ProductLot`.
- `OrderLine` validates `lot_required_if_stock_enabled` (lot must be chosen) and `lot_quantity_not_exceeded` (single-lot cap).
- `ProductStock#amount` validates `>= 0` — stock cannot go negative.
- One `OrderLine` → at most one `ProductLot`.

### Target behaviour (EPIC-17)
- **LOT column removed** from the order form UI. Users never pick a lot manually.
- The backend **automatically allocates lots in FIFO order** (`received_date ASC`) at save time.
- **Stock can go negative** — if no active lots exist, the order line still saves; a phantom (nil-lot) allocation is recorded.
- **Retroactive lot assignment**: when a new PO is confirmed and lots are created, `ConfirmPurchaseOrderService` checks for existing phantom allocations for that product and assigns them to the new lot (oldest-pending first).
- Each order line stores a **`cogs`** column (weighted-average unit cost across all lots consumed).
- The order form shows a read-only **COST** column. When the user changes quantity, a debounced API call computes the projected COGS without writing to the DB.
- A new **`order_line_lot_allocations`** table records which lots (and how much of each) were used per order line, enabling correct lot `remaining_quantity` tracking and future audit.

### Performance guardrails
- The UI COGS preview calls `GET /api/v1/catalogs/products/:id/fifo_cost?quantity=X` — a **read-only dry-run** (no DB writes). The endpoint is debounced at 400 ms in the Stimulus controller.
- The endpoint queries only `ProductLot` records (indexed on `product_id`, `status`, `received_date`) — no N+1 risk.
- Actual allocation (writes) only happens on `OrderLine` `after_create` / `after_update` / `before_destroy` callbacks, wrapped in a transaction.

---

## Stories

### STORY-17-01 — Remove Negative-Stock & Lot-Required Constraints

**Status:** 🟢 Completed
**Description:** Remove the model-level constraints that currently prevent stock from going negative and require a lot on every stock-enabled order line. This is a prerequisite for automatic FIFO allocation.

**User Perspective:**
As a developer, I want to remove the lot-selection requirement and negative-stock guard so that EPIC-17 automatic allocation can be wired in without validation conflicts.

**Acceptance Criteria:**

| #     | Given                                                                                              | When                                                                                        | Then                                                                                                                            |
| ----- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A stock-enabled product with no active lots and `ProductStock#amount = 0`                         | `OrderLine` is created with `product_lot_id: nil`                                           | Record saves successfully; no validation error for `product_lot`                                                                |
| AC-02 | A `ProductStock` with `amount = 0`                                                                | `stock.withdraw!(amount: 5)` is called                                                      | `ProductStock#amount` becomes `-5`; an OB transaction is recorded; no `ActiveRecord::RecordInvalid` raised                    |
| AC-03 | An `OrderLine` being updated where new `quantity` exceeds the single lot's `remaining_quantity`   | `order_line.update!(quantity: 99999)`                                                       | `lot_quantity_not_exceeded` validation does **not** fire; record saves                                                          |
| AC-04 | An `OrderLine` being created for a stock-enabled product with `product_lot_id: nil`               | `order_line.valid?`                                                                         | `errors[:product_lot]` is empty; `errors[:base]` is empty                                                                      |

**Edge Cases:**

- `ProductStock#holding_amount` validation `>= 0` is **not** changed in this story.
- Existing `lot_quantity_not_exceeded` and `lot_required_if_stock_enabled` private methods should be removed (not just disabled) to avoid dead code.

| #          | Task                                                                                                         | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------ | ------ |
| T-17-01-01 | Remove `validates :amount, numericality: { greater_than_or_equal_to: 0 }` from `ProductStock`               | `[x]`  |
| T-17-01-02 | Remove `lot_required_if_stock_enabled` validation and private method from `OrderLine`                        | `[x]`  |
| T-17-01-03 | Remove `lot_quantity_not_exceeded` validation and private method from `OrderLine`                            | `[x]`  |
| T-17-01-04 | Remove `validate :lot_required_if_stock_enabled` and `validate :lot_quantity_not_exceeded` calls in `OrderLine` | `[x]`  |
| T-17-01-05 | Write RSpec model spec: `ProductStock` allows negative `amount` after `withdraw!`                            | `[x]`  |
| T-17-01-06 | Write RSpec model spec: `OrderLine` saves with `product_lot_id: nil` for stock-enabled product               | `[x]`  |

---

### STORY-17-02 — `OrderLineLotAllocation` Model & Migration

**Status:** 🟢 Completed
**Description:** Introduce the `order_line_lot_allocations` table that records exactly which lot (and how much quantity at what unit cost) was consumed for each order line. Supports multi-lot splits and phantom (nil-lot) records for negative-stock situations.

**User Perspective:**
As a developer, I want a normalised allocation table so that FIFO lot deductions, COGS calculation, and lot `remaining_quantity` bookkeeping are all traceable and reversible.

**Acceptance Criteria:**

| #     | Given                              | When                                                  | Then                                                                                                          |
| ----- | ---------------------------------- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| AC-01 | Migration runs on a clean DB       | `rails db:migrate`                                    | `order_line_lot_allocations` table exists with columns: `id`, `order_line_id`, `product_lot_id` (nullable), `allocated_quantity` (decimal precision 8 scale 2), `unit_cost` (decimal precision 20 scale 2), `created_at`, `updated_at` |
| AC-02 | `OrderLineLotAllocation` is valid  | Model instantiated with valid attributes               | `valid?` returns `true`                                                                                       |
| AC-03 | `product_lot_id` is nil            | Model instantiated with `product_lot_id: nil`          | `valid?` returns `true` (phantom allocation for negative stock)                                               |
| AC-04 | `allocated_quantity <= 0`          | `valid?` called                                       | `errors[:allocated_quantity]` contains a message                                                              |

**Edge Cases:**

- Index on `order_line_id` for fast lookup when reversing allocations.
- `dependent: :destroy` on `OrderLine has_many :order_line_lot_allocations`.
- `OrderLineLotAllocation` belongs_to `:product_lot, optional: true`.

| #          | Task                                                                                                                           | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-17-02-01 | Create migration `create_order_line_lot_allocations`: columns as described in AC-01 + index on `order_line_id`                | `[x]`  |
| T-17-02-02 | Create `app/models/order_line_lot_allocation.rb`: associations, presence/numericality validations                              | `[x]`  |
| T-17-02-03 | Add `has_many :order_line_lot_allocations, dependent: :destroy` to `OrderLine`                                                 | `[x]`  |
| T-17-02-04 | Add `cogs` column (decimal precision 20 scale 2 default 0) to `order_lines` via migration                                     | `[x]`  |
| T-17-02-05 | Write RSpec model spec for `OrderLineLotAllocation` validations and associations                                               | `[x]`  |
| T-17-02-06 | Write RSpec factory `order_line_lot_allocation` (FactoryBot)                                                                   | `[x]`  |

---

### STORY-17-03 — `FifoLotAllocationService`

**Status:** 🟢 Completed
**Description:** A pure-Ruby service that, given a product and a quantity (in base units), computes the FIFO lot allocation plan and optionally executes it (deducting `remaining_quantity` from each lot and persisting `OrderLineLotAllocation` records).

**User Perspective:**
As a developer, I want a single, testable service to own all FIFO logic so that order line callbacks and the API preview endpoint can share the same allocation algorithm.

**Acceptance Criteria:**

| #     | Given                                                                                          | When                                                                                       | Then                                                                                                                                                |
| ----- | ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Product has lots: Lot A (`remaining_quantity: 10, unit_cost: 20`), Lot B (`remaining_quantity: 5, unit_cost: 30`); requested quantity `= 12` | `FifoLotAllocationService.new(product, 12).call(dry_run: true)` | Returns `{ allocations: [{lot: LotA, qty: 10, unit_cost: 20}, {lot: LotB, qty: 2, unit_cost: 30}], weighted_avg_cost: (10*20 + 2*30) / 12 = 21.67, phantom_qty: 0 }` |
| AC-02 | Product has no active lots; requested quantity `= 5`                                           | `FifoLotAllocationService.new(product, 5).call(dry_run: true)`                             | Returns `{ allocations: [], weighted_avg_cost: 0, phantom_qty: 5 }` (entire quantity is a phantom)                                                  |
| AC-03 | Product has Lot A (`remaining_quantity: 3, unit_cost: 50`); requested quantity `= 8`           | `FifoLotAllocationService.new(product, 8).call(dry_run: true)`                             | Returns `{ allocations: [{lot: LotA, qty: 3, unit_cost: 50}], weighted_avg_cost: (3*50+0) / 8 = 18.75, phantom_qty: 5 }` (partial lot + phantom)  |
| AC-04 | Same setup as AC-01 but `dry_run: false`, with `order_line` passed                            | `FifoLotAllocationService.new(product, 12).call(dry_run: false, order_line: ol)`           | `LotA.remaining_quantity` decremented by 10; `LotB.remaining_quantity` decremented by 2; two `OrderLineLotAllocation` records created for `ol`; one phantom record created if any phantom qty |
| AC-05 | `dry_run: false` called inside a transaction that rolls back                                   | Outer transaction rolled back                                                              | No `ProductLot` or `OrderLineLotAllocation` records are mutated                                                                                     |

**Edge Cases:**

- The service operates only on lots with `status = 'active'` and `remaining_quantity > 0`, ordered by `received_date ASC`.
- Unit conversion: the caller must pass quantity already converted to **base units** (same unit as `ProductLot#original_quantity`).
- `weighted_avg_cost` is rounded to 2 decimal places.
- Phantom qty (negative-stock portion) creates a single `OrderLineLotAllocation` with `product_lot_id: nil`, `unit_cost: 0`.

| #          | Task                                                                                                                   | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------- | ------ |
| T-17-03-01 | Create `app/services/fifo_lot_allocation_service.rb` with `#call(dry_run:, order_line: nil)` interface                 | `[x]`  |
| T-17-03-02 | Implement FIFO lot selection loop (active lots, `received_date ASC`, consume until quantity met)                        | `[x]`  |
| T-17-03-03 | Implement phantom qty handling (nil-lot allocation when stock insufficient)                                             | `[x]`  |
| T-17-03-04 | Implement `weighted_avg_cost` calculation                                                                               | `[x]`  |
| T-17-03-05 | Implement `dry_run: false` path: decrement `lot.remaining_quantity`, create `OrderLineLotAllocation` records            | `[x]`  |
| T-17-03-06 | Write RSpec service spec: full-lot coverage (AC-01)                                                                     | `[x]`  |
| T-17-03-07 | Write RSpec service spec: no lots / all phantom (AC-02)                                                                 | `[x]`  |
| T-17-03-08 | Write RSpec service spec: partial lot + phantom (AC-03)                                                                 | `[x]`  |
| T-17-03-09 | Write RSpec service spec: dry_run false persists allocations and decrements lots (AC-04)                                | `[x]`  |
| T-17-03-10 | Write RSpec service spec: rollback safety (AC-05)                                                                       | `[x]`  |

---

### STORY-17-04 — Wire FIFO Service into `OrderLine` Lifecycle Callbacks

**Status:** 🟢 Completed
**Description:** Replace the current manual lot deduction in `OrderLine` callbacks with calls to `FifoLotAllocationService`. On create, FIFO allocations are applied. On quantity update, previous allocations are reversed and FIFO re-runs. On destroy, all allocations are reversed. The `cogs` column on `order_lines` is set to the weighted average cost returned by the service.

**User Perspective:**
As a sales staff member, I want the system to automatically pick the right lots and record the cost of goods so that I don't need to think about stock lots at all.

**Acceptance Criteria:**

| #     | Given                                                                                                           | When                                                                                       | Then                                                                                                                                                      |
| ----- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Stock-enabled product; Lot A `remaining_qty: 10, cost: 20`; Lot B `remaining_qty: 5, cost: 30`                 | `OrderLine.create!(quantity: 12, …)`                                                        | `order_line.cogs = 21.67`; `OrderLineLotAllocation` count = 2; `LotA.remaining_quantity = 0`; `LotB.remaining_quantity = 3`; `ProductStock#amount` decremented by 12 (base units) |
| AC-02 | Same order line from AC-01; user updates quantity to `8`                                                        | `order_line.update!(quantity: 8)`                                                           | Old allocations destroyed; `LotA.remaining_quantity` restored to 10 then re-consumed for 8; `order_line.cogs = 20.0`; `LotB.remaining_quantity = 5`; `ProductStock` re-adjusted |
| AC-03 | Order line from AC-02 deleted                                                                                    | `order_line.destroy`                                                                        | All `OrderLineLotAllocation` records destroyed; `LotA.remaining_quantity` restored by 8; `ProductStock#amount` incremented by 8                           |
| AC-04 | Product has no active lots; stock is 0                                                                           | `OrderLine.create!(quantity: 5, …)`                                                         | Order line saves; `order_line.cogs = 0`; phantom allocation created (`product_lot_id: nil`); `ProductStock#amount = -5`                                   |
| AC-05 | Phantom allocation order line exists; then PO confirmed, creating Lot C (`quantity: 20, cost: 40`)             | `ConfirmPurchaseOrderService#call!` runs                                                   | Lot C `remaining_quantity` decremented by 5 (absorbed by phantom); phantom `OrderLineLotAllocation` replaced with real allocation to Lot C; `order_line.cogs = 40.0`; `ProductStock#amount` adjusted correctly |
| AC-06 | Any `OrderLine` for a product with `enable_stock: false`                                                        | Created / updated / destroyed                                                               | No `OrderLineLotAllocation` records created; `cogs = 0`                                                                                                   |
| AC-07 | DB transaction fails mid-allocation                                                                              | Outer `ApplicationRecord.transaction` rolls back                                            | `ProductStock`, `ProductLot`, and `OrderLineLotAllocation` all remain unchanged                                                                            |

**Edge Cases:**

- `handle_stock_on_update` must detect quantity change **in base units** (accounting for `unit_definition.ratio`).
- Phantom lot absorption in `ConfirmPurchaseOrderService` (AC-05) must process pending phantom allocations in `order_line` creation-time order (oldest first) up to the new lot's quantity.
- `product_lot_id` FK on `order_lines` remains in schema but is now **nullable and unused by new code** — it is not removed in this epic to avoid a breaking migration. Old rows from EPIC-16 testing retain their `product_lot_id`.

| #          | Task                                                                                                                                           | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-17-04-01 | Rewrite `handle_stock_on_create` in `OrderLine`: call `FifoLotAllocationService#call(dry_run: false)`, set `self.cogs`                         | `[x]`  |
| T-17-04-02 | Rewrite `handle_stock_on_update` in `OrderLine`: reverse old `OrderLineLotAllocation` records (restore lot qty + stock), then re-run FIFO      | `[x]`  |
| T-17-04-03 | Rewrite `handle_stock_on_destroy` in `OrderLine`: reverse all `OrderLineLotAllocation` records (restore lot qty + stock)                       | `[x]`  |
| T-17-04-04 | Add private method `reverse_allocations!(order_line)` to share reversal logic between update and destroy                                        | `[x]`  |
| T-17-04-05 | Add `before_validation :compute_base_quantity` to convert `quantity * unit_definition.ratio` for service call                                   | `[x]`  |
| T-17-04-06 | Update `ConfirmPurchaseOrderService`: after creating a new lot, call new `PhantomAllocationAbsorberService` for that product                     | `[x]`  |
| T-17-04-07 | Create `app/services/phantom_allocation_absorber_service.rb`: finds all nil-lot `OrderLineLotAllocation` records for the product (oldest `order_line` first), replaces them with the new lot up to its capacity, updates `cogs` on each affected `order_line` | `[x]`  |
| T-17-04-08 | Write RSpec model spec: AC-01 create with multi-lot split                                                                                       | `[x]`  |
| T-17-04-09 | Write RSpec model spec: AC-02 update re-runs FIFO                                                                                               | `[x]`  |
| T-17-04-10 | Write RSpec model spec: AC-03 destroy reverses allocations                                                                                      | `[x]`  |
| T-17-04-11 | Write RSpec model spec: AC-04 phantom allocation on negative stock                                                                              | `[x]`  |
| T-17-04-12 | Write RSpec service spec: `PhantomAllocationAbsorberService` absorbs phantom allocations into new lot (AC-05)                                   | `[x]`  |
| T-17-04-13 | Write RSpec model spec: AC-06 non-stock product produces no allocations                                                                         | `[x]`  |

---

### STORY-17-05 — COGS Preview API Endpoint

**Status:** 🟢 Completed
**Description:** A read-only JSON endpoint that returns the projected FIFO COGS for a given product and quantity. Used by the Stimulus controller to update the order line cost display in real time without writing to the DB.

**User Perspective:**
As a sales staff member, I want to see the cost of goods update as I type the quantity so that I have immediate visibility into the projected margin before submitting the order.

**Acceptance Criteria:**

| #     | Given                                                                                                   | When                                                                       | Then                                                                                                                                              |
| ----- | ------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Authenticated user; stock-enabled product with Lot A (`qty: 10, cost: 20`), Lot B (`qty: 5, cost: 30`) | `GET /api/v1/catalogs/products/:id/fifo_cost?quantity=12&unit_definition_id=Y` | Response `200` JSON: `{ weighted_avg_cost: 21.67, allocations: [{lot_number: "LOT-…", allocated_qty: 10, unit_cost: 20.0}, {…, allocated_qty: 2, unit_cost: 30.0}], has_phantom: false }` |
| AC-02 | Product has no active lots                                                                              | `GET /api/v1/catalogs/products/:id/fifo_cost?quantity=5`                   | Response `200` JSON: `{ weighted_avg_cost: 0, allocations: [], has_phantom: true }`                                                               |
| AC-03 | `quantity` param is missing                                                                             | `GET /api/v1/catalogs/products/:id/fifo_cost`                              | Response `422` JSON: `{ error: "quantity is required" }`                                                                                          |
| AC-04 | `quantity` param is `0` or negative                                                                     | `GET /api/v1/catalogs/products/:id/fifo_cost?quantity=0`                   | Response `422` JSON: `{ error: "quantity must be greater than 0" }`                                                                               |
| AC-05 | `unit_definition_id` provided                                                                           | `GET /api/v1/catalogs/products/:id/fifo_cost?quantity=2&unit_definition_id=Y` | Quantity converted to base units via `UnitDefinition#ratio` before FIFO calculation; `weighted_avg_cost` reflects base-unit cost                  |
| AC-06 | Unauthenticated request                                                                                 | `GET /api/v1/catalogs/products/:id/fifo_cost?quantity=1`                   | Response `401`                                                                                                                                    |

**Edge Cases:**

- This endpoint calls `FifoLotAllocationService#call(dry_run: true)` — **zero DB writes**.
- Route: nested under `api/v1/catalogs/products` alongside existing `lots` and `last_purchase_cost` actions.
- The response `allocations` array is ordered oldest lot first (FIFO order).

| #          | Task                                                                                               | Status |
| ---------- | -------------------------------------------------------------------------------------------------- | ------ |
| T-17-05-01 | Add `GET /api/v1/catalogs/products/:id/fifo_cost` route in `config/routes.rb`                      | `[x]`  |
| T-17-05-02 | Add `fifo_cost` action to `Api::V1::Catalogs::ProductsController`                                  | `[x]`  |
| T-17-05-03 | Apply `unit_definition.ratio` conversion when `unit_definition_id` param is present               | `[x]`  |
| T-17-05-04 | Return `422` for missing / invalid `quantity` param                                                | `[x]`  |
| T-17-05-05 | Write RSpec request spec: AC-01 multi-lot response shape                                           | `[x]`  |
| T-17-05-06 | Write RSpec request spec: AC-02 no lots / phantom response                                         | `[x]`  |
| T-17-05-07 | Write RSpec request spec: AC-03 missing quantity returns 422                                       | `[x]`  |
| T-17-05-08 | Write RSpec request spec: AC-04 zero quantity returns 422                                         | `[x]`  |
| T-17-05-09 | Write RSpec request spec: AC-05 unit definition ratio conversion                                   | `[x]`  |
| T-17-05-10 | Write RSpec request spec: AC-06 unauthenticated returns 401                                        | `[x]`  |

---

### STORY-17-06 — Remove Lot Column & Add Real-Time COGS Display in Order Form

**Status:** 🟢 Completed
**Description:** Remove the LOT column (header + cell + Stimulus lot-picker logic) from the order form. Add a read-only **COST** column that displays the projected weighted-average unit cost, updated in real time as the user changes quantity (debounced API call).

**User Perspective:**
As a sales staff member, I want to see the cost of goods per line update as I type the quantity, without needing to select a lot, so that I can focus on the sale rather than stock management.

**Acceptance Criteria:**

| #     | Given                                                                               | When                                                                                  | Then                                                                                                                        |
| ----- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | User on `GET /orders/new` page                                                      | Page loads                                                                            | Table header row shows: PRODUCT \| DESCRIPTION \| UNIT \| QTY \| UNIT PRICE \| DISCOUNT \| COST \| TOTAL; no "LOT" header |
| AC-02 | User selects a stock-enabled product with 2 active lots                              | Product is selected from the typeahead                                                | COST cell shows the weighted-average cost for quantity `1` (default), e.g. `฿20.00`                                        |
| AC-03 | User changes quantity to `12` (spanning 2 lots)                                     | User stops typing for 400 ms                                                          | COST cell updates to the weighted-average cost for qty `12`; no page reload                                                 |
| AC-04 | Product has no active lots (negative-stock scenario)                                | User selects product and sets any quantity                                             | COST cell shows `฿0.00` and a ghost indicator `(no stock)` in text-yellow-600                                               |
| AC-05 | User changes unit from the unit dropdown                                             | Unit changes                                                                          | COST cell recalculates using new `unit_definition_id` in the API call                                                       |
| AC-06 | API call is in flight (loading)                                                     | User types rapidly                                                                    | Only one API call fires per 400 ms idle window (debounce); COST cell shows `—` while loading                                |
| AC-07 | User opens an existing order for editing (`GET /orders/:id/edit`)                   | Page loads                                                                            | No LOT column visible; COST column shows saved `cogs` value per line                                                        |

**Edge Cases:**

- If `product_id` is blank (no product selected), COST cell shows `—`.
- `order-line-search` Stimulus controller must **not** call `/api/v1/catalogs/products/:id/lots` anymore — that API call is removed from the controller.
- The COST cell is purely informational and is **not** a form field — it is not submitted with the form.
- `lotAvailableDisplay` target (added in session) is also removed from the template.

| #          | Task                                                                                                                                                          | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-17-06-01 | Remove `<th>` for LOT from `app/views/orders/_form.html.erb`                                                                                                 | `[x]`  |
| T-17-06-02 | Remove `<th>` for LOT from `app/views/orders/_form.html.erb` (already in T-17-06-01; add `<th>` for COST before TOTAL)                                       | `[x]`  |
| T-17-06-03 | Remove lot picker `<td>` block from `app/views/orders/_order_line_fields.html.erb`                                                                            | `[x]`  |
| T-17-06-04 | Add read-only COST `<td>` to `app/views/orders/_order_line_fields.html.erb`: `data-order-line-search-target="cogsDisplay"` with initial `—`                   | `[x]`  |
| T-17-06-05 | Remove `_fetchLots`, `onLotChange`, `_updateLotAvailableDisplay`, `_lotsData` from `app/javascript/controllers/order_line_search_controller.js`               | `[x]`  |
| T-17-06-06 | Remove `lotPicker`, `lotCell`, `productLotId`, `lotAvailableDisplay` from `static targets` in `order_line_search_controller.js`                               | `[x]`  |
| T-17-06-07 | Add `_fetchFifoCost(productId, quantity, unitDefinitionId)` method to `order_line_search_controller.js`: calls `GET /api/v1/catalogs/products/:id/fifo_cost`, updates `cogsDisplay`; shows `฿0.00 (no stock)` in yellow on `has_phantom: true` | `[x]`  |
| T-17-06-08 | Debounce `_fetchFifoCost` at 400 ms; cancel in-flight call if new one fires before settling                                                                   | `[x]`  |
| T-17-06-09 | Call `_fetchFifoCost` on: product selection, quantity change, unit change                                                                                     | `[x]`  |
| T-17-06-10 | Show `—` in COST cell while API call is in flight                                                                                                             | `[x]`  |
| T-17-06-11 | For edit page: on `connect()`, if `productId` and `quantity` are already populated, call `_fetchFifoCost` to restore COST display from saved `cogs`            | `[x]`  |
| T-17-06-12 | Run `bin/rails tailwindcss:build` to include new utility classes for yellow ghost text                                                                        | `[x]`  |

---

### STORY-17-07 — Update Order Show Page & Order Line Partial

**Status:** 🟢 Completed
**Description:** Remove the LOT column from the order show page and the `_order_line` partial. Add a read-only COST column that displays `order_line.cogs` (the stored weighted-average unit cost) from the database.

**User Perspective:**
As a sales staff member reviewing a placed order, I want to see the cost of goods per line so that I can audit the margin without navigating to the stock page.

**Acceptance Criteria:**

| #     | Given                                                           | When                                  | Then                                                                                                              |
| ----- | --------------------------------------------------------------- | ------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| AC-01 | Authenticated user navigates to `GET /orders/:id` (show page)  | Page loads                            | Table header row shows: Product \| Description \| Unit \| QTY \| Unit Price \| Discount \| Cost \| Total; no "Lot" column |
| AC-02 | Order has 2 lines, each with `cogs` values set                  | Page loads                            | Each row's COST cell shows `฿XX.XX` formatted to 2 decimal places                                                |
| AC-03 | Order line has `cogs = 0` (non-stock product or phantom lot)    | Page loads                            | COST cell shows `฿0.00`                                                                                           |
| AC-04 | User without `products.cost` permission                         | Page loads                            | COST column is **hidden** (not rendered); all other columns remain visible                                        |
| AC-05 | Turbo Stream response for `order_lines#destroy`                  | Line is removed from the page         | Replaced row does not contain a LOT cell; removal animation plays correctly                                       |

**Edge Cases:**

- The permission check for COST visibility uses `policy(order_line.product).show_cost?` (or the equivalent existing Pundit helper).
- `_order_line.html.erb` partial is used in both the show page and Turbo Stream responses — change only needs to be made once.

| #          | Task                                                                                                                      | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-17-07-01 | Remove LOT `<th>` from `app/views/orders/show.html.erb`                                                                   | `[x]`  |
| T-17-07-02 | Add COST `<th>` (between Discount and Total) to `app/views/orders/show.html.erb`; wrap in `policy` check for `show_cost?` | `[x]`  |
| T-17-07-03 | Remove LOT `<td>` from `app/views/order_lines/_order_line.html.erb`                                                       | `[x]`  |
| T-17-07-04 | Add COST `<td>` to `app/views/order_lines/_order_line.html.erb`; wrap in `policy` check for `show_cost?`                 | `[x]`  |
| T-17-07-05 | Write RSpec request spec: `GET /orders/:id` includes COST column for admin; excludes COST for user without `show_cost?`   | `[x]`  |

---

## Summary

| Story       | Title                                                              | Stories | Tasks |
| ----------- | ------------------------------------------------------------------ | ------- | ----- |
| STORY-17-01 | Remove Negative-Stock & Lot-Required Constraints                   | 1       | 6     |
| STORY-17-02 | `OrderLineLotAllocation` Model & Migration                         | 1       | 6     |
| STORY-17-03 | `FifoLotAllocationService`                                         | 1       | 10    |
| STORY-17-04 | Wire FIFO into `OrderLine` Lifecycle Callbacks                     | 1       | 13    |
| STORY-17-05 | COGS Preview API Endpoint                                          | 1       | 10    |
| STORY-17-06 | Remove Lot Column & Add Real-Time COGS Display in Order Form       | 1       | 12    |
| STORY-17-07 | Update Order Show Page & Order Line Partial                        | 1       | 5     |
| **Total**   |                                                                    | **7**   | **62** |
