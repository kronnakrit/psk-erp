# EPIC-06 — Order Module (Core)

**Phase:** 6  
**Status:** 🔴 Not Started  
**Goal:** Full order lifecycle (Draft → Paid → Completed / Cancelled) with collision-safe order number generation, nested order lines, grand total auto-calculation (7-step formula), stock movements on line changes, and bulk status update.

---

## Legend

| Symbol | Meaning |
|---|---|
| 🔴 Not Started | Work has not begun |
| 🟡 In Progress | Actively being worked on |
| 🟢 Completed | Done and verified |
| `[ ]` | Task not started |
| `[~]` | Task in progress |
| `[x]` | Task completed |

---

## Stories

### STORY-06-01 — Order Model & Number Generation
**Status:** 🔴 Not Started  
**Description:** Generate the Order model with all fields. Implement the collision-safe `OrderNumberGenerator` service that produces `YYYYMMDD###` format numbers resetting per day.

| # | Task | Status |
|---|---|---|
| T-06-01-01 | Generate `Order` model with all columns per schema §5.2 of new_requirement.md | `[ ]` |
| T-06-01-02 | Add FK to `logistic_companies` with `on_delete: :nullify` | `[ ]` |
| T-06-01-03 | Add FK to `customers` with `on_delete: :cascade` | `[ ]` |
| T-06-01-04 | Add FKs to `users` for `created_by_id` and `updated_by_id` | `[ ]` |
| T-06-01-05 | Add all enums: `status` (`Dr`, `Pd`, `Cp`, `Cc`) and `logistic_status` (`WTS`, `ST`, `HP`, `TWH`) | `[ ]` |
| T-06-01-06 | Set up `ActiveSupport::CurrentAttributes` as `Current` with `user` attribute | `[ ]` |
| T-06-01-07 | Add `before_create :set_created_by` and `before_save :set_updated_by` callbacks using `Current.user` | `[ ]` |
| T-06-01-08 | Implement `OrderNumberGenerator` service object: counts orders for `running_date`, increments until unique, formats as `"#{date.strftime('%Y%m%d')}#{count.to_s.rjust(3, '0')}"` | `[ ]` |
| T-06-01-09 | Add `before_create :generate_order_number` on `Order` calling the service | `[ ]` |
| T-06-01-10 | Set default `running_date` to `Date.today` in the model | `[ ]` |
| T-06-01-11 | Write RSpec service spec for `OrderNumberGenerator`: daily reset, collision-safe (gaps), uniqueness | `[ ]` |
| T-06-01-12 | Write RSpec model specs: order number auto-set on create, FK constraints | `[ ]` |

---

### STORY-06-02 — Grand Total Calculation
**Status:** 🔴 Not Started  
**Description:** Implement the `GrandTotalCalculator` service using the exact 7-step formula from §9.2 of requirements.md. All values rounded to 2 decimal places.

| # | Task | Status |
|---|---|---|
| T-06-02-01 | Implement `GrandTotalCalculator` service: accepts an `Order` instance, returns `{ total_price, discount_amount, price_with_discount, price_excl_vat, vat_price, withholding_tax_amount, grand_total }` | `[ ]` |
| T-06-02-02 | Step 1: `total_price = order_lines.sum(:total_price)` | `[ ]` |
| T-06-02-03 | Step 2: discount_amount — percentage path and absolute path | `[ ]` |
| T-06-02-04 | Step 3: `price_with_discount = total_price - discount_amount` | `[ ]` |
| T-06-02-05 | Step 4: `price_excl_vat` — divide by 1.07 if `is_included_vat`, else use `price_with_discount` | `[ ]` |
| T-06-02-06 | Step 5: `vat_price` — zero if no VAT; reverse-extract if included; add-on if not included | `[ ]` |
| T-06-02-07 | Step 6: `withholding_tax_amount` — zero if not applicable; `price_excl_vat × (withholding_tax / 100)` | `[ ]` |
| T-06-02-08 | Step 7: `grand_total = price_excl_vat + vat_price - withholding_tax_amount` | `[ ]` |
| T-06-02-09 | Apply `round(2)` to every monetary value using `BigDecimal` half-up rounding | `[ ]` |
| T-06-02-10 | Add `recalculate_grand_total!` on `Order` which calls `GrandTotalCalculator` and saves the fields | `[ ]` |
| T-06-02-11 | Write RSpec service specs covering all 8 combinations of `has_vat`, `is_included_vat`, `is_discount_percentage`, and `is_withholding_tax` | `[ ]` |

---

### STORY-06-03 — Order CRUD & Status Management
**Status:** 🔴 Not Started  
**Description:** Full order CRUD with Turbo-powered status tab navigation. Dashboard summary widget. Advanced search with date range filters. Filtered list actions per status.

