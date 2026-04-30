# EPIC-16 — FIFO & Purchase Orders

**Phase:** 16
**Status:** 🟢 Completed

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

## Stories

### STORY-16-01 — Supplier Management

**Status:** 🟢 Completed
**Description:** Introduce a `Supplier` model and full CRUD UI mirroring the existing Logistic Company module. Suppliers are selectable on Purchase Orders.

**User Perspective:**
As a staff member, I want to create, view, edit, and deactivate suppliers, so that I can track which vendors I purchase products from.

**Acceptance Criteria:**

| #     | Given                                              | When                                                              | Then                                                                                                                    |
| ----- | -------------------------------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Authenticated user with `suppliers.create` perm   | `POST /suppliers` with valid params `{name, telephone, address, remark, is_active}` | Response is `302` redirect to `/suppliers`; flash `"Supplier created."`; row visible in `GET /suppliers`      |
| AC-02 | Authenticated user with `suppliers.update` perm   | `PATCH /suppliers/:id` with `{name: "Updated Name"}`             | Response is `302` redirect to `/suppliers`; flash `"Supplier updated."`; new name visible in list                       |
| AC-03 | Authenticated user with `suppliers.destroy` perm  | `DELETE /suppliers/:id`                                           | Response is `302` redirect to `/suppliers`; record no longer visible in `GET /suppliers`                                 |
| AC-04 | `POST /suppliers` with blank `name`               | Form submitted                                                    | Response is `422`; inline error `"Name can't be blank"` rendered on form                                                |
| AC-05 | User without `suppliers.index` perm               | `GET /suppliers`                                                  | Response is `302` redirect; flash `"Not authorised"`                                                                    |
| AC-06 | Authenticated user with `suppliers.index` perm    | `GET /suppliers`                                                  | Response is `200`; table lists all suppliers with columns: Name, Telephone, Status, Edit/Delete actions                 |
| AC-07 | Supplier with `is_active: false`                  | Displayed in index                                                | Row shows an "Inactive" badge (gray); "Active" badge (green) shown when `is_active: true`                               |

**Edge Cases:**

- Duplicate supplier name must be rejected with a `409`-equivalent inline error `"Name has already been taken"`.
- Inactive suppliers must still be selectable on Purchase Orders (soft-inactive, not deleted).
- Deleting a supplier that has associated Purchase Orders must be blocked with error `"Cannot delete supplier with existing purchase orders"`.

| #          | Task                                                                                                                | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------- | ------ |
| T-16-01-01 | Create migration: `create_suppliers` — columns: `name:string NOT NULL`, `telephone:string`, `address:text`, `remark:text`, `is_active:boolean NOT NULL DEFAULT true`; unique index on `name` | `[x]`  |
| T-16-01-02 | Create `Supplier` model: `validates :name, presence: true, uniqueness: true`; `has_many :purchase_orders`; `before_destroy` guard if purchase_orders exist; `ransackable_attributes %w[name telephone address remark is_active]` | `[x]`  |
| T-16-01-03 | Create `SuppliersController` (all 7 CRUD actions); use `before_action :authorize_supplier!` via Pundit            | `[x]`  |
| T-16-01-04 | Create `SupplierPolicy` (mirrors `LogisticCompanyPolicy`): index/show → `suppliers.index`; create → `suppliers.create`; update → `suppliers.update`; destroy → `suppliers.destroy` | `[x]`  |
| T-16-01-05 | Create `app/views/suppliers/index.html.erb`: page header "Suppliers" + "New Supplier" button; table with Name, Telephone, Status badge, Edit/Delete actions; empty state row | `[x]`  |
| T-16-01-06 | Create `app/views/suppliers/_form.html.erb`: fields `name`, `telephone`, `address` (textarea), `remark` (textarea), `is_active` (checkbox); chevron back button to `suppliers_path`; submit right-aligned | `[x]`  |
| T-16-01-07 | Create `app/views/suppliers/new.html.erb` and `app/views/suppliers/edit.html.erb` rendering `_form` partial        | `[x]`  |
| T-16-01-08 | Add `resources :suppliers` to `config/routes.rb`                                                                    | `[x]`  |
| T-16-01-09 | Add "Suppliers" nav link in `app/views/layouts/_sidebar.html.erb` under the "Catalog" collapsible group (below "Brands") | `[x]`  |
| T-16-01-10 | Write RSpec model spec: `spec/models/supplier_spec.rb` — validations, uniqueness, destroy guard                     | `[x]`  |
| T-16-01-11 | Write RSpec request spec: `spec/requests/suppliers_spec.rb` — index (200), create (302 / 422), update (302 / 422), destroy (302 / blocked with error) | `[x]`  |
| T-16-01-12 | Write RSpec policy spec: `spec/policies/supplier_policy_spec.rb` — per-permission matrix                            | `[x]`  |

