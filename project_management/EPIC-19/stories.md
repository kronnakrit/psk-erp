# EPIC-19 — Order & Product UX Enhancements, Stock Locations, and Logistic Company Improvements

**Phase:** 19
**Status:** 🟢 Completed
**Goal:** Eleven targeted improvements across the Order, Product, Stock, and Logistic Company modules: adding salesperson tracking to orders, removing the redundant logistic status field, introducing a view-all-orders permission, a barcode-scanner bulk-action page, product duplication, a "Create and New" shortcut on the product form, logistic company name uniqueness and active-status control, a new Stock Location CRUD with multi-select in stock detail, stock person assignment, and filtering completed/cancelled orders from the All tab.

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

## Background & Observed UI State

All observations are taken from `http://localhost:3000` on 2026-04-18.

**Order list (`GET /orders`):**
- Columns observed: ORDER #, DATE, CUSTOMER, STATUS, LOGISTIC, GRAND TOTAL, ACTIONS
- Tabs: All, Draft, Paid, Completed, Cancelled
- The **All** tab (`GET /orders`) currently shows all statuses including Completed (`Cp`) and Cancelled (`Cc`)
- No salesperson column present

**Order show (`GET /orders/:id`):**
- Order Details card contains: Status badge, Logistic Status badge, Customer, Logistic Company, Telephone, Address
- No salesperson field present

**Order edit (`GET /orders/:id/edit`):**
- Order Information section: Customer (Tom Select), Order Date, Status (select), Telephone, Address, Logistic Company (Tom Select), Logistic status (select: Wait to Send / Sent / Handpick / To Warehouse)
- No salesperson field present

**Product show (`GET /products/:id`):**
- Header buttons: "View Lots", "Edit" — no Duplicate button

**Product new (`GET /products/new`):**
- Sections: Product Information, Pricing, Details, Custom Attributes
- One submit button at the bottom (scrolled out of viewport in screenshot)

**Stock list (`GET /stocks`):**
- Columns: PRODUCT, BRANCH, AMOUNT, HOLDING, AVAILABLE, LAST UPDATED, ACTIONS — no stock person column

**Stock detail (`GET /stocks/:id`):**
- Sections: Product Lots, Deposit, Withdraw, View Transactions, Recalculate Checkpoint, Reset Stock, Transaction History
- No stock person or stock locations present

**Logistic companies list (`GET /logistic_companies`):**
- Columns: NAME, TELEPHONE, ADDRESS, ACTIONS — no active status column

**Logistic company edit (`GET /logistic_companies/:id/edit`):**
- Fields: Name, Telephone, Address, Remark — no active/inactive toggle

**Order model status codes:** `Dr` (Draft), `Pd` (Paid), `Cp` (Completed), `Cc` (Cancelled)
**Logistic status codes:** `WTS` (Wait to Send), `ST` (Sent), `HP` (Handpick), `TWH` (To Warehouse)

---

## Stories

---

### STORY-19-01 — Add Salesperson to Order

**Status:** 🟢 Completed
**Description:** A `salesperson_id` foreign key (optional, references `users`) is added to `orders`. The order form gains a Tom Select dropdown for salesperson; the order show page displays the salesperson's full name; the order list adds a SALESPERSON column.

**User Perspective:**
As a sales manager, I want to assign a salesperson to each order, so that I know who opened each order and who is responsible for it.

**Acceptance Criteria:**

| #     | Given                                                              | When                                                                | Then                                                                                                                                      |
| ----- | ------------------------------------------------------------------ | ------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin on `GET /orders/new` or `GET /orders/:id/edit`              | Page loads                                                          | A "Salesperson" label and Tom Select dropdown rendered in the Order Information section, listing all active users (first_name last_name)  |
| AC-02 | A salesperson is selected in the dropdown and form is submitted    | `POST /orders` or `PATCH /orders/:id`                               | Response `302` redirect; `order.salesperson_id` is set to the selected user's id in the database                                         |
| AC-03 | No salesperson is selected                                         | `POST /orders` or `PATCH /orders/:id`                               | Response `302` redirect; `order.salesperson_id` is `NULL`; order saves successfully                                                      |
| AC-04 | Admin on `GET /orders/:id`                                        | Page loads                                                          | Order Details card renders "Salesperson" row showing the assigned user's full name; if none assigned, renders "—"                         |
| AC-05 | Admin on `GET /orders`                                            | Page loads                                                          | Table includes a "SALESPERSON" column displaying the assigned user's full name (or "—")                                                   |
| AC-06 | Admin on `GET /orders/:id/edit` where order has an existing salesperson | Page loads                                                 | Tom Select dropdown is pre-populated with the currently assigned salesperson                                                               |

**Edge Cases:**
- If a user is deactivated after being assigned as salesperson, the full name must still render on the show page (display the name from the user record even if `is_active = false`).
- The salesperson dropdown must list users (first_name + last_name) ordered alphabetically.
- No change to existing order validations — `salesperson_id` is optional.

