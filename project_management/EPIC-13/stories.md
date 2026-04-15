# EPIC-13 — Product Stock Enhancements

**Phase:** 13
**Status:** 🟢 Completed
**Goal:** Improve the Product Stock module with adjuster tracking on every manual transaction, search + last-updated on the stock list page, a reset-to-zero action with mandatory reason + confirmation, and a direct shortcut to a product's stock page from the product list.

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

### STORY-13-01 — Track Stock Adjuster on Manual Transactions

**Status:** 🟢 Completed
**Description:** Every manual stock adjustment (deposit, withdraw, reset) must record the logged-in user as the adjuster. The adjuster's full name is displayed in a new "Adjuster" column in the Recent Transactions table on the stock detail page, and in the full transactions list page.

**User Perspective:**
As a Stock Manager, I want every manual stock adjustment to show who made it, so that I can hold the correct person accountable for stock changes.

**Acceptance Criteria:**

| #     | Given                                                                                 | When                                              | Then                                                                                                                                       |
| ----- | ------------------------------------------------------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | A logged-in user on the stock detail page (`/stocks/:id`)                             | They submit the **Deposit** form                  | The created `ProductStockTransaction` has `adjuster_id = current_user.id` persisted in the database                                        |
| AC-02 | A logged-in user on the stock detail page                                             | They submit the **Withdraw** form                 | The created `ProductStockTransaction` has `adjuster_id = current_user.id` persisted in the database                                        |
| AC-03 | A stock detail page rendering Recent Transactions                                     | The page loads                                    | Each transaction row shows an "Adjuster" column with the adjuster's full name (`profile.first_name + " " + profile.last_name`), or "—" when `adjuster_id` is `NULL` (system transactions) |
| AC-04 | A `ProductStockTransaction` created by an order fulfilment (no `adjuster_id`)         | Viewing it in the stock detail transactions table | The Adjuster cell renders "—"                                                                                                              |
| AC-05 | A logged-in user with `view_product_stocks` permission                                | They navigate to `GET /stocks/:id/transactions`   | The full paginated transactions list also includes the "Adjuster" column with the same display logic                                       |

**Edge Cases:**

- Adjuster's profile may have blank `first_name` or `last_name` — fall back to `adjuster.email` in that case.
- `adjuster_id` column must be `null: true` so pre-existing and system-generated transactions remain valid.
- `withdraw_from_holding!` (called by order fulfillment) does **not** receive an adjuster and must continue to work without one.

| #          | Task                                                                                                                                                                                         | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-13-01-01 | Generate migration: `add_adjuster_to_product_stock_transactions` — add column `adjuster_id:bigint null:true` with FK `references :users` to `product_stock_transactions`                    | `[x]`  |
| T-13-01-02 | Add `belongs_to :adjuster, class_name: "User", optional: true` association to `ProductStockTransaction` model                                                                               | `[x]`  |
| T-13-01-03 | Add `adjuster_id` to `ProductStockTransaction.ransackable_attributes`                                                                                                                        | `[x]`  |
| T-13-01-04 | Update `ProductStock#create_transaction!` private method to accept an `adjuster:` keyword argument and pass it to `product_stock_transactions.create!`                                       | `[x]`  |
| T-13-01-05 | Update `ProductStock#deposit!` signature to accept `adjuster: nil` and forward it to `create_transaction!`                                                                                  | `[x]`  |
| T-13-01-06 | Update `ProductStock#withdraw!` signature to accept `adjuster: nil` and forward it to `create_transaction!`                                                                                | `[x]`  |
| T-13-01-07 | Update `StocksController#deposit` to pass `adjuster: current_user` when calling `@stock.deposit!`                                                                                           | `[x]`  |
| T-13-01-08 | Update `StocksController#withdraw` to pass `adjuster: current_user` when calling `@stock.withdraw!`                                                                                        | `[x]`  |
| T-13-01-09 | Add `adjuster_display_name` helper method to `ApplicationHelper` (or `StocksHelper`): returns `adjuster.profile.first_name + " " + adjuster.profile.last_name` if present, else `adjuster.email`, else `"—"` | `[x]`  |
| T-13-01-10 | Update `app/views/stocks/show.html.erb` Recent Transactions table: add `<th>Adjuster</th>` header and `<td><%= adjuster_display_name(txn.adjuster) %></td>` cell                            | `[x]`  |
| T-13-01-11 | Update `app/views/stocks/transactions.html.erb` full transactions table: add "Adjuster" column with the same display logic                                                                  | `[x]`  |
| T-13-01-12 | Write RSpec model spec: `deposit!` with `adjuster:` creates transaction with correct `adjuster_id`; `withdraw!` with `adjuster:` creates transaction with correct `adjuster_id`; `withdraw_from_holding!` without adjuster creates transaction with `adjuster_id: nil` | `[x]`  |
| T-13-01-13 | Write RSpec request spec: `POST /stocks/:id/deposit` — response redirects to stock detail and the latest transaction has `adjuster_id = current_user.id`                                   | `[x]`  |