---

### STORY-16-02 — Purchase Order Header CRUD

**Status:** 🟢 Completed
**Description:** Users can create, list, view, edit, and cancel Purchase Orders. Each PO has an auto-generated PO number, a supplier, a date, a status (Draft / Confirmed / Cancelled), and a remark.

**User Perspective:**
As a purchasing staff member, I want to create and manage Purchase Orders, so that I have a formal record of every product inbound.

**Acceptance Criteria:**

| #     | Given                                                               | When                                                                       | Then                                                                                                                                        |
| ----- | ------------------------------------------------------------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Authenticated user with `purchase_orders.create` perm              | `POST /purchase_orders` with `{supplier_id, po_date, remark}`              | Response is `302` to `/purchase_orders/:id`; flash `"Purchase order created."`; `po_number` auto-generated as `PO-YYYYMMDD-XXXX`; `status` is `"Dr"` |
| AC-02 | Authenticated user with `purchase_orders.update` perm              | `PATCH /purchase_orders/:id` with `{remark: "Updated"}`                    | Response is `302` to `/purchase_orders/:id`; flash `"Purchase order updated."`                                                              |
| AC-03 | PO with status `"Cf"` (Confirmed)                                  | `PATCH /purchase_orders/:id` to change any field                           | Response is `422`; error `"Confirmed purchase orders cannot be edited"`                                                                     |
| AC-04 | `POST /purchase_orders` with blank `supplier_id`                   | Form submitted                                                             | Response is `422`; inline error `"Supplier must exist"` on form                                                                             |
| AC-05 | Authenticated user with `purchase_orders.index` perm               | `GET /purchase_orders`                                                     | Response is `200`; table lists POs with columns: PO Number, Supplier, Date, Status badge, Lines count, actions                              |
| AC-06 | User without `purchase_orders.index` perm                          | `GET /purchase_orders`                                                     | Response is `302`; flash `"Not authorised"`                                                                                                 |
| AC-07 | PO with status `"Dr"` (Draft)                                      | `GET /purchase_orders/:id`                                                 | Response is `200`; page shows "Confirm" button and "Edit" button; `status` badge displays "Draft" in gray                                  |
| AC-08 | PO with status `"Cf"` (Confirmed)                                  | `GET /purchase_orders/:id`                                                 | Response is `200`; "Confirm" and "Edit" buttons are absent; `status` badge displays "Confirmed" in green                                   |

**Edge Cases:**

- `po_number` uniqueness is enforced at DB level; if collision occurs on create, retry with next sequential suffix.
- Cancelled POs (`"Cc"`) cannot be re-opened or edited.
- Deleting a Confirmed PO must be blocked: error `"Cannot delete a confirmed purchase order"`.