| #          | Task                                                                                                                                                                         | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-01-01 | Write migration: add `salesperson_id bigint references users` (nullable) to `orders` table; add index                                                                        | `[x]`  |
| T-19-01-02 | Add `belongs_to :salesperson, class_name: "User", optional: true` to `app/models/order.rb`                                                                                  | `[x]`  |
| T-19-01-03 | Add `:salesperson_id` to `order_params` permitted params in `app/controllers/orders_controller.rb`                                                                           | `[x]`  |
| T-19-01-04 | Update `app/views/orders/_form.html.erb`: add Tom Select dropdown for salesperson (loads `User.where(is_active: true).order(:first_name)`) below the Address field           | `[x]`  |
| T-19-01-05 | Update `app/views/orders/show.html.erb`: add "Salesperson" row in the Order Details card                                                                                     | `[x]`  |
| T-19-01-06 | Update `app/views/orders/index.html.erb`: add SALESPERSON `th` header and `td` cell (renders `order.salesperson&.profile&.full_name \|\| "—"`)                              | `[x]`  |
| T-19-01-07 | Update `Order.ransackable_associations` to include `salesperson`                                                                                                             | `[x]`  |
| T-19-01-08 | Write RSpec request spec: `PATCH /orders/:id` with `salesperson_id` sets the field (AC-02)                                                                                   | `[x]`  |
| T-19-01-09 | Write RSpec request spec: `GET /orders/:id` renders salesperson name (AC-04)                                                                                                 | `[x]`  |
| T-19-01-10 | Write RSpec request spec: `GET /orders` renders SALESPERSON column (AC-05)                                                                                                   | `[x]`  |

---

### STORY-19-02 — Remove Logistic Status from Order

**Status:** 🟢 Completed
**Description:** The `logistic_status` field is removed from the `orders` table, the Order model, the order form, show view, list view, and all API serialisation. A migration drops the column after removing it from the application layer.

**User Perspective:**
As a product owner, I want the logistic status removed from orders entirely, so that the UI is simplified and no redundant data is stored.

**Acceptance Criteria:**

| #     | Given                                                             | When                                             | Then                                                                                                                               |
| ----- | ----------------------------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin on `GET /orders/:id/edit`                                  | Page loads                                       | No "Logistic status" label or `<select>` rendered in the Order Information section                                                 |
| AC-02 | Admin on `GET /orders/:id`                                       | Page loads                                       | No "Logistic Status" row or badge rendered in the Order Details card                                                               |
| AC-03 | Admin on `GET /orders`                                           | Page loads                                       | No "LOGISTIC" column header or cell rendered in the orders table                                                                   |
| AC-04 | Request includes `order[logistic_status]=ST`                     | `PATCH /orders/:id`                              | Response `302` redirect; `logistic_status` param is silently ignored (column no longer exists)                                     |
| AC-05 | Admin calls `GET /api/v1/orders` (if such API exists)            | Request                                          | Response does **not** contain a `logistic_status` key                                                                              |

**Edge Cases:**
- `Order::LOGISTIC_STATUSES` and `Order::LOGISTIC_STATUS_LABELS` constants must be removed from `app/models/order.rb`.
- Any Ransack search referencing `logistic_status` must be removed from `ransackable_attributes`.
- Any seed data or fixtures referencing `logistic_status` must be updated.
- Removing the column is a destructive, irreversible migration — existing `logistic_status` data will be permanently deleted.

| #          | Task                                                                                                                                                                                  | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-02-01 | Remove `logistic_status` from permitted params in `app/controllers/orders_controller.rb`                                                                                              | `[x]`  |
| T-19-02-02 | Remove "Logistic status" `<select>` from `app/views/orders/_form.html.erb`                                                                                                            | `[x]`  |
| T-19-02-03 | Remove Logistic Status badge/row from `app/views/orders/show.html.erb`                                                                                                                | `[x]`  |
| T-19-02-04 | Remove LOGISTIC column (`th` and `td`) from `app/views/orders/index.html.erb`                                                                                                         | `[x]`  |
| T-19-02-05 | Remove `LOGISTIC_STATUSES`, `LOGISTIC_STATUS_LABELS` constants, `validates :logistic_status`, `logistic_status` scope and `ransackable_attributes` entry from `app/models/order.rb`  | `[x]`  |
| T-19-02-06 | Write migration: `remove_column :orders, :logistic_status`                                                                                                                            | `[x]`  |
| T-19-02-07 | Remove `logistic_status` from any API serialiser in `app/controllers/api/` if present                                                                                                 | `[x]`  |
| T-19-02-08 | Write RSpec request spec: `GET /orders/:id/edit` does not render "Logistic status" (AC-01)                                                                                            | `[x]`  |
| T-19-02-09 | Write RSpec request spec: `GET /orders` does not render LOGISTIC column (AC-03)                                                                                                       | `[x]`  |

---

### STORY-19-03 — Order Visibility Permission (View All vs Own Orders)

**Status:** 🟢 Completed
**Description:** A new permission codename `view_all_orders` is added to `Permissions::ALL`. Users who hold this permission see every order; users who do not see only orders where `salesperson_id = current_user.id`. The restriction applies consistently across the web UI and the API.

**User Perspective:**
As an admin, I want to control whether a salesperson can see all orders or only the ones they are responsible for, so that staff access is appropriately scoped.

**Acceptance Criteria:**

| #     | Given                                                                                           | When                          | Then                                                                                                                                                     |
| ----- | ----------------------------------------------------------------------------------------------- | ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | User has `view_all_orders` permission                                                           | `GET /orders`                 | Response `200`; all orders rendered regardless of salesperson                                                                                            |
| AC-02 | User does **not** have `view_all_orders`; user is salesperson on orders 1 and 3                | `GET /orders`                 | Response `200`; only orders 1 and 3 rendered in the table                                                                                                |
| AC-03 | User does **not** have `view_all_orders`; attempts to view `GET /orders/:id` for order they did not create as salesperson | Request | Response `403` (Pundit not-authorised) or redirect with flash "Not authorised"                                                                         |
| AC-04 | Admin visits `GET /permissions`                                                                 | Page loads                    | `view_all_orders` is listed in the permissions catalogue                                                                                                  |
| AC-05 | User does **not** have `view_all_orders`; order count badge (if any) on the sidebar              | Page loads                    | Badge count reflects only the user's own orders                                                                                                           |