---

### STORY-13-02 — Stock List: Search by Product & Branch + Last Updated Column

**Status:** � Completed
**Description:** The stock list page (`/stocks`) gains a search/filter bar that lets users filter by product name (or SKU) and by branch. A new "Last Updated" column shows when each stock record was last modified.

**User Perspective:**
As a Stock Manager, I want to search for a product's stock record by name or branch, and see when a stock record was last changed, so that I can quickly find and audit specific stock entries.

**Acceptance Criteria:**

| #     | Given                                                                                    | When                                                                                | Then                                                                                                                                                         |
| ----- | ---------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | The stock list page with multiple records                                                | The user types a product name fragment into the search field and submits             | Only rows whose product `name` contains the fragment (case-insensitive, Ransack `product_name_cont`) are displayed; pagination is reset to page 1            |
| AC-02 | The stock list page                                                                      | The user selects a branch from the branch dropdown and submits                       | Only rows matching that `branch_id` (`q[branch_id_eq]`) are displayed                                                                                       |
| AC-03 | The stock list page                                                                      | The user uses both product name and branch filters together and submits              | Only rows satisfying both conditions are displayed (Ransack AND combination)                                                                                 |
| AC-04 | The stock list page after a search is applied                                            | The user clicks the **Clear** button                                                 | All filter fields are cleared (GET `/stocks` with no `q` params) and the full unfiltered list is shown                                                      |
| AC-05 | The stock list page                                                                      | The page renders                                                                     | Each row shows a **Last Updated** column displaying `ProductStock#updated_at` formatted as `"DD MMM YYYY HH:MM"` (e.g. "15 Apr 2026 14:25"), right-aligned |
| AC-06 | The stock list page with a search that matches zero records                              | The page renders                                                                     | The table body is empty and the existing "No stock records found." empty-state message is shown beneath the table                                           |

**Edge Cases:**

- Search by SKU: `product_name_cont` does not match SKU. Add `product_sku_cont` as an OR condition in the Ransack search (use Ransack `q[product_name_or_product_sku_cont]`).
- Branch dropdown must list only branches that have at least one `ProductStock` record in the current unfiltered policy scope — OR all branches (simpler); use all branches for the dropdown.
- `ProductStock#updated_at` is automatically touched by `increment!`/`decrement!` calls in `deposit!`, `withdraw!`, `withdraw_from_holding!`, and `reset_stock!`, so no additional `touch:` configuration is required.