| #          | Task                                                                                                                                           | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-16-02-01 | Create migration: `create_purchase_orders` — columns: `supplier_id:bigint NOT NULL`, `po_number:string NOT NULL UNIQUE`, `po_date:date NOT NULL`, `status:string(2) NOT NULL DEFAULT 'Dr'`, `remark:text`; FK on `supplier_id`; index on `status`, `po_date` | `[x]`  |
| T-16-02-02 | Create `PurchaseOrder` model: `STATUSES = %w[Dr Cf Cc]`; `belongs_to :supplier`; `has_many :purchase_order_lines, dependent: :destroy`; `has_many :product_lots`; `validates :po_number, presence: true, uniqueness: true`; `validates :po_date, presence: true`; `validates :status, inclusion: {in: STATUSES}`; `before_validation :generate_po_number, on: :create`; `before_destroy` guard if status is `"Cf"` | `[x]`  |
| T-16-02-03 | Implement `generate_po_number` private method on `PurchaseOrder`: format `PO-YYYYMMDD-XXXX` where XXXX is zero-padded daily sequence (mirrors `Order#generate_order_number`) | `[x]`  |
| T-16-02-04 | Create `PurchaseOrdersController` (index, show, new, create, edit, update, destroy); add `confirm` member action (`POST`); Pundit authorize; prevent edit/delete on Confirmed/Cancelled | `[x]`  |
| T-16-02-05 | Create `PurchaseOrderPolicy` (mirrors `OrderPolicy`): index/show → `purchase_orders.index`; create → `purchase_orders.create`; update/confirm → `purchase_orders.update`; destroy → `purchase_orders.destroy` | `[x]`  |
| T-16-02-06 | Create `app/views/purchase_orders/index.html.erb`: page header "Purchase Orders" + "New Purchase Order" button; table with PO Number, Supplier, Date, Status badge, Line count, actions; empty state | `[x]`  |
| T-16-02-07 | Create `app/views/purchase_orders/_form.html.erb`: supplier dropdown (collection_select from Supplier.all), po_date (date field), remark (textarea); validation error block; submit right-aligned with Cancel link | `[x]`  |
| T-16-02-08 | Create `app/views/purchase_orders/new.html.erb` and `edit.html.erb`; chevron back to `purchase_orders_path`                                    | `[x]`  |
| T-16-02-09 | Create `app/views/purchase_orders/show.html.erb`: PO header card (PO number, supplier, date, status badge, remark); "Confirm" button (turbo_confirm dialog: "Confirm this PO? Stock lots will be created.") visible only when status is `"Dr"`; "Edit" button visible only when status is `"Dr"` | `[x]`  |
| T-16-02-10 | Add `resources :purchase_orders` to `config/routes.rb` with `member { post :confirm }`                                                        | `[x]`  |
| T-16-02-11 | Add "Purchase Orders" nav link in `_sidebar.html.erb` as a top-level item (below "Orders")                                                    | `[x]`  |
| T-16-02-12 | Write RSpec model spec: `spec/models/purchase_order_spec.rb` — validations, po_number generation, destroy guard                                | `[x]`  |
| T-16-02-13 | Write RSpec request spec: `spec/requests/purchase_orders_spec.rb` — index (200), create (302 / 422), update (302 / blocked on Confirmed), destroy (302 / blocked) | `[x]`  |

---

### STORY-16-03 — Purchase Order Lines

**Status:** 🟢 Completed
**Description:** Users can add, update, and remove line items on a Draft Purchase Order. Each line has a product, quantity, unit, and unit cost. The unit cost auto-fills from the product's last confirmed PO price, falling back to `product.cost`.

**User Perspective:**
As a purchasing staff member, I want to add product lines to a PO with auto-filled costs, so that I can quickly build an accurate purchase order.

**Acceptance Criteria:**

| #     | Given                                                                    | When                                                                                             | Then                                                                                                                              |
| ----- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Draft PO exists; user has `purchase_orders.update` perm                  | `POST /purchase_orders/:id/purchase_order_lines` with `{product_id, unit_definition_id, quantity, unit_cost}` | Response is `200` Turbo Stream; new line row appended to PO lines table; PO total recalculated and updated in DOM               |
| AC-02 | `POST /purchase_orders/:id/purchase_order_lines` with `quantity: 0`      | Submitted                                                                                        | Response is `422`; inline error `"Quantity must be greater than 0"`                                                               |
| AC-03 | `POST /purchase_orders/:id/purchase_order_lines` with blank `product_id` | Submitted                                                                                        | Response is `422`; inline error `"Product must exist"`                                                                            |
| AC-04 | Product has a prior confirmed PO line                                    | User selects the product in the PO line form                                                     | `unit_cost` field auto-fills with the `unit_cost` from the most recent confirmed PO line for that product (`GET /api/v1/products/:id/last_purchase_cost` returns `{unit_cost: decimal}` with `200`) |
| AC-05 | Product has no prior PO                                                  | User selects the product in the PO line form                                                     | `unit_cost` field auto-fills with `product.cost`; if `product.cost` is nil, field is left blank                                   |
| AC-06 | PO is Confirmed (`"Cf"`)                                                 | `POST /purchase_orders/:id/purchase_order_lines`                                                 | Response is `403`; no line created                                                                                                |
| AC-07 | PO line exists                                                           | `DELETE /purchase_orders/:id/purchase_order_lines/:line_id`                                      | Response is `200` Turbo Stream; row removed from DOM; PO total recalculated                                                       |