**Edge Cases:**
- If `salesperson_id` is `NULL` on an order and the viewer does not have `view_all_orders`, that order is **not** shown to them (they did not open it).
- Superadmin users (with `admin` permission) implicitly have all permissions; existing admin access remains unaffected.

| #          | Task                                                                                                                                                                                                       | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-03-01 | Add `view_all_orders` to `Permissions::ALL` in `app/models/concerns/permissions.rb`                                                                                                                       | `[x]`  |
| T-19-03-02 | Update `OrderPolicy` (or `OrderPolicy::Scope`) in `app/policies/order_policy.rb`: if `user.can?(:view_all_orders)` → scope all records; else → scope to `where(salesperson_id: user.id)`                  | `[x]`  |
| T-19-03-03 | Update `OrderPolicy#show?` and `OrderPolicy#edit?`: return `false` if user does not have `view_all_orders` and `order.salesperson_id != user.id`                                                           | `[x]`  |
| T-19-03-04 | Ensure `OrdersController#index` and other actions call `policy_scope(Order)` so the Pundit scope is applied                                                                                                 | `[x]`  |
| T-19-03-05 | Write RSpec policy spec: `OrderPolicy::Scope` returns only own orders when `view_all_orders` is absent (AC-02)                                                                                              | `[x]`  |
| T-19-03-06 | Write RSpec policy spec: `OrderPolicy::Scope` returns all orders when `view_all_orders` is present (AC-01)                                                                                                  | `[x]`  |
| T-19-03-07 | Write RSpec request spec: user without `view_all_orders` receives `403` on `GET /orders/:id` for an order not assigned to them (AC-03)                                                                     | `[x]`  |

---

### STORY-19-04 — Barcode Scanner Bulk Action Page

**Status:** 🟢 Completed
**Description:** A new page at `GET /orders/scan` allows a user to scan order barcodes (order numbers printed on invoices/delivery notes) using a barcode scanner operating in keyboard emulation mode. Each scanned order is displayed in a preview list. When done, the user can click "Mark All as Paid" or "Mark All as Complete" to bulk-update all displayed orders via the existing `POST /orders/bulk_update_status` endpoint.

**User Perspective:**
As a warehouse/billing staff member, I want to scan order barcodes and then mark all scanned orders as Paid or Complete in one click, so that I can process a batch of physical orders quickly without navigating to each individually.

**Acceptance Criteria:**

| #     | Given                                                                             | When                                                                            | Then                                                                                                                                                                |
| ----- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin on `GET /orders`                                                           | Page loads                                                                      | A "Scan Orders" button is visible in the page header area, navigating to `GET /orders/scan`                                                                         |
| AC-02 | User on `GET /orders/scan`                                                       | Page loads                                                                      | Page renders with: an auto-focused barcode input field, an empty scanned-orders table, and disabled "Mark All as Paid" and "Mark All as Complete" buttons           |
| AC-03 | User types a valid order number into the input and presses Enter                 | Enter key event fires                                                           | The input is cleared; a `GET /api/v1/orders/find_by_number?q=<order_number>` (or equivalent) request is made; the matching order row is appended to the scanned table |
| AC-04 | The scanned orders table has at least one row                                    | After scan                                                                      | "Mark All as Paid" and "Mark All as Complete" buttons become enabled                                                                                                |
| AC-05 | User scans the same order number twice                                           | Second Enter key event                                                          | A flash-style inline warning is shown: "Order <number> already scanned" — the duplicate is not appended to the list                                                |
| AC-06 | User types an order number that does not match any record and presses Enter      | Enter key event                                                                 | An inline error message is shown: "Order <number> not found" — no row appended                                                                                      |
| AC-07 | User clicks "Mark All as Paid" with 3 scanned orders showing                    | Button click                                                                    | `POST /orders/bulk_update_status` fires with `{order_ids: [...], status: "Pd"}`; response `302`; flash success message; scanned list is cleared                    |
| AC-08 | User clicks "Mark All as Complete" with 3 scanned orders showing                | Button click                                                                    | `POST /orders/bulk_update_status` fires with `{order_ids: [...], status: "Cp"}`; response `302`; flash success message; scanned list is cleared                    |
| AC-09 | User clicks "Remove" on a scanned row                                            | Button click                                                                    | The row is removed from the scanned list; button states re-evaluated                                                                                                |
| AC-10 | Unauthenticated user navigates to `GET /orders/scan`                             | Request                                                                         | Response `302` redirect to `/login`                                                                                                                                 |

**Edge Cases:**
- Barcode scanners in keyboard mode typically send the full code followed by an Enter key press. The Stimulus controller must handle rapid key-down sequences by appending characters to a buffer and flushing on Enter.
- If `view_all_orders` permission is absent, the lookup must still only return orders the user can access (policy-scoped).
- An order in `Cc` (Cancelled) status in the scanned list should show a visual warning badge; clicking "Mark All as Paid/Complete" should skip cancelled orders and report them individually.

