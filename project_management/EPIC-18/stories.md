# EPIC-18 — Unit-Aware Order Line Price Autofill & Cost Field Removal

**Phase:** 18
**Status:** 🟢 Completed
**Goal:** The `Cost` field is removed from the product form and API; when a unit is changed on an order line the unit price recalculates in real time by ratio arithmetic (e.g. 1 dozen = 12 baht ÷ ratio 12 → 1 pc = 1 baht); the initial price fetch on product selection passes `unit_definition_id` to the `last_price` endpoint for customer-specific accuracy.

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

### Current behaviour (pre-EPIC-18)
- The **Pricing** card on `GET /products/new` and `GET /products/:id/edit` contains three fields: **Unit Group**, **Price** (single decimal on `products.price`), and **Cost** (decimal on `products.cost`, role-gated by `can_view_cost?`).
- There is a single `products.price` — no per-unit stored prices.
- The `last_price` endpoint (`GET /api/v1/catalogs/products/:id/last_price/:customer_id`) returns the most recent `order_lines.unit_price` for a product+customer pair with **no filter on `unit_definition_id`**. The fallback is `product.price`.
- `order_form_controller.js` fetches `last_price` only **on product selection**. Changing the unit dropdown does **not** update the price field.

### Target behaviour (EPIC-18)
1. **Cost field removed**: The `Cost` field is removed from the product new/edit form and from the `products` API response. `products.cost` column is **not dropped** (data preserved), but excluded from permitted params and not rendered.
2. **Ratio-based price autofill on unit change (client-side)**:
   - When the unit dropdown changes, `order_form_controller.js` recalculates the price **immediately in the browser** using the formula: `new_price = current_price × (new_unit_ratio ÷ old_unit_ratio)`.
   - Example: current price = 12 baht on Dozen (ratio 12) → switch to Pc (ratio 1) → 12 × 1 ÷ 12 = **1 baht**.
   - No additional server request is made on unit change.
   - Each unit definition `<option>` must carry a `data-ratio` attribute; the `<select>` element tracks `data-current-ratio` so the previous ratio is available when the change event fires.
3. **Unit-aware initial price fetch**:
   - On product selection (and on edit page load for pre-filled rows), `_fetchLastPrice` sends `?unit_definition_id=X` for the currently selected unit so the customer-specific last price is unit-accurate.
   - `default_price` in the response is always `product.price` (single global price — no per-unit stored value).

### No per-unit stored prices
- The `product_unit_prices` table is **not implemented** in this epic.
- `products.price` remains the single selling price for a product; all unit-to-unit conversion is performed in JS using ratio arithmetic.

### API changes (summary)
- `GET /api/v1/catalogs/products/:id/last_price/:customer_id` → accepts optional `?unit_definition_id=X`; `default_price` = `product.price`.
- `serialize_product` in `Api::V1::Catalogs::ProductsController` **excludes `cost`**; includes `unit_definitions: [{id, name, ratio}]` so the order form JS can read ratios.

---

## Stories

### STORY-18-01 — Product Form: Remove Cost Field

**Status:** 🟢 Completed
**Description:** The Pricing card in `app/views/products/_form.html.erb` is updated to remove the Cost input entirely. `products_controller.rb` no longer permits the `cost` parameter. Product list and show views no longer display Cost.

**User Perspective:**
As an admin, I want the product form to exclude the Cost field, so that cost data is managed solely via Purchase Orders and is not editable here.

**Acceptance Criteria:**

| #     | Given                                         | When                              | Then                                                                                        |
| ----- | --------------------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------- |
| AC-01 | Admin user on `GET /products/new`             | Page loads                        | Pricing card contains Unit Group and Price fields; **no "Cost" label or input rendered**    |
| AC-02 | Admin user on `GET /products/:id/edit`        | Page loads                        | Pricing card contains Unit Group and Price fields; **no "Cost" label or input rendered**    |
| AC-03 | Request includes `product[cost]=999`          | `PATCH /products/:id`             | Response `302` redirect; `product.cost` is **not** updated (param silently ignored)         |
| AC-04 | Admin user on `GET /products`                 | Page loads                        | No "Cost" column header or cell rendered in the products table                              |
| AC-05 | Admin user on `GET /products/:id`             | Page loads                        | No Cost value rendered in the product detail view                                           |