**Edge Cases:**

- `unit_definition_id` must belong to the product's effective unit group; otherwise return `422` with error `"Invalid unit for this product"`.
- Editing a line on a Confirmed PO must return `403`.

| #          | Task                                                                                                                                                      | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-16-03-01 | Create migration: `create_purchase_order_lines` — columns: `purchase_order_id:bigint NOT NULL`, `product_id:bigint NOT NULL`, `unit_definition_id:bigint NOT NULL`, `quantity:decimal(8,2) NOT NULL`, `unit_cost:decimal(20,2) NOT NULL DEFAULT 0`; FK indexes on all foreign keys | `[x]`  |
| T-16-03-02 | Create `PurchaseOrderLine` model: `belongs_to :purchase_order`; `belongs_to :product`; `belongs_to :unit_definition`; `validates :quantity, numericality: {greater_than: 0}`; `validates :unit_cost, numericality: {greater_than_or_equal_to: 0}`; `validate :unit_definition_belongs_to_product_group`; `after_commit :recalc_po_total` | `[x]`  |
| T-16-03-03 | Add `has_many :purchase_order_lines, dependent: :destroy` and `accepts_nested_attributes_for :purchase_order_lines` to `PurchaseOrder` model               | `[x]`  |
| T-16-03-04 | Create `PurchaseOrderLinesController` (create, update, destroy nested under purchase_orders); Pundit authorize via `PurchaseOrderPolicy`; respond with Turbo Stream | `[x]`  |
| T-16-03-05 | Add nested route: inside `resources :purchase_orders` add `resources :purchase_order_lines, only: %i[create update destroy]`                              | `[x]`  |
| T-16-03-06 | Implement `Product.last_purchase_cost(product_id:)` class method: queries `PurchaseOrderLine.joins(:purchase_order).where(product_id:, purchase_orders: {status: "Cf"}).order("purchase_orders.po_date DESC").first&.unit_cost || Product.find(product_id).cost` | `[x]`  |
| T-16-03-07 | Add API route `GET /api/v1/products/:id/last_purchase_cost`; add `last_purchase_cost` action to existing API products controller; returns `{unit_cost: decimal \| null}` with `200` | `[x]`  |
| T-16-03-08 | Create `app/views/purchase_orders/_purchase_order_line_fields.html.erb`: product typeahead (reuses `order-line-search` Stimulus pattern), unit definition select, quantity field, unit_cost field (auto-filled via `last_purchase_cost` API call when product selected), Remove button | `[x]`  |
| T-16-03-09 | Update `app/views/purchase_orders/show.html.erb` to include PO lines table and "Add Line" form rendered as Turbo Frame; columns: Product, Unit, Qty, Unit Cost, Total, Remove action | `[x]`  |
| T-16-03-10 | Write RSpec model spec: `spec/models/purchase_order_line_spec.rb` — validations, unit group check, total recalc callback                                   | `[x]`  |
| T-16-03-11 | Write RSpec request spec: `spec/requests/purchase_order_lines_spec.rb` — create (200 Turbo / 422 / 403 on Confirmed), destroy (200 Turbo / 403)           | `[x]`  |
| T-16-03-12 | Write RSpec request spec for `GET /api/v1/products/:id/last_purchase_cost` — with prior PO (returns cost), without prior PO (returns `product.cost`), no product (404) | `[x]`  |

---

### STORY-16-04 — PO Confirmation Creates Product Lots

**Status:** 🟢 Completed
**Description:** When a user confirms a Draft Purchase Order, each PO line generates one `ProductLot` record that tracks the inbound batch's quantity and unit cost. The existing `ProductStock` is also incremented for compatibility with the stock module.