| #          | Task                                                                                                                                                                                                                          | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-04-01 | Add `get :scan` and `get :find_by_number` collection routes to `resources :orders` in `config/routes.rb`                                                                                                                      | `[x]`  |
| T-19-04-02 | Add `OrdersController#scan` action (GET) — authenticates, authorises, renders `app/views/orders/scan.html.erb`                                                                                                                | `[x]`  |
| T-19-04-03 | Add `OrdersController#find_by_number` action (GET, JSON) — looks up order by `order_number` using `policy_scope`, returns `{id, order_number, customer_name, status, grand_total}` or `{error: "not found"}` with `404`     | `[x]`  |
| T-19-04-04 | Create `app/views/orders/scan.html.erb` with: page title "Scan Orders", barcode input (`data-barcode-scan-target="input"`), scanned orders `<table>` with Turbo-compatible structure, "Mark All as Paid" and "Mark All as Complete" buttons | `[x]`  |
| T-19-04-05 | Create `app/javascript/controllers/barcode_scan_controller.js` Stimulus controller: handles keydown buffer, flushes on Enter, fetches `find_by_number`, appends rows, manages enabled/disabled state of action buttons        | `[x]`  |
| T-19-04-06 | Add "Scan Orders" button link to `app/views/orders/index.html.erb` header row (alongside "New Order")                                                                                                                         | `[x]`  |
| T-19-04-07 | Implement duplicate-scan guard in `barcode_scan_controller.js`: compare incoming `order_number` against current list; show inline warning if already present                                                                   | `[x]`  |
| T-19-04-08 | Implement "Mark All as Paid" and "Mark All as Complete" form submissions: build hidden inputs for `order_ids[]` and `status`, POST to `/orders/bulk_update_status`                                                             | `[x]`  |
| T-19-04-09 | Implement per-row "Remove" button in `barcode_scan_controller.js` that removes the row from the DOM                                                                                                                            | `[x]`  |
| T-19-04-10 | Write RSpec request spec: `GET /orders/scan` returns `200` for authenticated user (AC-02)                                                                                                                                     | `[x]`  |
| T-19-04-11 | Write RSpec request spec: `GET /orders/find_by_number?q=20260418001` returns correct order JSON (AC-03)                                                                                                                       | `[x]`  |
| T-19-04-12 | Write RSpec request spec: `GET /orders/find_by_number?q=NOTEXIST` returns `404` (AC-06)                                                                                                                                       | `[x]`  |

---

### STORY-19-05 — Duplicate Product Action

**Status:** 🟢 Completed
**Description:** A "Duplicate" button is added to the product show page (`GET /products/:id`). Clicking it sends `POST /products/:id/duplicate`, which creates a copy of the product with a new auto-generated SKU, a new auto-generated barcode, and the name prefixed with "Copy of ". The user is redirected to the new product's edit page to complete any adjustments.

**User Perspective:**
As a catalogue manager, I want to duplicate an existing product, so that I can quickly create variants without re-entering all fields from scratch.

**Acceptance Criteria:**

| #     | Given                                                              | When                                        | Then                                                                                                                                        |
| ----- | ------------------------------------------------------------------ | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin on `GET /products/:id`                                      | Page loads                                  | A "Duplicate" button is rendered in the header alongside "View Lots" and "Edit"                                                             |
| AC-02 | Admin clicks "Duplicate" on product with name "Widget A"          | `POST /products/:id/duplicate`              | Response `302` redirect to `GET /products/:new_id/edit`; new product created with name "Copy of Widget A", new unique SKU, new unique barcode |
| AC-03 | New duplicated product                                            | Created in database                         | `product_type`, `price`, `brand_id`, `vendor_id`, `product_class_id`, `unit_group_id`, `description`, `description_th`, `remark`, `enable_stock`, `unit` are copied from the original |
| AC-04 | New duplicated product                                            | Created in database                         | `parent_id`, `product_attributes`, and `product_category` associations are **not** copied (left blank/default)                               |
| AC-05 | User without `add_products` permission                            | `POST /products/:id/duplicate`              | Response `403`                                                                                                                              |

**Edge Cases:**
- If the product name is already prefixed with "Copy of", the new name becomes "Copy of Copy of …" — no special handling needed.
- `product_images` are not copied to the duplicate; the new product starts with no images.
- The new product is a full `Standalone` or `Parent` type copy; child products (`parent_id` present) may be duplicated but `parent_id` is cleared in the copy.

| #          | Task                                                                                                                                                              | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-05-01 | Add `member { post :duplicate }` to `resources :products` in `config/routes.rb`                                                                                   | `[x]`  |
| T-19-05-02 | Add `ProductsController#duplicate` action: calls `Products::DuplicateService.new(product).call`, redirects to `edit_product_path(new_product)` on success        | `[x]`  |
| T-19-05-03 | Create `app/services/products/duplicate_service.rb`: duplicates product scalar fields (name prefixed "Copy of ", new SKU/barcode via existing generators), persists | `[x]`  |
| T-19-05-04 | Update `ProductPolicy#duplicate?` (or add to existing policy): requires `add_products` permission                                                                  | `[x]`  |
| T-19-05-05 | Add "Duplicate" button to `app/views/products/show.html.erb` header row (data-method POST, with confirmation dialog)                                              | `[x]`  |
| T-19-05-06 | Write RSpec service spec: `Products::DuplicateService` creates product with correct copied fields and new SKU/barcode (AC-02, AC-03)                               | `[x]`  |
| T-19-05-07 | Write RSpec request spec: `POST /products/:id/duplicate` redirects to edit page (AC-02)                                                                           | `[x]`  |
| T-19-05-08 | Write RSpec request spec: unauthorized user receives `403` (AC-05)                                                                                                | `[x]`  |