| #          | Task                                                                                                                                                                       | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-13-02-01 | Update `StocksController#index` to load `@branches = Branch.order(:name)` for the branch dropdown                                                                         | `[x]`  |
| T-13-02-02 | Update `ProductStock.ransackable_attributes` to include `updated_at` (already has `created_at`)                                                                           | `[x]`  |
| T-13-02-03 | Add search/filter bar to `app/views/stocks/index.html.erb`: product name/SKU text input (`q[product_name_or_product_sku_cont]`), branch select (`q[branch_id_eq]`), **Search** and **Clear** buttons — use Ransack form helpers (`search_form_for @ransack`) | `[x]`  |
| T-13-02-04 | Add **Last Updated** column header (`<th>`) and cell (`<td>`) to the stocks table in `app/views/stocks/index.html.erb`, displaying `stock.updated_at.strftime("%d %b %Y %H:%M")` | `[x]`  |
| T-13-02-05 | Write RSpec request spec: `GET /stocks?q[product_name_cont]=<name>` returns only matching rows (HTTP 200, correct body content)                                           | `[x]`  |
| T-13-02-06 | Write RSpec request spec: `GET /stocks?q[branch_id_eq]=<id>` returns only rows for that branch                                                                           | `[x]`  |

---

### STORY-13-03 — Reset Stock to Zero with Mandatory Reason and Confirmation

**Status:** � Completed
**Description:** An authorised user can reset a product's stock amount to zero from the stock detail page. The user must enter a mandatory reason. The browser shows a confirmation dialog before submission. The reset is an atomic operation recorded as a new `RS` transaction type in the ledger.

**User Perspective:**
As a Stock Manager, I want to reset a product's stock to zero with a required reason, so that the action is intentional, auditable, and cannot be done by accident.

**Acceptance Criteria:**

| #     | Given                                                                                     | When                                                                                              | Then                                                                                                                                                                                                             |
| ----- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | An authorised user (`change_product_stocks` permission) on the stock detail page          | The page renders                                                                                  | A **Reset Stock** button with a reason text field is visible below the Deposit/Withdraw section                                                                                                                  |
| AC-02 | The user enters a reason and clicks **Reset Stock**                                       | The browser confirmation dialog appears                                                           | The dialog reads: "Reset stock to 0? This cannot be undone."                                                                                                                                                     |
| AC-03 | The user confirms the dialog and the reason field is non-blank                            | The form submits `POST /stocks/:id/reset_stock` with `reason` param                               | `ProductStock#amount` is set to `0.00`; a `ProductStockTransaction` with `transaction_type: "RS"`, `amount = pre-reset amount`, `reason = submitted reason`, and `adjuster_id = current_user.id` is created; responds with redirect `302` to `/stocks/:id`; flash notice reads "Stock has been reset to 0." |
| AC-04 | The user confirms the dialog but the reason field is blank                                | The form submits `POST /stocks/:id/reset_stock` with blank `reason`                               | Redirects `302` back to `/stocks/:id`; flash alert reads "Reason is required to reset stock."; `ProductStock#amount` is **not** changed; no transaction is created                                              |
| AC-05 | The current stock `amount` is already `0.00`                                             | The user confirms and submits the reset form with a valid reason                                  | Redirects `302` back to `/stocks/:id`; flash notice reads "Stock is already at zero — no changes made."; no transaction is created                                                                              |
| AC-06 | An unauthorised user (no `change_product_stocks` permission)                              | They send `POST /stocks/:id/reset_stock`                                                          | They receive a `403 Forbidden` response (Pundit `NotAuthorizedError` handled by `ApplicationController`)                                                                                                         |

**Edge Cases:**

- `ProductStockTransaction` already validates `amount > 0`. The `RS` transaction is created with `amount = pre-reset amount` only when `pre-reset amount > 0`. When amount is already zero the transaction is skipped (AC-05).
- `holding_amount` is **not** modified by reset — stock is forced to zero regardless of existing holds, which may produce a negative `total_amount`. This is intentional (forced zero-out).
- The `Reset Stock` reason field has a 255-character maximum, consistent with `ProductStockTransaction#reason` validation.