**Edge Cases:**
- `products.cost` column is retained in the database; only the UI and permitted params change. No migration required.
- The cost field was previously role-gated by `can_view_cost?`; the entire conditional block is removed for all roles.

| #          | Task                                                                                                                                                         | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-18-01-01 | Remove `:cost` from `product_params` permitted params in `app/controllers/products_controller.rb`                                                            | `[x]`  |
| T-18-01-02 | Remove the Cost input block from `app/views/products/_form.html.erb` (the `can_view_cost?` block containing `f.label :cost` and `f.number_field :cost`)     | `[x]`  |
| T-18-01-03 | Remove Cost column from `app/views/products/index.html.erb` (header `th` and body `td`) if present                                                          | `[x]`  |
| T-18-01-04 | Remove Cost field display from `app/views/products/show.html.erb` if present                                                                                 | `[x]`  |
| T-18-01-05 | Write RSpec request spec: `GET /products/:id/edit` does not render "Cost" (AC-02)                                                                            | `[x]`  |
| T-18-01-06 | Write RSpec request spec: `PATCH /products/:id` with `cost` param does not update `product.cost` (AC-03)                                                    | `[x]`  |

---

### STORY-18-02 — Product Catalog API: Exclude Cost, Include Unit Definition Ratios

**Status:** 🟢 Completed
**Description:** The `serialize_product` helper in `Api::V1::Catalogs::ProductsController` is updated to stop returning the `cost` field and to include a `unit_definitions` array (with `id`, `name`, `ratio`) so the order form JS can perform ratio-based price calculations client-side without extra requests.

**User Perspective:**
As a developer, I want the product catalog API to omit `cost` and expose unit definition ratios inline, so that sensitive cost data is never exposed and the order form has everything it needs to compute unit prices from ratios.

**Acceptance Criteria:**

| #     | Given                                                  | When                                              | Then                                                                                                                           |
| ----- | ------------------------------------------------------ | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | Any authenticated product API request                  | `GET /api/v1/catalogs/products?q[name_cont]=x`   | Response `200`; product objects do **not** contain a `"cost"` key                                                             |
| AC-02 | Product has a unit group with unit definitions Pc (ratio=1) and Box (ratio=12) | `GET /api/v1/catalogs/products/:id` | Response includes `"unit_definitions": [{"id": 1, "name": "Pc", "ratio": 1}, {"id": 2, "name": "Box", "ratio": 12}]` ordered by `ratio ASC` |
| AC-03 | Unauthenticated request                                | `GET /api/v1/catalogs/products`                   | Response `401` (unchanged)                                                                                                     |

**Edge Cases:**
- If `unit_definitions` is already partially included in the response, ensure `ratio` is present and no N+1 is introduced — update `includes` to `{ unit_group: :unit_definitions }`.
- Products using the system-default unit group must also return the correct `unit_definitions` array.

| #          | Task                                                                                                                                          | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-18-02-01 | Update `serialize_product` in `Api::V1::Catalogs::ProductsController`: remove `cost:` key from the returned hash                             | `[x]`  |
| T-18-02-02 | Ensure `serialize_product` includes `unit_definitions: [{id:, name:, ratio:}]` ordered by `ratio ASC`; update `includes` to eager-load `{ unit_group: :unit_definitions }` | `[x]`  |
| T-18-02-03 | Write RSpec request spec: `cost` key absent from product API response (AC-01)                                                                 | `[x]`  |
| T-18-02-04 | Write RSpec request spec: `unit_definitions` array with correct `ratio` values present in product API response (AC-02)                        | `[x]`  |

---

### STORY-18-03 — Unit-Aware `last_price` Endpoint

**Status:** 🟢 Completed
**Description:** The existing `GET /api/v1/catalogs/products/:id/last_price/:customer_id` endpoint is extended to accept an optional `unit_definition_id` query parameter. When provided, the last-selling-price lookup filters `order_lines` by that unit. `default_price` in the response is always `product.price` (no per-unit stored price).