---

### STORY-19-06 — "Create and New" Button on Product Form

**Status:** 🟢 Completed
**Description:** The product new/create form gains a secondary "Create and New" submit button. When clicked, the product is saved and the user is immediately redirected to `GET /products/new` (a blank product form), allowing rapid sequential product creation without navigating away.

**User Perspective:**
As a catalogue manager, I want a "Create and New" button on the new product form, so that I can create multiple products in succession without switching views.

**Acceptance Criteria:**

| #     | Given                                                                  | When                                                                  | Then                                                                                                                                             |
| ----- | ---------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | Admin on `GET /products/new`                                          | Page loads                                                            | Two submit buttons rendered: "Create Product" (existing) and "Create and New"                                                                    |
| AC-02 | Admin fills in required fields and clicks "Create and New"             | `POST /products` with `commit=Create+and+New` (or `create_and_new=1`) | Response `302` redirect to `GET /products/new`; product is created in the database; flash success "Product created"                              |
| AC-03 | Admin fills in required fields and clicks the original "Create Product" | `POST /products`                                                      | Behaviour unchanged: response `302` redirect to `GET /products/:id` (show page)                                                                 |
| AC-04 | Validation fails (e.g. name is blank) and user clicked "Create and New" | `POST /products`                                                      | Response `422`; product new form re-rendered with validation errors; "Create and New" button still present                                        |

**Edge Cases:**
- The `create_and_new` distinction is detected by checking `params[:commit]` value or a hidden field — no new controller action required; modify `create` action only.
- The "Create and New" button must also be absent (not rendered) on the edit page (`GET /products/:id/edit`).

| #          | Task                                                                                                                                                                    | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-06-01 | Add "Create and New" submit button to `app/views/products/_form.html.erb` (renders only when `product.new_record?`)                                                     | `[x]`  |
| T-19-06-02 | Update `ProductsController#create`: after successful save, check `params[:commit]`; if `"Create and New"` → `redirect_to new_product_path, notice: "Product created."` | `[x]`  |
| T-19-06-03 | Write RSpec request spec: `POST /products` with `commit=Create and New` redirects to `new_product_path` (AC-02)                                                        | `[x]`  |
| T-19-06-04 | Write RSpec request spec: `POST /products` without `commit=Create and New` redirects to product show page (AC-03 — regression)                                         | `[x]`  |

---

### STORY-19-07 — Logistic Company Name Uniqueness

**Status:** 🟢 Completed
**Description:** A unique database index is added to `logistic_companies.name` and a Rails uniqueness validation is added to the `LogisticCompany` model to prevent duplicate company names. The form displays an appropriate validation error when a duplicate name is submitted.

**User Perspective:**
As an admin, I want logistic company names to be unique, so that dropdown lists elsewhere in the system do not contain confusingly duplicate entries.

**Acceptance Criteria:**

| #     | Given                                                              | When                                                                  | Then                                                                                                                                   |
| ----- | ------------------------------------------------------------------ | --------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Logistic company "DHL Express" already exists                     | `POST /logistic_companies` with `name=DHL Express`                   | Response `422`; form re-rendered with error "Name has already been taken"                                                              |
| AC-02 | Logistic company "DHL Express" already exists                     | `PATCH /logistic_companies/:id` on a different record with `name=DHL Express` | Response `422`; form re-rendered with error "Name has already been taken"                                                     |
| AC-03 | Logistic company "DHL Express" already exists and same record is updated with same name | `PATCH /logistic_companies/:id`                   | Response `302` redirect; update succeeds (uniqueness scoped to other records)                                                           |
| AC-04 | Valid unique name submitted                                        | `POST /logistic_companies`                                            | Response `302` redirect; record created                                                                                                |

**Edge Cases:**
- Uniqueness validation should be **case-insensitive** (e.g. "dhl express" conflicts with "DHL Express") — use `validates :name, uniqueness: { case_sensitive: false }` and a lowercased functional index in PostgreSQL.
- Existing duplicate names in the database (if any) will cause the migration to fail; the task list includes a deduplication step.

| #          | Task                                                                                                                                                                                      | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-07-01 | Check for existing duplicate `logistic_companies.name` values in the database; if found, rename duplicates (append ` (2)`, ` (3)` etc.) before adding unique index                       | `[x]`  |
| T-19-07-02 | Write migration: add unique index `index_logistic_companies_on_lower_name` on `lower(name)` using `algorithm: :concurrently` (or equivalent safe migration)                              | `[x]`  |
| T-19-07-03 | Add `validates :name, presence: true, uniqueness: { case_sensitive: false }` to `app/models/logistic_company.rb`                                                                          | `[x]`  |
| T-19-07-04 | Write RSpec model spec: uniqueness validation prevents duplicate case-insensitive names (AC-01)                                                                                            | `[x]`  |
| T-19-07-05 | Write RSpec request spec: `POST /logistic_companies` with duplicate name returns `422` and error message (AC-01)                                                                           | `[x]`  |

---

### STORY-19-08 — Logistic Company Active Status