| # | Task | Status |
|---|---|---|
| T-06-03-01 | Implement `OrdersController` with `index`, `show`, `new`, `create`, `edit`, `update`, `destroy` | `[ ]` |
| T-06-03-02 | Add `draft`, `paid`, `completed`, `cancelled` collection actions (scoped queries + Pagy) | `[ ]` |
| T-06-03-03 | Implement `dashboard` action: today's order count, draft count, completed revenue this month, last 10 orders | `[ ]` |
| T-06-03-04 | Implement `advance_search` action with all parameters from §9.6 of requirements.md (date ranges, customer, status, logistic status, created_by, updated_by) | `[ ]` |
| T-06-03-05 | Implement `POST /filter` action: filter by `search_text` matching status code | `[ ]` |
| T-06-03-06 | Build Order list view with status tab bar (Turbo Frame: clicking a tab swaps only the table, not full page) | `[ ]` |
| T-06-03-07 | Build Order detail view: summary panel + lines table + grand total panel | `[ ]` |
| T-06-03-08 | Build Order new/edit form with Railsblocks; customer select, address fields, VAT toggles, discount fields | `[ ]` |
| T-06-03-09 | Display status and logistic status as Railsblocks `rb_badge` with per-status colours per §3.2 | `[ ]` |
| T-06-03-10 | Add `OrderPolicy` with CRUD and `report?` predicates | `[ ]` |
| T-06-03-11 | Add API routes mirroring all web actions under `/api/v1/orders/` | `[ ]` |
| T-06-03-12 | Write RSpec request specs for list, CRUD, filtered lists, dashboard, advance search | `[ ]` |

---

### STORY-06-04 — Order Lines Management
**Status:** 🔴 Not Started  
**Description:** Inline order line creation and editing. Each line change triggers a Turbo Stream update recalculating and displaying the updated grand total. Accepts nested order lines in the order create payload.

| # | Task | Status |
|---|---|---|
| T-06-04-01 | Generate `OrderLine` model with all columns per schema; `on_delete: :restrict` on `product_id` FK | `[ ]` |
| T-06-04-02 | Add `after_create_commit`, `after_update_commit`, `after_destroy_commit` callbacks on `OrderLine` → each calls `order.recalculate_grand_total!` | `[ ]` |
| T-06-04-03 | Implement `total_price` setter logic: `quantity × unit_price - discount_price` (calculated before save) | `[ ]` |
| T-06-04-04 | Accept nested `order_lines` in `Order` via `accepts_nested_attributes_for :order_lines, allow_destroy: true` | `[ ]` |
| T-06-04-05 | Implement `OrderLinesController` with full CRUD; search by `order_number` and product name | `[ ]` |
| T-06-04-06 | Build inline order line editor within Order detail/edit view using Stimulus controller (`order_line_controller.js`) | `[ ]` |
| T-06-04-07 | Turbo Stream: after saving/deleting a line, broadcast updated grand total summary panel to `"order_#{order.id}_total"` | `[ ]` |
| T-06-04-08 | Add dynamic "Add Line" button that appends a new line form row without page reload | `[ ]` |
| T-06-04-09 | Add `OrderLinePolicy` | `[ ]` |
| T-06-04-10 | Write RSpec model specs: total_price calculation, grand total recalculation trigger | `[ ]` |
| T-06-04-11 | Write RSpec request specs: create/update/delete with grand total recalculation verified | `[ ]` |

---

### STORY-06-05 — Order Line Stock Integration
**Status:** 🔴 Not Started  
**Description:** When a product has `enable_stock = true`, every change to an order line triggers automatic stock adjustments: withdrawal on create, re-deposit + re-withdrawal on quantity update, full deposit (reversal) on delete.

| # | Task | Status |
|---|---|---|
| T-06-05-01 | Add `after_create :handle_stock_on_create` on `OrderLine`: calls `ProductStock.find_or_create_for!(product:).withdraw!(quantity, ...)` when `product.enable_stock` | `[ ]` |
| T-06-05-02 | Add `after_update :handle_stock_on_update` on `OrderLine`: when quantity changed, deposit previous quantity then withdraw new quantity; two ledger entries produced | `[ ]` |
| T-06-05-03 | Add `before_destroy :handle_stock_on_destroy` on `OrderLine`: deposit full quantity back; nullify linked stock transaction `related_object` references | `[ ]` |
| T-06-05-04 | Skip all stock callbacks when `product.enable_stock == false` | `[ ]` |
| T-06-05-05 | Write RSpec model specs: stock withdrawal on create, re-deposit/re-withdraw on update (quantity change + no change), full reversal on destroy | `[ ]` |
| T-06-05-06 | Write RSpec integration spec: create order with stock-enabled product, verify `ProductStock#amount` decrements; delete line, verify amount restored | `[ ]` |

---

### STORY-06-06 — Bulk Status Update & Order Images
**Status:** 🔴 Not Started  
**Description:** Staff can select multiple orders and update their status in bulk. Orders can also have images attached.

| # | Task | Status |
|---|---|---|
| T-06-06-01 | Implement `PATCH /orders/bulk_update_status`: accepts `{ ids: [...], status }` or `{ is_selected_all: true, status }` (mutually exclusive) | `[ ]` |
| T-06-06-02 | Validate that `ids` and `is_selected_all` are not both provided; return `400` if so | `[ ]` |
| T-06-06-03 | Use `Order.where(id: ids).update_all(status: status)` for the IDs path | `[ ]` |
| T-06-06-04 | Use `Order.update_all(status: status)` (full scope) for the `is_selected_all` path | `[ ]` |
| T-06-06-05 | Add bulk selection UI to Order list: checkboxes per row + top action bar with status dropdown + Apply button | `[ ]` |
| T-06-06-06 | Generate `OrderImage` model: `order_id:bigint` FK, timestamps; Active Storage `has_one_attached :image` + `has_one_attached :thumb_image` | `[ ]` |
| T-06-06-07 | Include `ImageCompressible` concern in `OrderImage` | `[ ]` |
| T-06-06-08 | Implement `OrderImagesController` with full CRUD; filter by `order_id` | `[ ]` |
| T-06-06-09 | Add `OrderImagePolicy` | `[ ]` |
| T-06-06-10 | Write RSpec request specs: bulk update with IDs, bulk update all, mutual exclusivity validation | `[ ]` |