| #          | Task                                                                                                                                                                                    | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-13-03-01 | Add `"RS"` to `ProductStockTransaction::TYPES` constant array                                                                                                                          | `[x]`  |
| T-13-03-02 | Implement `ProductStock#reset_stock!(reason:, adjuster: nil)` instance method: wrap in `with_lock`; guard for `amount == 0` (return `:already_zero`); capture `pre_amount = amount`; call `update_columns(amount: 0)`; call `create_transaction!(transaction_type: "RS", amount: pre_amount, reason: reason, adjuster: adjuster)`; return `:ok` | `[x]`  |
| T-13-03-03 | Add member route `post :reset_stock` to `resources :stocks` in `config/routes.rb`                                                                                                     | `[x]`  |
| T-13-03-04 | Add `reset_stock` action to `StocksController`: authorize with `update?`; validate `reason.present?`; call `@stock.reset_stock!(reason: reason, adjuster: current_user)`; branch on return value for flash; redirect to `stock_path(@stock)` | `[x]`  |
| T-13-03-05 | Add Reset Stock section to `app/views/stocks/show.html.erb` (inside `policy(@stock).update?` guard): a form (`form_with url: reset_stock_stock_path(@stock), method: :post`) with a required text field for `reason` (max 255 chars), a red **Reset Stock** submit button, and `data-turbo-confirm: "Reset stock to 0? This cannot be undone."` on the submit button | `[x]`  |
| T-13-03-06 | Write RSpec model spec: `reset_stock!` with valid reason sets `amount` to `0`, creates `RS` transaction with correct `amount` and `adjuster_id`; calling it when amount is `0` returns `:already_zero` and creates no transaction | `[x]`  |
| T-13-03-07 | Write RSpec request spec: `POST /stocks/:id/reset_stock` — with valid reason redirects with notice, amount is zero, RS transaction exists; with blank reason redirects with alert, amount unchanged; as unauthorised user receives 403 | `[x]`  |

---

### STORY-13-04 — Stock Page Shortcut in Product List Row

**Status:** � Completed
**Description:** Each product row in the Products list (`/products`) that has stock tracking enabled shows a direct "Stock" link in the ACTIONS column. The link navigates to the stock list pre-filtered for that product.

**User Perspective:**
As a Stock Manager, I want a one-click shortcut from the product list to a product's stock records, so that I don't have to navigate to the Stock module and search manually.

**Acceptance Criteria:**

| #     | Given                                                                                                   | When                                                                               | Then                                                                                                                                       |
| ----- | ------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | A product with `enable_stock: true` and the logged-in user has `view_product_stocks` permission         | The Products list page (`/products`) renders                                       | A **"Stock"** link is present in the ACTIONS cell of that product's row                                                                   |
| AC-02 | The user clicks the "Stock" link on a product row                                                       | Navigation occurs                                                                  | The browser navigates to `GET /stocks?q[product_id_eq]=<product.id>` and the stock list shows only records for that product               |
| AC-03 | A product with `enable_stock: false`                                                                    | The Products list page renders                                                     | No "Stock" link is rendered in that product's ACTIONS cell                                                                                |
| AC-04 | A logged-in user without `view_product_stocks` permission                                               | The Products list page renders                                                     | No "Stock" link is rendered for any product row, regardless of `enable_stock` value                                                       |
| AC-05 | A child product row (type `Ch`, rendered as a nested sub-row in `app/views/products/index.html.erb`)    | The Products list page renders                                                     | If the child product has `enable_stock: true` and the user has permission, a "Stock" link is rendered in its ACTIONS cell as well         |

**Edge Cases:**

- The filtered stock list (`/stocks?q[product_id_eq]=<id>`) may be empty (no `ProductStock` yet created for that product). The existing "No stock records found." empty state handles this — no additional changes needed.
- The "Stock" link must be wrapped in the same permission guard used elsewhere: `policy(ProductStock.new).index?` on `ProductStockPolicy`.