**Status:** 🟢 Completed
**Description:** An `is_active` boolean (default `true`) is added to `logistic_companies`. The list view shows an Active/Inactive badge per row. Admin can toggle a company's status via "Deactivate"/"Activate" buttons. Dropdowns throughout the system (order form, customer form) only show active logistic companies.

**User Perspective:**
As an admin, I want to deactivate logistic companies that are no longer in use, so that staff do not accidentally assign a discontinued carrier to new orders.

**Acceptance Criteria:**

| #     | Given                                                                      | When                                                              | Then                                                                                                                               |
| ----- | -------------------------------------------------------------------------- | ----------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin on `GET /logistic_companies`                                        | Page loads                                                        | Each row shows an "Active" (green) or "Inactive" (gray) badge in an ACTIVE column; new companies default to Active                 |
| AC-02 | Admin clicks "Deactivate" on an active logistic company                   | `PATCH /logistic_companies/:id/deactivate`                        | Response `302`; `is_active` set to `false`; row now shows "Inactive" badge                                                         |
| AC-03 | Admin clicks "Activate" on an inactive logistic company                   | `PATCH /logistic_companies/:id/activate`                          | Response `302`; `is_active` set to `true`; row now shows "Active" badge                                                            |
| AC-04 | Admin on `GET /orders/new` or `GET /orders/:id/edit`                      | Page loads                                                        | Logistic Company Tom Select dropdown lists **only** companies where `is_active = true`                                             |
| AC-05 | Admin on `GET /customers/new` or `GET /customers/:id/edit`                | Page loads                                                        | Logistic Company dropdown lists **only** companies where `is_active = true`                                                        |
| AC-06 | An order already has an inactive logistic company assigned                | `GET /orders/:id` page loads                                      | Inactive company name is still shown (display only, not affected by active filter)                                                  |
| AC-07 | Admin creates a new logistic company without specifying active status     | `POST /logistic_companies`                                        | `is_active` defaults to `true`; company appears as "Active"                                                                        |

**Edge Cases:**
- Deactivating a company that is currently assigned to active orders does not change those orders — it only prevents future assignment.
- The `is_active` field should appear as a checkbox in the `new`/`edit` form, defaulting to checked.

| #          | Task                                                                                                                                                                                     | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-08-01 | Write migration: add `is_active boolean default true not null` to `logistic_companies`                                                                                                   | `[x]`  |
| T-19-08-02 | Add `validates :is_active, inclusion: { in: [true, false] }` and named scope `active -> { where(is_active: true) }` to `app/models/logistic_company.rb`                                 | `[x]`  |
| T-19-08-03 | Add `member { patch :activate; patch :deactivate }` routes to `resources :logistic_companies` in `config/routes.rb`                                                                      | `[x]`  |
| T-19-08-04 | Add `LogisticCompaniesController#activate` and `#deactivate` actions                                                                                                                    | `[x]`  |
| T-19-08-05 | Add ACTIVE column (badge) to `app/views/logistic_companies/index.html.erb` with Activate/Deactivate toggle buttons per row                                                               | `[x]`  |
| T-19-08-06 | Add `is_active` checkbox field to `app/views/logistic_companies/_form.html.erb`                                                                                                          | `[x]`  |
| T-19-08-07 | Update `app/views/orders/_form.html.erb`: change logistic company dropdown query to `LogisticCompany.active.order(:name)`                                                                | `[x]`  |
| T-19-08-08 | Update `app/views/customers/_form.html.erb`: change logistic company dropdown query to `LogisticCompany.active.order(:name)`                                                             | `[x]`  |
| T-19-08-09 | Write RSpec request spec: `PATCH /logistic_companies/:id/deactivate` sets `is_active` to false (AC-02)                                                                                   | `[x]`  |
| T-19-08-10 | Write RSpec request spec: `GET /orders/new` logistic dropdown only lists active companies (AC-04)                                                                                         | `[x]`  |
| T-19-08-11 | Write RSpec model spec: `LogisticCompany.active` scope returns only active records                                                                                                        | `[x]`  |

---

### STORY-19-09 — Stock Location CRUD & Multi-Select in Stock Detail

**Status:** 🟢 Completed
**Description:** A new `StockLocation` model is created with full CRUD. A join table `product_stock_locations` links stock records to multiple locations. The stock detail page (`GET /stocks/:id`) gains a multi-select Tom Select dropdown for assigning locations. Assigned locations are shown in the Product Lots section.

**User Perspective:**
As a warehouse manager, I want to define named stock locations and assign multiple locations to a stock record, so that I know exactly where inventory is physically stored.

**Acceptance Criteria:**

| #     | Given                                                                           | When                                                             | Then                                                                                                                                           |
| ----- | ------------------------------------------------------------------------------- | ---------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin navigates to a new "Stock Locations" page (via sidebar or menu)          | `GET /stock_locations`                                           | Page lists all stock locations with NAME, DESCRIPTION columns and Edit/Delete actions; "New Stock Location" button present                      |
| AC-02 | Admin fills in Name and Description and clicks "Create"                        | `POST /stock_locations`                                          | Response `302`; new record created; redirected to index; flash "Stock location created"                                                         |
| AC-03 | Admin submits a blank Name                                                      | `POST /stock_locations`                                          | Response `422`; form re-rendered with "Name can't be blank"                                                                                     |
| AC-04 | Admin deletes a stock location that is assigned to a stock record               | `DELETE /stock_locations/:id`                                    | Response `302`; location deleted; join rows removed via `dependent: :destroy`                                                                   |
| AC-05 | Admin on `GET /stocks/:id`                                                     | Page loads                                                       | A "Stock Locations" multi-select Tom Select dropdown is rendered, pre-populated with currently assigned locations                               |
| AC-06 | Admin selects 2 locations in the dropdown and saves                            | `PATCH /stocks/:id` with `product_stock[stock_location_ids][]`  | Response `302`; `product_stock.stock_locations` association updated to the two selected; previously selected locations not in the new set are removed |
| AC-07 | Admin clears all locations and saves                                            | `PATCH /stocks/:id` with empty `stock_location_ids`             | Response `302`; all location associations removed                                                                                               |