**User Perspective:**
As a warehouse manager, I want confirming a PO to automatically create product lots, so that each inbound batch is traceable with its own cost.

**Acceptance Criteria:**

| #     | Given                                                                    | When                                                                   | Then                                                                                                                                                                          |
| ----- | ------------------------------------------------------------------------ | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Draft PO with 2 lines exists; user has `purchase_orders.update` perm     | `POST /purchase_orders/:id/confirm`                                    | Response is `302` to `/purchase_orders/:id`; flash `"Purchase order confirmed. 2 product lot(s) created."`; PO `status` changes to `"Cf"`; 2 `ProductLot` records created   |
| AC-02 | PO is confirmed (as above)                                               | After `POST /purchase_orders/:id/confirm`                              | Each `ProductLot` has: `product_id` from line, `purchase_order_id`, auto-generated `lot_number` (`LOT-{po_number}-{n}`), `received_date` = today's date, `original_quantity` = line `quantity` × unit ratio (in base unit), `remaining_quantity` = `original_quantity`, `unit_cost` = line `unit_cost`, `status` = `"active"` |
| AC-03 | PO is confirmed (as above)                                               | After `POST /purchase_orders/:id/confirm`                              | For each line: `ProductStock.find_or_create_for!(product:).deposit!(amount: original_quantity, reason: "PO #{po_number}", related_object: product_lot)` is called; `product_stock_transactions` record created |
| AC-04 | PO already has status `"Cf"`                                             | `POST /purchase_orders/:id/confirm`                                    | Response is `422`; flash `"Purchase order is already confirmed"`; no lots created                                                                                              |
| AC-05 | PO has status `"Cc"` (Cancelled)                                        | `POST /purchase_orders/:id/confirm`                                    | Response is `422`; flash `"Cannot confirm a cancelled purchase order"`                                                                                                         |
| AC-06 | Draft PO has zero lines                                                  | `POST /purchase_orders/:id/confirm`                                    | Response is `422`; flash `"Cannot confirm a purchase order with no lines"`                                                                                                     |

**Edge Cases:**

- Confirmation is wrapped in a database transaction; if any lot creation fails, the entire confirmation is rolled back and an error flash is shown.
- `lot_number` must be unique; format `LOT-{po_number}-{n}` where n is 1-based line index.

| #          | Task                                                                                                                                                              | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-16-04-01 | Create migration: `create_product_lots` | `[x]`  |
| T-16-04-02 | Create `ProductLot` model | `[x]`  |
| T-16-04-03 | Create `ConfirmPurchaseOrderService` | `[x]`  |
| T-16-04-04 | Add `PurchaseOrdersController#confirm` action calls service | `[x]`  |
| T-16-04-05 | Add `has_many :product_lots` to both `PurchaseOrder` and `Product` models | `[x]`  |
| T-16-04-06 | Write RSpec service spec: `spec/services/confirm_purchase_order_service_spec.rb` | `[x]`  |
| T-16-04-07 | Write RSpec model spec: `spec/models/product_lot_spec.rb` | `[x]`  |
| T-16-04-08 | Write RSpec request spec for `POST /purchase_orders/:id/confirm` | `[x]`  |

---

### STORY-16-05 — Lot Selection on Sales Order Lines

**Status:** 🟢 Completed
**Description:** When building a sales Order, each Order Line must reference a `ProductLot`. The lot picker defaults to the oldest active lot for the selected product (FIFO). The lot picker displays lot number, received date, available quantity, and unit cost.

**User Perspective:**
As a sales staff member, I want to pick which product lot to fulfil from when adding an order line, so that stock is consumed in first-in-first-out order.

**Acceptance Criteria:**