| #          | Task                                                                                                                                                                                              | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-13-04-01 | Update the parent product ACTIONS cell in `app/views/products/index.html.erb`: add `<% if product.enable_stock? && policy(ProductStock.new).index? %><%= link_to "Stock", stocks_path(q: { product_id_eq: product.id }), class: "text-indigo-600 hover:underline text-xs" %><% end %>` before the Images link | `[x]`  |
| T-13-04-02 | Apply the same Stock link addition to the **child product sub-row** ACTIONS cell within the nested `product.children.each` loop in `app/views/products/index.html.erb`                           | `[x]`  |
| T-13-04-03 | Write RSpec request spec: `GET /products` — response body includes `stocks_path(q: { product_id_eq: product.id })` URL for products with `enable_stock: true`; does not include it for products with `enable_stock: false` | `[x]`  |
| T-13-04-04 | Write RSpec request spec: `GET /stocks?q[product_id_eq]=<id>` — returns HTTP 200 and only includes stock records for the given product                                                          | `[x]`  |
---

### STORY-13-05 — Lock Cancelled Order Status & Return Stock on Cancellation

**Status:** 🟢 Completed
**Description:** Once an order reaches the `Cc` (Cancelled) status, its status cannot be changed to any other status. Additionally, when an order is first cancelled, every order line whose product has stock tracking enabled has its stock returned (deposited) with an auditable reason referencing the order number.

**User Perspective:**
As a Stock Manager and Operations lead, I want cancelled orders to be permanently locked and their stock returned automatically, so that inventory is always accurate and cancelled orders cannot be accidentally re-activated.

**Acceptance Criteria:**

| #     | Given                                                                                                   | When                                                                                              | Then                                                                                                                                                                                                     |
| ----- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | An order with `status: "Cc"` viewed on the Edit Order page                                             | The page renders                                                                                  | The Status dropdown shows "Cancelled" and is rendered as **disabled** (HTML `disabled` attribute); the option values `Dr`, `Pd`, `Cp` are not selectable                                                |
| AC-02 | An order with `status: "Cc"`                                                                            | A `PATCH /orders/:id` request is submitted with `status` set to any value other than `"Cc"` (e.g. via direct HTTP manipulation) | The update is rejected; the order `status` remains `"Cc"` in the database; the response renders the edit form with HTTP `422` and an error: `"Cancelled orders cannot be re-activated."` |
| AC-03 | An order currently in `Dr`, `Pd`, or `Cp` status with at least one order line for a stock-enabled product | The user saves the edit form with `status` changed to `"Cc"`                                      | For each order line with a stock-enabled product, `ProductStock#deposit!` is called with `amount: line.quantity`, `reason: "Order #{order.order_number} cancelled"`, `related_object: order_line`; the stock transactions are created in the database |
| AC-04 | An order already in `Cc` status                                                                         | The user submits `PATCH /orders/:id` with `status: "Cc"` again (no-change)                       | The update proceeds normally (no double-deposit); no new stock transactions are created                                                                                                                   |
| AC-05 | An order with a mix of stock-enabled and stock-disabled products                                        | The order is cancelled                                                                             | Only products with `enable_stock: true` have their stock returned; no error is raised for non-stock products                                                                                             |
| AC-06 | The bulk status update (`PATCH /orders/bulk_update_status`)                                             | The new status is any value and some of the targeted orders have `status: "Cc"`                   | Already-cancelled orders are skipped (not updated); non-cancelled orders are updated; the response JSON includes a `skipped_count` field with the number of orders that were skipped                    |

**Edge Cases:**