**Edge Cases:**
- Stock locations should be unique by name (database unique index + Rails validation).
- The `PATCH /stocks/:id` endpoint does not yet exist as a web UI update route — a new `:update` action must be added to `stocks` resources (currently only `index`, `show`, and member action routes exist).
- The Tom Select on the stock detail page must use the multi-select mode (`maxItems: null`).
- `StockLocation` is not soft-deleted; hard delete removes it and cleans up joins.

| #          | Task                                                                                                                                                                                                            | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-09-01 | Write migration: `create_table :stock_locations` with `name:string (not null, unique)`, `description:text`, timestamps                                                                                          | `[x]`  |
| T-19-09-02 | Write migration: `create_table :product_stock_locations` with `product_stock_id:bigint (not null)`, `stock_location_id:bigint (not null)`, composite unique index on both columns                               | `[x]`  |
| T-19-09-03 | Create `app/models/stock_location.rb`: `validates :name, presence: true, uniqueness: { case_sensitive: false }`; `has_many :product_stock_locations, dependent: :destroy`; `has_many :product_stocks, through: :product_stock_locations` | `[x]`  |
| T-19-09-04 | Create `app/models/product_stock_location.rb`: `belongs_to :product_stock`; `belongs_to :stock_location`; unique validation on pair                                                                              | `[x]`  |
| T-19-09-05 | Update `app/models/product_stock.rb`: add `has_many :product_stock_locations, dependent: :destroy`; `has_many :stock_locations, through: :product_stock_locations`                                               | `[x]`  |
| T-19-09-06 | Generate `StockLocationsController` with full CRUD (index, new, create, edit, update, destroy); add to `config/routes.rb` as `resources :stock_locations`                                                       | `[x]`  |
| T-19-09-07 | Create views: `app/views/stock_locations/index.html.erb`, `_form.html.erb`, `new.html.erb`, `edit.html.erb`                                                                                                     | `[x]`  |
| T-19-09-08 | Create `app/policies/stock_location_policy.rb` using `view_product_stocks` / `change_product_stocks` permissions                                                                                                 | `[x]`  |
| T-19-09-09 | Add `resources :stocks, only: %i[index show update]` (add `:update`) to `config/routes.rb`                                                                                                                      | `[x]`  |
| T-19-09-10 | Add `StocksController#update` action: accepts `stock_location_ids: []` in permitted params; updates `product_stock.stock_location_ids`; redirects back to `GET /stocks/:id`                                     | `[x]`  |
| T-19-09-11 | Add multi-select Tom Select Stock Locations widget to `app/views/stocks/show.html.erb` with a small form POSTing PATCH to `stocks/:id`                                                                          | `[x]`  |
| T-19-09-12 | Add "Stock Locations" link to the sidebar in `app/views/layouts/_sidebar.html.erb`                                                                                                                               | `[x]`  |
| T-19-09-13 | Write RSpec request spec: `POST /stock_locations` creates record (AC-02)                                                                                                                                         | `[x]`  |
| T-19-09-14 | Write RSpec request spec: `PATCH /stocks/:id` with `stock_location_ids` updates associations (AC-06)                                                                                                             | `[x]`  |
| T-19-09-15 | Write RSpec model spec: `StockLocation` validates name presence and uniqueness                                                                                                                                   | `[x]`  |

---

### STORY-19-10 — Stock Person in Stock Detail and List View

**Status:** 🟢 Completed
**Description:** A `stock_person_id` FK (optional, references `users`) is added to `product_stocks`. The stock detail page (`GET /stocks/:id`) gains a Tom Select dropdown to assign a stock person. The stock list view (`GET /stocks`) gains a STOCK PERSON column.

**User Perspective:**
As a warehouse manager, I want to designate a responsible person per stock record, so that I know who to contact about a given product's inventory.

**Acceptance Criteria:**

| #     | Given                                                                                         | When                                                          | Then                                                                                                                                           |
| ----- | --------------------------------------------------------------------------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin on `GET /stocks/:id`                                                                   | Page loads                                                    | A "Stock Person" Tom Select dropdown is rendered, listing all active users, pre-populated if one is already assigned                           |
| AC-02 | Admin selects a user and saves                                                                | `PATCH /stocks/:id` with `product_stock[stock_person_id]=X`  | Response `302`; `product_stock.stock_person_id` updated; stock detail page shows the assigned user's full name                                  |
| AC-03 | Admin clears the stock person selection and saves                                             | `PATCH /stocks/:id` with blank `stock_person_id`             | Response `302`; `product_stock.stock_person_id` set to `NULL`                                                                                  |
| AC-04 | Admin on `GET /stocks`                                                                       | Page loads                                                    | Table includes a STOCK PERSON column displaying the assigned user's full name (or "—")                                                         |