**User Perspective:**
As a sales staff member, I want the order line to pre-fill with the last price this customer paid for the specific unit I selected, so that the initial price is customer-contextually accurate.

**Acceptance Criteria:**

| #     | Given                                                                                    | When                                                                                      | Then                                                                                                                                       |
| ----- | ---------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | Customer last paid ฿80 for unit "Box" (id=2); `product.price` = 7                       | `GET /api/v1/catalogs/products/:id/last_price/:customer_id?unit_definition_id=2`          | Response `200` JSON: `{ "last_price": 80.0, "default_price": 7.0 }`                                                                      |
| AC-02 | Customer has **not** ordered in unit "Box"; `product.price` = 7                          | `GET /api/v1/catalogs/products/:id/last_price/:customer_id?unit_definition_id=2`          | Response `200` JSON: `{ "last_price": null, "default_price": 7.0 }`                                                                      |
| AC-03 | No `unit_definition_id` param supplied                                                   | `GET /api/v1/catalogs/products/:id/last_price/:customer_id`                               | Response `200`; `last_price` = most recent order line price regardless of unit; `default_price` = `product.price` (legacy behaviour)       |
| AC-04 | Unauthenticated request                                                                  | `GET /api/v1/catalogs/products/:id/last_price/:customer_id?unit_definition_id=2`          | Response `401`                                                                                                                             |

**Edge Cases:**
- `Product.last_selling_price_for` receives optional `unit_definition_id: nil`; when non-nil, adds `.where(unit_definition_id:)` to the `OrderLine` query.
- `default_price` is always `product.price` — there is no per-unit price lookup (no `ProductUnitPrice` table).

| #          | Task                                                                                                                                                          | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-18-03-01 | Update `Product.last_selling_price_for(product_id:, customer_id:, unit_definition_id: nil)` to add `.where(unit_definition_id:)` when param is present        | `[x]`  |
| T-18-03-02 | Update `last_price` action in `Api::V1::Catalogs::ProductsController`: read `params[:unit_definition_id]`; pass to `last_selling_price_for`; `default_price` = `product.price` | `[x]`  |
| T-18-03-03 | Write RSpec request spec: AC-01 — unit-filtered last price returned                                                                                           | `[x]`  |
| T-18-03-04 | Write RSpec request spec: AC-02 — no unit match returns `last_price: null`                                                                                    | `[x]`  |
| T-18-03-05 | Write RSpec request spec: AC-03 — no `unit_definition_id` param uses legacy behaviour                                                                         | `[x]`  |
| T-18-03-06 | Write RSpec model spec: `Product.last_selling_price_for` with `unit_definition_id` filter                                                                     | `[x]`  |

---

### STORY-18-04 — Order Form: Ratio-Based Price Recalculation on Unit Change

**Status:** 🟢 Completed
**Description:** In the order form, selecting a unit definition recalculates the unit price field **instantly in the browser** using `new_price = current_price × (new_ratio ÷ old_ratio)`. No server request is made on unit change. On initial product selection, `_fetchLastPrice` is called with the currently selected `unit_definition_id` to get the unit-accurate customer last price.

**User Perspective:**
As a sales staff member, I want the unit price to update automatically when I change the unit (e.g. switching from Dozen at ฿12 to Pc gives ฿1), so that I do not need to calculate or retype the price.

**Acceptance Criteria:**