- Stock return on cancellation fires **only on transition** (previous status ≠ `"Cc"` and new status == `"Cc"`). Use `saved_change_to_status?` / `before_save` pattern on the `Order` model to capture the previous value and trigger returns after commit.
- `holding_amount` is **not** affected by the cancellation deposit — the cancellation reversal uses `deposit!`, not `withdraw_from_holding!`.
- If `deposit!` raises an error for any line, the entire `Order#update` transaction must roll back (all deposits are performed inside the `after_commit` callback's outer transaction via a service object to ensure atomicity — or wrapped in a `transaction` block).
- The `bulk_update_status` endpoint currently uses `update_all` which bypasses model callbacks. It must be updated to skip already-cancelled orders without triggering individual model callbacks (since bulk does not currently touch stock — only the targeted status transition from the edit form triggers stock return).

| #          | Task                                                                                                                                                                                                   | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-13-05-01 | Add `validate :status_immutable_when_cancelled` to `Order` model: if `status_was == "Cc"` and `status_changed?` and `status != "Cc"`, add error `base: "Cancelled orders cannot be re-activated."`   | `[x]`  |
| T-13-05-02 | Add `after_commit :return_stock_on_cancellation, on: :update` callback to `Order` model: call only when `saved_change_to_status?` and `status == "Cc"` and `status_before_last_save != "Cc"`         | `[x]`  |
| T-13-05-03 | Implement `Order#return_stock_on_cancellation` private method: iterate `order_lines.includes(:product)`; for each line where `product.enable_stock?`, call `ProductStock.find_or_create_for!(product: line.product).deposit!(amount: line.quantity, reason: "Order #{order_number} cancelled", related_object: line)` | `[x]`  |
| T-13-05-04 | Update `app/views/orders/_form.html.erb`: wrap the Status `<select>` with a condition — `if order.status == "Cc"` render a disabled select showing only "Cancelled"; `else` render the current full select | `[x]`  |
| T-13-05-05 | Update `OrdersController#bulk_update_status`: filter out already-cancelled orders before `update_all`; count skipped; include `skipped_count` in JSON response and flash message                      | `[x]`  |
| T-13-05-06 | Write RSpec model spec: `Order` with `status: "Cc"` — setting `status` to `"Dr"/"Pd"/"Cp"` fails validation with correct error message; status `"Cc"` → `"Cc"` is valid                             | `[x]`  |
| T-13-05-07 | Write RSpec model spec: transitioning an order from `"Dr"` to `"Cc"` triggers `return_stock_on_cancellation` and creates deposit transactions for each stock-enabled order line with correct reason and amount | `[x]`  |
| T-13-05-08 | Write RSpec request spec: `PATCH /orders/:id` with `status: "Dr"` on a cancelled order — returns HTTP 422, order remains `"Cc"`, no stock transactions created                                       | `[x]`  |
| T-13-05-09 | Write RSpec request spec: `PATCH /orders/:id` with `status: "Cc"` on a Draft order with stock lines — returns redirect 302, stock deposit transactions exist with correct reason string               | `[x]`  |

---

### STORY-13-06 — Duplicate Order

**Status:** 🟢 Completed
**Description:** An authorised user can duplicate any existing order from the order detail page. The duplicate creates a new order as `Draft` status with today's date and a freshly generated order number, copying all header fields (customer, logistic company, address, telephone, VAT/discount/tax settings, remark, internal note) and all order lines (product, unit, quantity, unit price, discount, description, remark). Order images are **not** copied.

**User Perspective:**
As a Sales staff member, I want to duplicate an existing order with one click, so that I can quickly create a similar order without re-entering all the details.

**Acceptance Criteria:**

| #     | Given                                                                                               | When                                                                         | Then                                                                                                                                                                                                                             |
| ----- | --------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | An authorised user (`add_orders` permission) on the order detail page (`/orders/:id`)              | The page renders                                                             | A **"Duplicate"** button is visible in the header action area (alongside "Export Invoice", "Edit Order")                                                                                                                        |
| AC-02 | The user clicks the **Duplicate** button                                                            | A browser confirmation dialog appears                                        | The dialog reads: "Duplicate this order? A new Draft order will be created with today's date."                                                                                                                                  |
| AC-03 | The user confirms the dialog                                                                        | `POST /orders/:id/duplicate` is submitted                                   | A new `Order` is created with: `status: "Dr"`, `running_date: Date.today`, freshly generated `order_number`, `customer_id`, `logistic_company_id`, `address`, `telephone`, `has_vat`, `is_included_vat`, `discount_price`, `is_discount_percentage`, `discount_percentage`, `is_withholding_tax`, `withholding_tax`, `logistic_status`, `remark`, `internal_note` copied from the source order |
| AC-04 | The duplicate order is created                                                                      | The order lines are copied                                                   | For each source `OrderLine`, a new `OrderLine` is created on the duplicate with `product_id`, `unit`, `quantity`, `unit_price`, `discount_price`, `description`, `remark`, `idx` copied; `id` and `order_id` are fresh values  |
| AC-05 | The duplicate order is created                                                                      | Stock triggers fire on the new order lines                                   | Existing `after_create` stock callbacks on `OrderLine` run normally — if the product has `enable_stock: true` the stock is withdrawn for the duplicated lines                                                                   |
| AC-06 | The duplicate succeeds                                                                              | The controller responds                                                      | Redirects `302` to the new order's detail page (`/orders/:new_id`); flash notice reads: "Order duplicated as #{new_order.order_number}."                                                                                       |
| AC-07 | The duplicate fails (e.g. validation error on order number generation or customer)                  | The controller catches the error                                             | Redirects `302` back to the source order detail page (`/orders/:id`); flash alert reads: "Could not duplicate order: #{error message}."                                                                                        |
| AC-08 | An unauthorised user (no `add_orders` permission)                                                   | They send `POST /orders/:id/duplicate`                                       | They receive a `403 Forbidden` response (Pundit `NotAuthorizedError`)                                                                                                                                                           |
| AC-09 | Order images attached to the source order                                                           | The duplicate is created                                                     | No `OrderImage` records are copied to the duplicate; the duplicate's Images section on the detail page shows empty                                                                                                               |

**Edge Cases:**

- `order_number` is generated fresh by `OrderNumberGenerator` for today's date — it must not conflict with the source order's number.
- `created_by` on the duplicate is set to `current_user` (via the standard `before_create :set_created_by` callback using `Current.user`).
- `idx` (line order) values are preserved from the source order lines so the duplicate displays lines in the same order.
- The duplicate's `grand_total`, `total_price`, and `vat_price` are recalculated by the existing `after_commit` on `OrderLine#recalc_order_grand_total` — no additional calculation is required in the duplicate action.

| #          | Task                                                                                                                                                                                                        | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-13-06-01 | Add member route `post :duplicate` to `resources :orders` in `config/routes.rb`                                                                                                                            | `[ ]`  |
| T-13-06-02 | Add `duplicate?` predicate to `OrderPolicy`: returns `permission?("add_orders")`                                                                                                                           | `[ ]`  |
| T-13-06-03 | Implement `OrderDuplicateService.new(source_order, current_user:).call` service object in `app/services/`: build a new `Order` with copied header attributes + `status: "Dr"`, `running_date: Date.today`; build new `OrderLine` instances for each source line (no `id`); save the order with `order.save!`; return the new order | `[ ]`  |
| T-13-06-04 | Add `duplicate` action to `OrdersController`: `set_order`; authorize with `duplicate?`; call `OrderDuplicateService`; redirect on success or failure                                                       | `[ ]`  |
| T-13-06-05 | Add `Current.user = current_user` assignment before `OrderDuplicateService` call so `before_create :set_created_by` resolves correctly in the service context                                              | `[ ]`  |
| T-13-06-06 | Add **Duplicate** button to `app/views/orders/show.html.erb` header actions area (inside `policy(@order).duplicate?` guard): `button_to "Duplicate", duplicate_order_path(@order), method: :post, data: { turbo_confirm: "Duplicate this order? A new Draft order will be created with today's date." }, class: "..."` | `[ ]`  |
| T-13-06-07 | Write RSpec service spec for `OrderDuplicateService`: creates new order with correct attributes; creates correct number of order lines with matching fields; does not copy `order_images`; new order has `status: "Dr"` and `running_date: Date.today` | `[ ]`  |
| T-13-06-08 | Write RSpec request spec: `POST /orders/:id/duplicate` — authorised user redirects to new order with flash notice; unauthorised user receives 403                                                          | `[ ]`  |