**Edge Cases:**
- The `PATCH /stocks/:id` route is already added in STORY-19-09. This story extends the same action to also accept `stock_person_id` in permitted params.
- If a user is deactivated after assignment, their name is still rendered in both the list and detail views.

| #          | Task                                                                                                                                                                                   | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-10-01 | Write migration: add `stock_person_id bigint references users` (nullable, with index) to `product_stocks`                                                                              | `[x]`  |
| T-19-10-02 | Add `belongs_to :stock_person, class_name: "User", optional: true` to `app/models/product_stock.rb`                                                                                   | `[x]`  |
| T-19-10-03 | Add `stock_person_id` to permitted params in `StocksController#update` (alongside `stock_location_ids` from STORY-19-09)                                                              | `[x]`  |
| T-19-10-04 | Add Tom Select "Stock Person" dropdown to `app/views/stocks/show.html.erb` within the stock update form (same form as stock locations widget)                                          | `[x]`  |
| T-19-10-05 | Add STOCK PERSON column (`th` and `td`) to `app/views/stocks/index.html.erb`                                                                                                           | `[x]`  |
| T-19-10-06 | Write RSpec request spec: `PATCH /stocks/:id` with `stock_person_id` updates the field (AC-02)                                                                                         | `[x]`  |
| T-19-10-07 | Write RSpec request spec: `GET /stocks` renders STOCK PERSON column (AC-04)                                                                                                            | `[x]`  |

---

### STORY-19-11 — Filter Completed & Cancelled Orders from the "All" Tab

**Status:** 🟢 Completed
**Description:** The default Orders list (`GET /orders`, the "All" tab) is renamed to **"Active"** and is changed to exclude orders with status `Cp` (Completed) and `Cc` (Cancelled). Orders with these statuses remain accessible via the dedicated "Completed" and "Cancelled" tabs.

**User Perspective:**
As a sales staff member, I want the All tab to show only active orders (Draft and Paid), so that the default view is not cluttered with closed or cancelled orders.

**Acceptance Criteria:**

| #     | Given                                                                      | When                              | Then                                                                                                                              |
| ----- | -------------------------------------------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Database contains orders with statuses `Dr`, `Pd`, `Cp`, and `Cc`        | `GET /orders`                     | Response `200`; only orders with `status IN ('Dr', 'Pd')` are rendered; no `Cp` or `Cc` rows present                            |
| AC-02 | Database contains Completed orders                                         | `GET /orders/completed`           | Response `200`; only Completed orders rendered (behaviour unchanged)                                                             |
| AC-03 | Database contains Cancelled orders                                         | `GET /orders/cancelled`           | Response `200`; only Cancelled orders rendered (behaviour unchanged)                                                             |
| AC-04 | Database contains orders with all statuses                                 | `GET /orders` (All tab)           | Pagination count reflects only `Dr` + `Pd` orders; "Showing X–Y of Z" excludes `Cp` and `Cc` in Z                              |
| AC-05 | Ransack search on `GET /orders?q[order_number_cont]=20260412`              | Search with query                 | Search results are scoped to `Dr` + `Pd` statuses (no completed/cancelled orders returned in All tab search)                     |

**Edge Cases:**
- The "All" tab link text in `app/views/orders/index.html.erb` is renamed from "All" to "Active" (`link_to "Active", orders_path`).
- The policy scope from STORY-19-03 (`view_all_orders`) is applied **before** the status filter, so both filters are additive.
- The `GET /orders/draft` and `GET /orders/paid` tabs are unaffected.

| #          | Task                                                                                                                                                              | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-19-11-01 | Rename tab link text from "All" to "Active" in `app/views/orders/index.html.erb` | `[x]`  |
| T-19-11-02 | Update `OrdersController#index` default scope: change the base query to `policy_scope(Order).where(status: %w[Dr Pd]).order(running_date: :desc, order_number: :desc)` | `[x]`  |
| T-19-11-03 | Verify `OrdersController#draft`, `#paid`, `#completed`, `#cancelled` actions are unaffected and still use their dedicated scopes                                   | `[x]`  |
| T-19-11-04 | Write RSpec request spec: `GET /orders` does not render `Cp` or `Cc` orders (AC-01)                                                                               | `[x]`  |
| T-19-11-05 | Write RSpec request spec: `GET /orders/completed` still renders Completed orders (AC-02)                                                                           | `[x]`  |
| T-19-11-06 | Write RSpec request spec: `GET /orders/cancelled` still renders Cancelled orders (AC-03)                                                                           | `[x]`  |

---

## Summary

| Story | Title | Tasks |
| --- | --- | --- |
| STORY-19-01 | Add Salesperson to Order | 10 |
| STORY-19-02 | Remove Logistic Status from Order | 9 |
| STORY-19-03 | Order Visibility Permission | 7 |
| STORY-19-04 | Barcode Scanner Bulk Action Page | 12 |
| STORY-19-05 | Duplicate Product Action | 8 |
| STORY-19-06 | "Create and New" Button on Product Form | 4 |
| STORY-19-07 | Logistic Company Name Uniqueness | 5 |
| STORY-19-08 | Logistic Company Active Status | 11 |
| STORY-19-09 | Stock Location CRUD & Multi-Select | 15 |
| STORY-19-10 | Stock Person in Stock Detail & List | 7 |
| STORY-19-11 | Filter Completed & Cancelled from All Tab (rename to Active) | 6 |
| **TOTAL** | | **93** |