| #     | Given                                                                                                             | When                                                    | Then                                                                                                                              |
| ----- | ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Product selected; default unit is "Pc" (ratio=1); `last_price` endpoint returns 10.0 for Pc                     | Product selected from typeahead                         | Unit price input filled with `10.0`; no extra server request made for price                                                      |
| AC-02 | Current unit is "Pc" (ratio=1, price=1); user changes to "Dozen" (ratio=12)                                      | Unit dropdown changes to "Dozen"                        | Price field updated to `12.0` (= 1 × 12 ÷ 1); **no server request made**                                                        |
| AC-03 | Current unit is "Dozen" (ratio=12, price=12); user changes to "Pc" (ratio=1)                                     | Unit dropdown changes to "Pc"                           | Price field updated to `1.0` (= 12 × 1 ÷ 12); **no server request made**                                                        |
| AC-04 | Product selected; `last_price` endpoint returns `null`; `default_price` = 7.0                                    | Product selected from typeahead                         | Price field filled with `7.0` (default_price fallback)                                                                           |
| AC-05 | `last_price` fetch is in flight after product selection                                                           | User changes unit before fetch completes                | In-flight fetch is aborted via `AbortController`; ratio recalculation fires on whatever price was in the field at that moment    |
| AC-06 | User on `GET /orders/:id/edit` — existing order line with unit "Box" (ratio=12, saved price=80)                  | Page loads                                              | Price input shows saved `unit_price` `80.0`; `data-current-ratio` on the select is set to `12`                                   |

**Edge Cases:**
- Unit option `data-ratio` must be a positive integer. If absent or zero, skip recalculation and emit a `console.warn`.
- `data-current-ratio` on the `<select>` is updated **after** each recalculation so the next change always uses the correct previous ratio.
- On product selection `_onProductSelected` reads the currently selected unit's ratio from `data-current-ratio` (or from the selected option's `data-ratio`) and passes `unit_definition_id` to `_fetchLastPrice`.
- `onUnitChange` in `order_form_controller.js` does **not** call `_fetchLastPrice`; it performs only the client-side ratio calculation.
- The price tooltip (default price hint) displays `default_price` from the `last_price` response; it does **not** update on unit change (no server call is made).

| #          | Task                                                                                                                                                                     | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-18-04-01 | Add `data-ratio="<ratio>"` to each unit definition `<option>` in `app/views/orders/_order_line_fields.html.erb`                                                          | `[x]`  |
| T-18-04-02 | Add `data-current-ratio="<selected_option_ratio>"` attribute to the unit definition `<select>` in `_order_line_fields.html.erb`, initialised from the selected option    | `[x]`  |
| T-18-04-03 | Add `data-action="change->order-form#onUnitChange"` to the unit definition `<select>` in `_order_line_fields.html.erb`                                                   | `[x]`  |
| T-18-04-04 | Implement `onUnitChange(event)` in `app/javascript/controllers/order_form_controller.js`: read `oldRatio` from `select.dataset.currentRatio`; read `newRatio` from selected option's `data-ratio`; guard against zero/missing ratio; compute `newPrice = currentPrice × newRatio / oldRatio`; write to price input; update `data-current-ratio` | `[x]`  |
| T-18-04-05 | Refactor existing price-fetch logic into reusable `_fetchLastPrice(row, productId, unitDefinitionId)` that appends `?unit_definition_id=${unitDefinitionId}` when provided | `[x]`  |
| T-18-04-06 | Update `_onProductSelected` to read `unitDefinitionId` from the row's unit `<select>` and pass it to `_fetchLastPrice`; set `data-current-ratio` from selected option after product selection | `[x]`  |
| T-18-04-07 | Implement `AbortController` per-row in a `WeakMap`: abort previous in-flight `_fetchLastPrice` for the same row when a new product selection starts (AC-05)              | `[x]`  |
| T-18-04-08 | Update price-fill callback: if `last_price` non-null → use `last_price`; else use `default_price`; do NOT override `data-current-ratio` here (ratio is set separately)  | `[x]`  |
| T-18-04-09 | Write RSpec system/integration spec for AC-01: product selected → unit-accurate last price shown                                                                         | `[x]`  |
| T-18-04-10 | Write RSpec system/integration spec for AC-02–AC-03: unit change → price recalculated by ratio without server request                                                    | `[x]`  |

---

## Summary

| Story       | Title                                                          | Tasks |
| ----------- | -------------------------------------------------------------- | ----- |
| STORY-18-01 | Product Form: Remove Cost Field                                | 6     |
| STORY-18-02 | Product Catalog API: Exclude Cost, Include Unit Ratios         | 4     |
| STORY-18-03 | Unit-Aware `last_price` Endpoint                              | 6     |
| STORY-18-04 | Order Form: Ratio-Based Price Recalculation on Unit Change     | 10    |
| **Total**   |                                                                | **26** |