| #     | Given                                                                                              | When                                                                                                    | Then                                                                                                                                    |
| ----- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Product has 2 active lots (lot A received 2025-01-01, lot B received 2025-06-01)                   | `GET /api/v1/products/:id/lots`                                                                         | Response is `200` JSON `[{id, lot_number, received_date, remaining_quantity, unit_cost}, …]` ordered by `received_date ASC`; only lots with `status = "active"` and `remaining_quantity > 0` returned |
| AC-02 | Product has active lots (as above)                                                                 | User selects product in the Order Line form                                                             | Lot picker `<select>` populates via API call; first option (oldest lot) is pre-selected; each option label shows `"{lot_number} — {received_date} — qty: {remaining_quantity} — ฿{unit_cost}"` |
| AC-03 | Product has no active lots                                                                         | User selects product in the Order Line form                                                             | Lot picker shows single disabled option `"— No lots available —"`; form submission is blocked                                          |
| AC-04 | User selects a lot and submits the order line form                                                 | `POST /orders/:id/order_lines` with `{product_id, unit_definition_id, quantity, unit_price, product_lot_id}` | Response is `200` Turbo Stream; `order_lines.product_lot_id` persisted; line row rendered includes lot number in a "Lot" column       |
| AC-05 | `POST /orders/:id/order_lines` without `product_lot_id` for a product that has active lots        | Submitted                                                                                               | Response is `422`; inline error `"Lot must be selected"`                                                                                |
| AC-06 | Product has `enable_stock: false`                                                                  | User adds order line for this product                                                                   | Lot picker is not shown; `product_lot_id` is not required; existing behaviour unchanged                                                 |

**Edge Cases:**

- If a product's lots change between page load and form submit (race condition), the server-side validation in STORY-16-07 will catch the overage.
- `GET /api/v1/products/:id/lots` returns `[]` (empty array) for products with `enable_stock: false` or no active lots.

| #          | Task                                                                                                                                              | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-16-05-01 | Create migration: `add_product_lot_id_to_order_lines` | `[x]`  |
| T-16-05-02 | Add `belongs_to :product_lot, optional: true` to `OrderLine` model | `[x]`  |
| T-16-05-03 | Add API endpoint `GET /api/v1/products/:id/lots` | `[x]`  |
| T-16-05-04 | Update `app/views/orders/_order_line_fields.html.erb`: add lot picker `<select>` | `[x]`  |
| T-16-05-05 | Update `order-line-search` Stimulus controller: fetch lots after product selected | `[x]`  |
| T-16-05-06 | Update `OrderLinesController` strong params to permit `product_lot_id` | `[x]`  |
| T-16-05-07 | Add server-side validation to `OrderLine`: `validate :lot_required_if_stock_enabled` | `[x]`  |
| T-16-05-08 | Update `app/views/order_lines/_order_line.html.erb` to add "Lot" column | `[x]`  |
| T-16-05-09 | Write RSpec request spec for `GET /api/v1/products/:id/lots` | `[x]`  |
| T-16-05-10 | Write RSpec request spec for `POST /orders/:id/order_lines` with lot scenarios | `[x]`  |

---

### STORY-16-06 — Lot Visibility

**Status:** 🟢 Completed
**Description:** Users can view the full list of product lots for a given product, showing each lot's status, quantities, cost, and source PO number.

**User Perspective:**
As a warehouse manager, I want to see all lots for a product, so that I can understand the current FIFO stock breakdown and cost per batch.

**Acceptance Criteria:**

| #     | Given                                                              | When                                       | Then                                                                                                                                     |
| ----- | ------------------------------------------------------------------ | ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Authenticated user with `products.show` perm; product has 3 lots  | `GET /products/:id/lots`                   | Response is `200`; table rows for all 3 lots; columns: Lot Number, Source PO, Received Date, Original Qty, Remaining Qty, Unit Cost, Status badge |
| AC-02 | Lot with `remaining_quantity == 0`                                 | Displayed in lot list                      | Status badge shows "Depleted" in gray; lot with `remaining_quantity > 0` shows "Active" in green                                         |
| AC-03 | Product has no lots                                                | `GET /products/:id/lots`                   | Response is `200`; empty state message `"No lots have been created for this product yet."` visible                                       |
| AC-04 | User without `products.show` perm                                  | `GET /products/:id/lots`                   | Response is `302`; flash `"Not authorised"`                                                                                              |

**Edge Cases:**

- Lot list is ordered by `received_date ASC` (oldest first, matching FIFO consumption order).
- The "Source PO" column shows the `po_number` of the originating Purchase Order as a link to `purchase_orders/:id`.

| #          | Task                                                                                                                             | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-16-06-01 | Add `lots` action to `ProductsController` | `[x]`  |
| T-16-06-02 | Add `get :lots` member route inside `resources :products` | `[x]`  |
| T-16-06-03 | Create `app/views/products/lots.html.erb` | `[x]`  |
| T-16-06-04 | Add "View Lots" button/link on `app/views/products/show.html.erb` | `[x]`  |
| T-16-06-05 | Write RSpec request spec: `spec/requests/products_lots_spec.rb` | `[x]`  |

---

### STORY-16-07 — Lot Quantity Enforcement

**Status:** 🟢 Completed
**Description:** An Order Line quantity cannot exceed the selected `ProductLot`'s remaining quantity. The lot's `remaining_quantity` is decremented when an order line is created/updated and restored when an order line is deleted. A lot is automatically marked `"depleted"` when `remaining_quantity` reaches zero.

**User Perspective:**
As a sales staff member, I want the system to prevent me from selling more stock than a single lot contains, so that FIFO integrity is maintained and stock cannot go negative per lot.

**Acceptance Criteria:**

| #     | Given                                                                                                     | When                                                                         | Then                                                                                                                                     |
| ----- | --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Lot A has `remaining_quantity: 10`                                                                        | `POST /orders/:id/order_lines` with `{quantity: 11, product_lot_id: lot_a.id}` | Response is `422`; inline error `"Quantity (11) exceeds lot remaining quantity (10)"`; `lot_a.remaining_quantity` unchanged              |
| AC-02 | Lot A has `remaining_quantity: 10`                                                                        | `POST /orders/:id/order_lines` with `{quantity: 10, product_lot_id: lot_a.id}` | Response is `200` Turbo Stream; `lot_a.remaining_quantity` becomes `0`; `lot_a.status` becomes `"depleted"`; lot no longer appears in active lot picker |
| AC-03 | Lot A has `remaining_quantity: 5`; Order Line for lot A with `quantity: 3` exists                        | `PATCH /orders/:id/order_lines/:line_id` with `{quantity: 6}`                | Response is `422`; inline error `"Quantity (6) exceeds lot remaining quantity (8)"` (5 remaining + 3 already allocated by this line); `lot_a.remaining_quantity` unchanged |
| AC-04 | Order Line with `quantity: 5` for lot A (`remaining_quantity: 0`) is destroyed                           | `DELETE /orders/:id/order_lines/:line_id`                                    | Response is `200` Turbo Stream; `lot_a.remaining_quantity` becomes `5`; `lot_a.status` becomes `"active"`                               |
| AC-05 | Order Line for stock-disabled product (no lot)                                                           | Created/updated/deleted                                                      | No lot quantity changes; existing `ProductStock` behaviour unchanged                                                                     |

**Edge Cases:**

- Validation for update uses `quantity ≤ lot.remaining_quantity + quantity_was` (the previously committed quantity for this line, which has already been deducted from the lot, must be added back for comparison).
- All lot quantity changes are wrapped in a DB transaction with the order line save.
- If an Order's status is changed to "Cancelled" (triggering `return_stock_on_cancellation`), each order line's lot must have its `remaining_quantity` restored.

| #          | Task                                                                                                                                                                  | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-16-07-01 | Add `validate :lot_quantity_not_exceeded` to `OrderLine` | `[x]`  |
| T-16-07-02 | Update `OrderLine#handle_stock_on_create`: decrement lot `remaining_quantity` | `[x]`  |
| T-16-07-03 | Update `OrderLine#handle_stock_on_update`: adjust lot `remaining_quantity` | `[x]`  |
| T-16-07-04 | Update `OrderLine#handle_stock_on_destroy`: restore lot `remaining_quantity` | `[x]`  |
| T-16-07-05 | Update `Order#return_stock_on_cancellation` to restore lot `remaining_quantity` | `[x]`  |
| T-16-07-06 | Ensure `ProductLot#after_save :update_status_if_depleted` re-activates when `remaining_quantity > 0` | `[x]`  |
| T-16-07-07 | Write RSpec model spec: `spec/models/order_line_lot_enforcement_spec.rb` | `[x]`  |
| T-16-07-08 | Write RSpec request spec additions for lot enforcement scenarios | `[x]`  |
