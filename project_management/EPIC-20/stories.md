# EPIC-20 — Invoice Module

**Phase:** 20
**Status:** 🟢 Done
**Goal:** A complete Invoice Module allowing staff to create invoices from orders (with customer-grouping), manage invoice status (Draft → Paid / Cancelled), view invoice detail with associated orders, creator/updator info, change history timeline, and image attachments, print A4-formatted professional invoices from both the list and detail pages, and configure the company header information (name, address, tax ID, logo) used on printed invoices via a Company Settings page.

---

## Legend

| Symbol         | Meaning                  |
| -------------- | ------------------------ |
| 🔴 Not Started | Work has not begun       |
| 🟡 In Progress | Actively being worked on |
| 🟢 Completed   | Done and verified        |
| `[x]`          | Task not started         |
| `[~]`          | Task in progress         |
| `[x]`          | Task completed           |

---

## Background & Observed UI State

All observations are taken from `http://localhost:3000` (codebase inspection) on 2026-04-22.

**Existing orders list (`GET /orders`):**
- Tabs: Active, Draft, Paid, Completed, Cancelled
- Columns: Order #, Date, Customer, Salesperson, Status, Grand Total, Actions
- Bulk action bar: multi-select checkboxes + status dropdown + "Update Status" + "Combine Bills"
- Row actions: View, Print (conditional), Edit, Delete
- Header buttons: "Scan Orders", "New Order"

**Existing order show (`GET /orders/:id`):**
- Sections: Order Details card, Order Lines table, Summary panel, Images, Change History (lazy Turbo Frame)
- Header buttons: "Export Invoice", "Edit Order", "Duplicate"
- Change History loaded from `GET /orders/:id/audit_trail` via Turbo Frame
- Images: multi-upload via `order_images` nested resource

**Sidebar (authenticated layout):** Dashboard, Orders, Purchase Orders, Catalog▾, Unit Groups, Bulk Import, User Group, Users, Roles, Permissions, Customers, Logistic Company, Branches, Stock, Stock Locations, Countries — **no Invoice item present**.

**Status badge colours (established pattern):**
- Draft (`Dr`): gray, Paid (`Pd`): blue, Completed (`Cp`): green, Cancelled (`Cc`): red

**Permissions pattern (from `app/models/concerns/permissions.rb`):**
- Four CRUD codenames per resource: `view_X`, `add_X`, `change_X`, `delete_X`

**No invoices table, Invoice model, or Invoice routes exist in the codebase.**

---

## Stories

---

### STORY-20-01 — Invoice Schema, Models & Permissions

**Status:** 🟢 Done
**Description:** Four new database tables (`invoices`, `invoice_orders`, `invoice_audits`, `invoice_images`), four corresponding ActiveRecord models, a `InvoiceNumberGenerator` service, a Pundit `InvoicePolicy`, and four new permission codenames are added. This story creates the entire domain layer; no UI is delivered.

**User Perspective:**
As a developer, I want the Invoice domain layer in place (tables, models, service, policy), so that all subsequent invoice stories have a stable foundation to build on.

**Acceptance Criteria:**

| #     | Given                                                                              | When                                                                                    | Then                                                                                                                                                               |
| ----- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | A new `Invoice` record is created with `invoice_date: Date.today` and valid associations | `Invoice.create!` is called with required fields                                   | A unique `invoice_number` matching `INV-YYYYMMDD###` is generated; `status` defaults to `"Dr"`; `total_amount` defaults to `0.00`                                 |
| AC-02 | Two orders belonging to customer A are added to an invoice via `invoice_orders`   | `invoice.recalculate_total!` is called                                                  | `invoice.total_amount` equals the sum of both orders' `grand_total`                                                                                                |
| AC-03 | An invoice with status `"Cc"` exists; the same `invoice_number` is tried again    | `Invoice.create!` with duplicate `invoice_number`                                      | ActiveRecord raises a uniqueness validation error                                                                                                                   |
| AC-04 | A status value outside `["Dr", "Pd", "Cc"]` is assigned to an invoice            | `invoice.valid?`                                                                        | Returns `false`; `invoice.errors[:status]` is non-empty                                                                                                            |
| AC-05 | An invoice with status `"Pd"` (Paid) is present                                  | `POST /invoices/:id/reopen` is called                                                   | `invoice.status` becomes `"Dr"`; an `InvoiceAudit` of `event_type: "status_change"`, `previous_value: "Pd"`, `new_value: "Dr"` is created; **Paid invoices cannot transition to `"Cc"` — Cancelled is not a valid target from `"Pd"`**; Cancelled invoices cannot transition to any status (enforced by `status_immutable_when_cancelled` model validation) |
| AC-06 | `GET /permissions`                                                                | Page loads                                                                              | `view_invoices`, `add_invoices`, `change_invoices`, `view_invoice_audit` are visible in the permissions catalogue                                                    |
| AC-07 | User without `view_invoices`                                                      | `InvoicePolicy#index?`                                                                  | Returns `false`                                                                                                                                                     |

**Edge Cases:**

- `invoice_number` generation must be collision-safe (loop until unique), resetting the daily sequence per `invoice_date`.
- Deleting an invoice cascades to `invoice_orders`, `invoice_audits`, and `invoice_images` via `dependent: :destroy`.
- An `Order` can appear in `invoice_orders` for at most one non-cancelled invoice at a time (enforced by DB unique partial index on `invoice_orders.order_id WHERE invoices.status != 'Cc'` — or by application-level validation in `InvoicesController#create`).
- `InvoiceImage` uses Active Storage (`has_one_attached :image`) identical to `OrderImage`.

| #          | Task                                                                                                                                                                                                        | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-01-01 | Write migration: create `invoices` table (`invoice_number string unique`, `customer_id bigint FK`, `status string(2) default 'Dr'`, `invoice_date date`, `remark text`, `total_amount decimal(20,2) default 0`, `created_by_id bigint FK users`, `updated_by_id bigint FK users`, timestamps; indexes on `customer_id`, `status`, `invoice_date`, `invoice_number` unique) | `[x]`  |
| T-20-01-02 | Write migration: create `invoice_orders` join table (`invoice_id bigint FK invoices on_delete: :cascade`, `order_id bigint FK orders on_delete: :restrict`; unique index on `[invoice_id, order_id]`; index on `order_id`) | `[x]`  |
| T-20-01-03 | Write migration: create `invoice_audits` table (`invoice_id bigint FK invoices on_delete: :cascade`, `changed_by_id bigint FK users on_delete: :nullify`, `event_type string(20)`, `field_name string(100)`, `previous_value text`, `new_value text`, `changed_at datetime default now()`; indexes on `[invoice_id, changed_at]`) | `[x]`  |
| T-20-01-04 | Write migration: create `invoice_images` table (`invoice_id bigint FK invoices on_delete: :cascade`, `position integer default 0`, timestamps; index on `invoice_id`) | `[x]`  |
| T-20-01-05 | Create `app/models/invoice.rb` — skeleton: `STATUSES = %w[Dr Pd Cc]`; associations (`belongs_to :customer`, `belongs_to :created_by/updated_by class_name: "User" optional: true`, `has_many :invoice_orders dependent: :destroy`, `has_many :orders through: :invoice_orders`, `has_many :invoice_audits dependent: :destroy`, `has_many :invoice_images dependent: :destroy`); validations (`status inclusion`, `invoice_number presence + uniqueness`, `invoice_date presence`); `ransackable_attributes` and `ransackable_associations` | `[x]`  |
| T-20-01-06 | Create `app/models/invoice_order.rb`: `belongs_to :invoice`, `belongs_to :order`; validate uniqueness of `order_id` scoped to active invoices (custom validation: order must not already belong to a non-cancelled invoice) | `[x]`  |
| T-20-01-07 | Create `app/models/invoice_audit.rb`: `EVENT_TYPES = %w[status_change field_update order_added order_removed]`; `belongs_to :invoice`; `belongs_to :changed_by class_name: "User" optional: true`; validates `event_type` inclusion | `[x]`  |
| T-20-01-08 | Create `app/models/invoice_image.rb`: `belongs_to :invoice`; `has_one_attached :image`; `after_create_commit :generate_thumb` (same pattern as `OrderImage`) | `[x]`  |
| T-20-01-09 | Create `app/services/invoice_number_generator.rb`: generates `"INV-#{date.strftime('%Y%m%d')}#{count.to_s.rjust(3,'0')}"`, collision-safe loop (same pattern as `OrderNumberGenerator`) | `[x]`  |
| T-20-01-10 | Create `app/policies/invoice_policy.rb`: `InvoicePolicy` and `InvoicePolicy::Scope`; map CRUD actions to `view_invoices`, `add_invoices`, `change_invoices`; add `cancel?`, `mark_paid?`, `reopen?`, `print?`, `audit?`, `bulk_update_status?` actions | `[x]`  |
| T-20-01-11 | Add `view_invoices add_invoices change_invoices view_invoice_audit` to `Permissions::ALL` in `app/models/concerns/permissions.rb` | `[x]`  |
| T-20-01-12 | Write RSpec model spec for `Invoice`: auto-generates `invoice_number`, defaults status to `Dr`, validates status inclusion, `recalculate_total!` sums order grand_totals (AC-01, AC-02, AC-04) | `[x]`  |
| T-20-01-13 | Write RSpec service spec for `InvoiceNumberGenerator`: daily reset, collision-safe, `INV-YYYYMMDD###` format (AC-01) | `[x]`  |
| T-20-01-14 | Write RSpec policy spec for `InvoicePolicy`: `index?` returns false without `view_invoices` (AC-07), `create?` returns false without `add_invoices`, `audit?` returns false without `view_invoice_audit`, `mark_paid?` returns false without `change_invoices` or when invoice is not Draft, `reopen?` returns false without `change_invoices` or when invoice is not Paid | `[x]`  |
| T-20-01-15 | Add callbacks and methods to `app/models/invoice.rb`: `before_validation :generate_invoice_number on: :create`; `before_create :set_created_by`; `before_save :set_updated_by`; `recalculate_total!` method (sets `total_amount = orders.sum(:grand_total)` and saves) | `[x]`  |
| T-20-01-16 | Write RSpec model spec for `InvoiceOrder`: custom uniqueness validation rejects an `order_id` already on a non-cancelled invoice; allows the same `order_id` when the prior invoice is Cancelled | `[x]`  |
| T-20-01-17 | Write RSpec model spec for `InvoiceAudit`: validates `event_type` inclusion in `EVENT_TYPES`; rejects unknown `event_type` | `[x]`  |
| T-20-01-18 | Write RSpec model spec for `InvoiceImage`: `has_one_attached :image`; `after_create_commit` triggers `generate_thumb` (verify method is called on create) | `[x]`  |

---

### STORY-20-02 — Invoice List Page & Sidebar Navigation

**Status:** 🟢 Done
**Description:** A new `/invoices` section is added to the application with an index page showing all invoices in a table with status tabs (All, Draft, Paid, Cancelled), per-row Print and View actions, multi-select checkboxes for bulk status updates, and an "Invoices" sidebar navigation item.

**User Perspective:**
As a billing staff member, I want to see all invoices on a dedicated list page with status tabs and search, so that I can quickly find and act on any invoice.

**Acceptance Criteria:**

| #     | Given                                                                                              | When                                             | Then                                                                                                                                                             |
| ----- | -------------------------------------------------------------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Authenticated user with `view_invoices`                                                           | `GET /invoices`                                  | Response `200`; page renders with title "Invoices", status tabs (All, Draft, Paid, Cancelled), and a table with columns: INVOICE #, DATE, CUSTOMER, STATUS, TOTAL BILL, ACTIONS |
| AC-02 | User on `GET /invoices`                                                                           | Clicks "Draft" tab                               | Response `200`; `GET /invoices/draft`; table shows only invoices with `status = "Dr"`                                                                            |
| AC-03 | User on `GET /invoices`                                                                           | Clicks "Paid" tab                                | Response `200`; `GET /invoices/paid`; table shows only invoices with `status = "Pd"`                                                                             |
| AC-04 | User on `GET /invoices`                                                                           | Clicks "Cancelled" tab                           | Response `200`; `GET /invoices/cancelled`; table shows only invoices with `status = "Cc"`                                                                        |
| AC-05 | Authenticated user on any page                                                                    | Sidebar renders                                  | An "Invoices" navigation item is visible between "Orders" and "Purchase Orders"; it is only rendered when user has `view_invoices` permission                    |
| AC-06 | Invoices table has rows                                                                           | Page loads                                       | Each row shows: invoice number as a link to `GET /invoices/:id`, invoice_date formatted `DD MMM YYYY`, customer full name, status badge (gray/blue/red), total_amount formatted as currency, and Actions buttons |
| AC-07 | User with `add_invoices` permission on `GET /invoices`                                            | Page loads                                       | A "Create Invoice" button is visible in the page header area, linking to `GET /invoices/new`                                                                     |
| AC-08 | User types a search query in the Ransack search input and submits                                 | `GET /invoices?q[invoice_number_or_customer_first_name_or_customer_last_name_cont]=...` | Response `200`; table shows only matching invoices                                                                           |
| AC-09 | User without `view_invoices`                                                                      | `GET /invoices`                                  | Response `302` redirect to root with flash "Not authorised"                                                                                                      |
| AC-10 | Unauthenticated user                                                                              | `GET /invoices`                                  | Response `302` redirect to `/login`                                                                                                                              |

**Edge Cases:**

- The "All" tab shows Draft + Paid + Cancelled (all statuses) — it is the default tab.
- Pagination (Pagy) must be applied on all tabs.
- The TOTAL BILL column renders the `total_amount` formatted with 2 decimal places and currency symbol consistent with the orders grand total display.
- Status badge colours: Draft = gray, Paid = blue, Cancelled = red (reuse or extract `invoices/status_badge` partial).
- The "Invoices" sidebar item must be hidden for users without `view_invoices` using `policy(Invoice).index?`.

| #          | Task                                                                                                                                                                                                          | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-02-01 | Add `resources :invoices` to `config/routes.rb` with collection routes: `get :draft`, `get :paid`, `get :cancelled`, `post :bulk_update_status`; member routes: `post :cancel`, `post :mark_paid`, `post :reopen`, `get :audit_trail`, `get :print` | `[x]`  |
| T-20-02-02 | Create `app/controllers/invoices_controller.rb`: `before_action :authenticate_user!`; `before_action :authorize_invoice` (Pundit); `index`, `draft`, `paid`, `cancelled` actions with Ransack + Pagy; `policy_scope(Invoice)` applied in all list actions | `[x]`  |
| T-20-02-03 | Create `app/views/invoices/index.html.erb`: page header ("Invoices" title + "Create Invoice" button behind `add_invoices` policy); status tabs (All/Draft/Paid/Cancelled) with active-state highlighting matching orders pattern; Ransack search bar; bulk-action bar (hidden, shown on checkbox selection) with status dropdown + "Update Status" button; data table with INVOICE #, DATE, CUSTOMER, STATUS, TOTAL BILL, ACTIONS columns; Pagy pagination | `[x]`  |
| T-20-02-04 | Create `app/views/invoices/_status_badge.html.erb` partial: maps `Dr`→gray, `Pd`→blue, `Cc`→red using same Tailwind classes as the orders status badge partial | `[x]`  |
| T-20-02-05 | Add per-row bulk-select checkbox (`data-controller="bulk-action"`) to the invoices table, matching the `bulk-action` Stimulus controller pattern already used in `orders/index.html.erb` | `[x]`  |
| T-20-02-06 | Add per-row "View" link (`GET /invoices/:id`) and "Print" link (`GET /invoices/:id/print`, opens in new tab, behind `print?` policy check) to the Actions column | `[x]`  |
| T-20-02-07 | Update sidebar partial `app/views/layouts/_sidebar.html.erb` (or equivalent): add `rb_nav_item` for "Invoices" pointing to `invoices_path`, placed between Orders and Purchase Orders, wrapped in `policy(Invoice).index?` guard | `[x]`  |
| T-20-02-08 | Write RSpec request spec: `GET /invoices` returns `200` for user with `view_invoices` (AC-01) | `[x]`  |
| T-20-02-09 | Write RSpec request spec: `GET /invoices/draft` returns `200` and only Draft invoices (AC-02) | `[x]`  |
| T-20-02-10 | Write RSpec request spec: `GET /invoices` returns `302` for user without `view_invoices` (AC-09) | `[x]`  |
| T-20-02-11 | Write RSpec request spec: `GET /invoices` returns `302` redirect to `/login` for unauthenticated user (AC-10) | `[x]`  |
| T-20-02-12 | Write RSpec request spec: `GET /invoices/paid` returns `200` and only Paid invoices (AC-03) | `[x]`  |
| T-20-02-13 | Write RSpec request spec: `GET /invoices/cancelled` returns `200` and only Cancelled invoices (AC-04) | `[x]`  |
| T-20-02-14 | Write RSpec request spec: `GET /invoices` renders the "Invoices" sidebar nav item for user with `view_invoices`; nav item is absent for user without `view_invoices` (AC-05) | `[x]`  |

---

### STORY-20-03 — Invoice Creation from Orders

**Status:** 🟢 Done
**Description:** A dedicated invoice creation page (`GET /invoices/new`) lists all orders that are not yet associated with an active (non-cancelled) invoice. The user can filter orders by customer (Tom Select typeahead) and date range, select multiple orders, and click "Create Invoice". The system groups selected orders by `customer_id` and creates one invoice per unique customer. The user is redirected to the invoice list after creation.

**User Perspective:**
As a billing staff member, I want to select multiple orders and create invoices from them, so that customers with multiple orders are automatically grouped into a single invoice.

**Acceptance Criteria:**

| #     | Given                                                                                                               | When                                               | Then                                                                                                                                                                                         |
| ----- | ------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | User with `add_invoices` on `GET /invoices/new`                                                                    | Page loads                                         | Response `200`; page renders with: page title "Create Invoice", a customer Tom Select filter, a "From Date" date input, a "To Date" date input, a table listing eligible orders, and a "Create Invoice" button |
| AC-02 | Eligible orders are orders not associated with any non-cancelled invoice                                           | Page loads                                         | Orders previously invoiced (status `Dr` or `Pd`) are **not** listed; orders belonging to cancelled invoices **are** listed                                                                   |
| AC-03 | User selects a customer from the Tom Select filter                                                                 | Filter applied (Stimulus or form submit)           | Table refreshes (or re-renders) showing only orders for the selected customer                                                                                                                |
| AC-04 | User enters a date range ("From Date" and "To Date")                                                              | Filter applied                                     | Table shows only orders whose `running_date` falls within the specified range (inclusive)                                                                                                    |
| AC-05 | User selects 3 orders: 2 for Customer A, 1 for Customer B, then clicks "Create Invoice"                           | `POST /invoices` with `order_ids: [id1, id2, id3]` | Response `302` redirect to `GET /invoices`; 2 invoices created: one for Customer A (linked to orders id1 + id2, `total_amount` = sum of their `grand_total`s), one for Customer B (linked to order id3) |
| AC-06 | User selects 2 orders for the same customer and clicks "Create Invoice"                                           | `POST /invoices`                                   | Response `302`; 1 invoice created with both orders linked; `total_amount` = sum of both orders' `grand_total`s; both orders removed from the eligible list                                  |
| AC-07 | User submits `POST /invoices` with no orders selected                                                             | `POST /invoices` with empty `order_ids`            | Response `422`; flash error "Please select at least one order"                                                                                                                               |
| AC-08 | User submits `POST /invoices` with an `order_id` that already belongs to an active invoice (race condition)       | `POST /invoices`                                   | Response `422`; flash error listing the conflicting order number; no invoices created                                                                                                        |
| AC-09 | User without `add_invoices`                                                                                        | `GET /invoices/new` or `POST /invoices`            | Response `302` redirect with flash "Not authorised"                                                                                                                                          |
| AC-10 | No eligible orders exist (all orders already invoiced)                                                            | `GET /invoices/new` page loads                     | Table renders an empty state message: "No orders available for invoicing"                                                                                                                    |
| AC-11 | User has selected at least one eligible order and clicks "Create Invoice"                                        | Click (before `POST`)                              | A modal dialog opens showing a grouped preview: a row per unique customer listing customer name, number of selected orders, and combined total; a "Confirm" button and a "Back" button are rendered; no `POST` is made yet |
| AC-12 | Preview modal is open and user clicks "Confirm"                                                                   | Click                                              | `POST /invoices` is submitted with the selected `order_ids`; invoices are created as per AC-05/AC-06; modal closes; user is redirected to `GET /invoices` with flash success |
| AC-13 | Preview modal is open and user clicks "Back"                                                                      | Click                                              | Modal closes; user remains on `GET /invoices/new`; previously selected checkboxes remain ticked; no `POST` is made |

**Edge Cases:**

- Eligible orders query: `Order.where.not(id: InvoiceOrder.joins(:invoice).where.not(invoices: { status: 'Cc' }).select(:order_id))` — must exclude orders currently on any Draft or Paid invoice.
- The creation page table columns should mirror the orders list: Order #, Date, Customer, Salesperson, Status, Grand Total — with a leading checkbox column.
- A "Select All" checkbox in the table header selects/deselects all visible rows (reuse `bulk-action` Stimulus controller).
- The customer Tom Select dropdown should list all customers (including soft-deleted ones whose orders may still appear) ordered by `first_name last_name`.
- Each created invoice gets a `created_by` set to `Current.user`.
- `InvoiceAudit` records of type `order_added` are created for each order linked to the new invoice.
- Invoice creation is transactional: if any invoice fails to save, the entire batch is rolled back and a `422` is returned.

| #          | Task                                                                                                                                                                                                                     | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-20-03-01 | Add `get :new` to `resources :invoices` collection if not already implicit; ensure `InvoicesController#new` is accessible and authorised via `InvoicePolicy#create?` | `[x]`  |
| T-20-03-02 | Implement `InvoicesController#new`: loads `@eligible_orders = EligibleOrdersQuery.new(params).call` with Ransack/scope filtering on `customer_id` and `running_date` range; authorise `policy(:invoice).create?`; loads customer list for Tom Select | `[x]`  |
| T-20-03-03 | Create `app/services/eligible_orders_query.rb`: encapsulates the query `Order.where.not(id: InvoiceOrder.joins(:invoice).where.not(invoices: { status: 'Cc' }).select(:order_id))` with optional `customer_id` and date-range filter params | `[x]`  |
| T-20-03-04 | Implement `InvoicesController#create`: validates `order_ids` not empty (AC-07); checks no selected order belongs to an active invoice (AC-08); groups orders by `customer_id`; wraps in `ActiveRecord::Base.transaction`; creates one `Invoice` per customer with linked `InvoiceOrder` records; calls `invoice.recalculate_total!`; creates `InvoiceAudit` (`order_added`) per order; redirects to `invoices_path` with flash success | `[x]`  |
| T-20-03-05 | Create `app/views/invoices/new.html.erb`: page title "Create Invoice"; filter bar with customer Tom Select (`data-controller="tom-select"`, loads `/customers` JSON for typeahead) + "From Date" date input + "To Date" date input + "Filter" button; eligible orders table with select-all checkbox + Order #, Date, Customer, Salesperson, Status, Grand Total columns; "Create Invoice" button (`data-action="click->invoice-preview#open"`, disabled when no rows checked); hidden preview modal (`data-invoice-preview-target="modal"`) with grouped-customer summary table, "Confirm" form submit button, and "Back" button; empty state message when no eligible orders | `[x]`  |
| T-20-03-06 | Wire date-range and customer filters using Ransack or a custom `filter` GET param in `EligibleOrdersQuery`; ensure filter state persists on form re-render after validation error | `[x]`  |
| T-20-03-07 | Write RSpec request spec: `POST /invoices` with 2 orders same customer creates 1 invoice linked to both orders (AC-06) | `[x]`  |
| T-20-03-08 | Write RSpec request spec: `POST /invoices` with orders from 2 different customers creates 2 invoices (AC-05) | `[x]`  |
| T-20-03-09 | Write RSpec request spec: `POST /invoices` with empty `order_ids` returns `422` with error flash (AC-07) | `[x]`  |
| T-20-03-10 | Write RSpec request spec: `POST /invoices` with an already-invoiced order returns `422` (AC-08) | `[x]`  |
| T-20-03-11 | Write RSpec request spec: `GET /invoices/new` returns `302` for user without `add_invoices` (AC-09) | `[x]`  |
| T-20-03-12 | Write RSpec service spec for `EligibleOrdersQuery`: excludes orders on active invoices; includes orders on cancelled invoices; applies customer filter; applies date range filter | `[x]`  |
| T-20-03-13 | Create `app/javascript/controllers/invoice_preview_controller.js`: Stimulus controller with `open(event)` action — prevents form submission, reads selected checkbox values + row data attributes (`customer-id`, `customer-name`, `grand-total`), groups by customer, renders grouped summary rows into `modalTarget`, shows modal; `confirm()` action submits the form; `close()` action hides the modal | `[x]`  |

---

### STORY-20-04 — Invoice Show Page (Detail, Associated Orders, Images & Change History)

**Status:** 🟢 Done
**Description:** The invoice show page (`GET /invoices/:id`) displays the full invoice detail: header with Invoice number, status badge, customer, invoice date, remark, creator, and updator; a table of all associated orders; a multi-image upload section; and a lazy-loaded Change History timeline matching the Order show page pattern.

**User Perspective:**
As a billing staff member, I want to view full invoice detail including all associated orders, who created and updated it, and the complete change history, so that I have a clear audit trail for each invoice.

**Acceptance Criteria:**

| #     | Given                                                                                                        | When                                          | Then                                                                                                                                                                               |
| ----- | ------------------------------------------------------------------------------------------------------------ | --------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | User with `view_invoices` on `GET /invoices/:id`                                                            | Page loads                                    | Response `200`; Invoice Details card shows: Invoice #, invoice_date (formatted `DD MMM YYYY`), Customer full name, Status badge, Remark (or "—" if blank), Created by (full name), Last updated by (full name) |
| AC-02 | Invoice has 3 associated orders                                                                             | Page loads                                    | An "Associated Orders" section renders a table with columns: ORDER #, DATE, CUSTOMER, STATUS, GRAND TOTAL; each row links to `GET /orders/:id`                                     |
| AC-03 | Invoice has `invoice_images` attached                                                                       | Page loads                                    | Images section renders thumbnails of all attached images                                                                                                                           |
| AC-04 | User with `change_invoices` on the show page                                                                | Page loads                                    | An image upload form is visible (file input + "Upload" button) identical in behaviour to the order image upload                                                                     |
| AC-05 | User on `GET /invoices/:id`                                                                                 | Page loads                                    | A lazy-loaded Turbo Frame `invoice_audit_trail` fires `GET /invoices/:id/audit_trail`; the timeline renders audit events (status changes, remark edits, order additions/removals) in chronological order (newest first) |
| AC-06 | User with `change_invoices` and invoice `status = "Dr"`                                                    | Page loads                                    | A "Cancel Invoice" button, a "Mark as Paid" button, and an "Edit Remark" button (or inline edit) are visible                                                                       |
| AC-07 | User with `change_invoices` and invoice `status = "Pd"` (Paid)                                             | Page loads                                    | A "Reopen to Draft" button is visible; no "Cancel Invoice", "Mark as Paid", or "Edit Remark" buttons are rendered                                                                   |
| AC-08 | User without `view_invoices`                                                                                | `GET /invoices/:id`                           | Response `302` redirect with flash "Not authorised"                                                                                                                                |
| AC-09 | Invoice id does not exist                                                                                   | `GET /invoices/:id`                           | Response `404`                                                                                                                                                                     |
| AC-10 | User with `change_invoices` on `GET /invoices/:id`                                                         | Clicks "Print Invoice"                        | Browser navigates to `GET /invoices/:id/print` (see STORY-20-06)                                                                                                                   |
| AC-11 | Invoice `status = "Cc"` (Cancelled)                                                                        | Page loads                                    | No "Cancel Invoice", "Mark as Paid", "Reopen to Draft", or "Edit Remark" buttons are rendered; invoice is fully read-only; "Print Invoice" button remains visible                   |

**Edge Cases:**

- If `created_by` user is deactivated, their full name must still render (do not hide it).
- The "Associated Orders" table must show the orders' own status badges (not the invoice status).
- Change History is only rendered when user has `view_invoice_audit` permission (dedicated permission — normal users with only `view_invoices` will not see the audit timeline).
- The `audit_trail` action renders a partial `_audit_trail.html.erb` with a vertical timeline of `InvoiceAudit` records ordered by `changed_at DESC`.
- "Print Invoice" button is always visible to users with `view_invoices` (no separate `print_invoices` permission required).

| #          | Task                                                                                                                                                                                               | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-04-01 | Add `InvoicesController#show` action: loads `@invoice = policy_scope(Invoice).find(params[:id])`; authorises `policy(@invoice).show?`; loads `@invoice_images = @invoice.invoice_images.order(:position)`; loads `@associated_orders = @invoice.orders.includes(:customer)` | `[x]`  |
| T-20-04-02 | Add `InvoicesController#audit_trail` action: loads `@invoice`; loads `@audits = @invoice.invoice_audits.order(changed_at: :desc)`; renders `invoices/audit_trail` partial in a Turbo Frame | `[x]`  |
| T-20-04-03 | Create `app/views/invoices/show.html.erb`: back-link to `invoices_path`; page heading with invoice number; header buttons: "Print Invoice" (links `GET /invoices/:id/print` target `_blank`), "Mark as Paid" (`POST /invoices/:id/mark_paid`, behind `policy(@invoice).mark_paid?`), "Cancel Invoice" (`POST /invoices/:id/cancel`, behind `policy(@invoice).cancel?`), "Reopen to Draft" (`POST /invoices/:id/reopen`, behind `policy(@invoice).reopen?`), "Edit Remark" (links `GET /invoices/:id/edit`, behind `change_invoices` + Draft guard); Invoice Details card (Invoice #, Date, Customer, Status badge, Remark, Created by, Last updated by); Associated Orders table; Images section; Change History Turbo Frame | `[x]`  |
| T-20-04-04 | Create `app/views/invoices/_audit_trail.html.erb`: vertical timeline listing `@audits` — each entry shows `changed_at`, `changed_by` full name (or "System"), `event_type` human-readable label, and `field_name` / `previous_value` → `new_value` when applicable | `[x]`  |
| T-20-04-05 | Create nested resource `resources :invoice_images, only: %i[create destroy]` under `resources :invoices` in `config/routes.rb` | `[x]`  |
| T-20-04-06 | Create `app/controllers/invoice_images_controller.rb`: `create` (authorises `change_invoices`, attaches image via Active Storage, creates `InvoiceImage` record, responds with Turbo Stream appending thumbnail); `destroy` (authorises, destroys record + blob) | `[x]`  |
| T-20-04-07 | Create `app/views/invoice_images/_invoice_image.html.erb` partial: thumbnail + remove button (matching `order_images/_order_image.html.erb` pattern) | `[x]`  |
| T-20-04-08 | Write RSpec request spec: `GET /invoices/:id` returns `200` and renders invoice details, creator name, associated orders section (AC-01, AC-02) | `[x]`  |
| T-20-04-09 | Write RSpec request spec: `GET /invoices/:id/audit_trail` returns `200` with audit timeline (AC-05) | `[x]`  |
| T-20-04-10 | Write RSpec request spec: `GET /invoices/:id` returns `302` for user without `view_invoices` (AC-08) | `[x]`  |
| T-20-04-11 | Write RSpec request spec: `GET /invoices/99999` returns `404` (AC-09) | `[x]`  |
| T-20-04-12 | Write RSpec request spec: `POST /invoices/:id/invoice_images` with a valid image file creates an `InvoiceImage` record (AC-04) | `[x]`  |
| T-20-04-13 | Write RSpec request spec: `GET /invoices/:id` for a Draft invoice renders "Mark as Paid" and "Cancel Invoice" buttons for user with `change_invoices`; not rendered for Paid or Cancelled invoice (AC-06, AC-07, AC-11) | `[x]`  |
| T-20-04-14 | Write RSpec request spec: `GET /invoices/:id` for a Paid invoice renders "Reopen to Draft" button; not rendered for Draft or Cancelled invoice (AC-07) | `[x]`  |

---

### STORY-20-05 — Invoice Status Management (Cancel, Bulk Update & Remark Edit)

**Status:** 🟢 Done
**Description:** Invoices can be cancelled (Draft status only) or marked as Paid (Draft status only) via dedicated per-invoice actions. A Paid invoice can be reopened back to Draft by a user with `change_invoices`. Cancelled invoices are terminal and cannot transition to any other status. Cancelled invoices automatically release their associated orders back to the eligible pool. Multiple invoices can be bulk-updated to a new status (except Cancelled) via the list page. An edit action allows updating the invoice remark. All status changes are recorded in `InvoiceAudit`.

**User Perspective:**
As a billing staff member, I want to cancel a Draft invoice, mark it as Paid, or reopen a Paid invoice to Draft, and update statuses in bulk, so that I can manage the full invoice lifecycle accurately.

**Acceptance Criteria:**

| #     | Given                                                                                                              | When                                                 | Then                                                                                                                                                                                                  |
| ----- | ------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | User with `change_invoices` on an invoice with `status = "Dr"`                                                    | `POST /invoices/:id/cancel`                          | Response `302` redirect to `invoices_path`; `invoice.status` is `"Cc"`; an `InvoiceAudit` record of `event_type: "status_change"` is created with `previous_value: "Dr"`, `new_value: "Cc"`          |
| AC-02 | Invoice is cancelled (AC-01); user visits `GET /invoices/new`                                                     | Page loads                                           | Orders previously linked to the now-cancelled invoice appear in the eligible orders table                                                                                                             |
| AC-03 | User attempts `POST /invoices/:id/cancel` on an invoice with `status = "Pd"` (Paid)                              | Request                                              | Response `422`; flash error "Only Draft invoices can be cancelled"; invoice status unchanged                                                                                                           |
| AC-04 | User attempts `POST /invoices/:id/cancel` on an invoice with `status = "Cc"` (already Cancelled)                 | Request                                              | Response `422`; flash error "Invoice is already cancelled"; invoice status unchanged                                                                                                                   |
| AC-05 | User selects 3 invoices on the list page and selects "Paid" in the bulk status dropdown, then clicks "Update Status" | `POST /invoices/bulk_update_status` with `ids: [...]`, `status: "Pd"` | Response `302` redirect to `invoices_path`; all 3 invoices have `status = "Pd"`; flash success "3 invoices updated"; the bulk status dropdown offers only `"Paid"` as a valid target — no other status appears in the dropdown |
| AC-06 | User attempts bulk update to `status = "Cc"` (Cancelled) via the bulk update form                                | `POST /invoices/bulk_update_status` with `status: "Cc"` | Response `422`; flash error "Use the Cancel Invoice action to cancel individual invoices"; no statuses changed                                                                                         |
| AC-07 | User with `change_invoices` submits `PATCH /invoices/:id` with updated `remark`                                  | Request                                              | Response `302` redirect to `GET /invoices/:id`; `invoice.remark` updated; an `InvoiceAudit` record of `event_type: "field_update"`, `field_name: "remark"` is created                                |
| AC-08 | User without `change_invoices`                                                                                    | `POST /invoices/:id/cancel`                          | Response `302` redirect with flash "Not authorised"                                                                                                                                                   |
| AC-09 | User without `change_invoices`                                                                                    | `POST /invoices/bulk_update_status`                  | Response `302` redirect with flash "Not authorised"                                                                                                                                                   |
| AC-10 | User with `change_invoices` on an invoice with `status = "Dr"`                                                    | `POST /invoices/:id/mark_paid`                       | Response `302` redirect to `GET /invoices/:id`; `invoice.status` is `"Pd"`; an `InvoiceAudit` record of `event_type: "status_change"`, `previous_value: "Dr"`, `new_value: "Pd"` is created            |
| AC-11 | User attempts `POST /invoices/:id/mark_paid` on an invoice with `status != "Dr"`                                 | Request                                              | Response `422`; flash error "Only Draft invoices can be marked as Paid"; invoice status unchanged                                                                                                    |
| AC-12 | User with `change_invoices` on an invoice with `status = "Pd"`                                                    | `POST /invoices/:id/reopen`                          | Response `302` redirect to `GET /invoices/:id`; `invoice.status` is `"Dr"`; an `InvoiceAudit` record of `event_type: "status_change"`, `previous_value: "Pd"`, `new_value: "Dr"` is created            |
| AC-13 | User attempts `POST /invoices/:id/reopen` on an invoice with `status != "Pd"`                                    | Request                                              | Response `422`; flash error "Only Paid invoices can be reopened to Draft"; invoice status unchanged                                                                                                  |

**Edge Cases:**

- Bulk cancel via `bulk_update_status` is intentionally blocked (AC-06); cancellation must be done individually per invoice to preserve the audit trail clarity.
- The bulk status dropdown renders only `"Paid"` as a selectable option — reopening to Draft and cancelling must be done individually via the invoice show page.
- If `bulk_update_status` is submitted with an empty `ids` array, return `422` with flash "Please select at least one invoice".
- `InvoiceAudit` entries are created **per affected invoice** for all status changes — including bulk updates — capturing `changed_by: Current.user`.
- The `status_immutable_when_cancelled` guard prevents a Cancelled invoice from being changed to any other status (model-level validation). Paid invoices do **not** have a model-level immutability guard — `reopen` is permitted via the dedicated action.
- The `PATCH /invoices/:id` edit action only permits `remark` in the strong parameters; no other fields can be updated through this action (status changes go through dedicated actions).

| #          | Task                                                                                                                                                                                                             | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-05-01 | Add `status_immutable_when_cancelled` private validation to `app/models/invoice.rb`: raises error when `status_was == "Cc" && status_changed? && status != "Cc"` | `[x]`  |
| T-20-05-02 | Implement `InvoicesController#cancel` action: authorises `policy(@invoice).cancel?`; validates `@invoice.status == "Dr"` (AC-03/AC-04); calls `@invoice.update!(status: "Cc")`; creates `InvoiceAudit` for status change; redirects to `invoices_path` with flash | `[x]`  |
| T-20-05-03 | Implement `InvoicesController#bulk_update_status` action: authorises `policy(:invoice).bulk_update_status?`; rejects empty `ids` (422); rejects `status = "Cc"` (422, AC-06); updates all matching invoices; creates `InvoiceAudit` record per affected invoice; redirects with flash count | `[x]`  |
| T-20-05-04 | Implement `InvoicesController#edit` and `InvoicesController#update` actions: `edit` renders `app/views/invoices/edit.html.erb`; `update` permits only `remark` param; creates `InvoiceAudit` on remark change; redirects to `GET /invoices/:id` | `[x]`  |
| T-20-05-05 | Create `app/views/invoices/edit.html.erb`: simple form with a single "Remark" textarea field + "Save" and "Cancel" buttons | `[x]`  |
| T-20-05-06 | Create `app/services/invoice_audit_service.rb`: records `InvoiceAudit` entries for field updates and status changes; mirrors `OrderAuditService` pattern | `[x]`  |
| T-20-05-07 | Wire `after_update_commit :record_field_audits` callback in `Invoice` model calling `InvoiceAuditService` (AC-07 audit creation) | `[x]`  |
| T-20-05-08 | Add `cancel?`, `mark_paid?`, `reopen?`, and `bulk_update_status?` to `InvoicePolicy` (`cancel?` requires `change_invoices` + invoice is Draft; `mark_paid?` requires `change_invoices` + invoice is Draft; `reopen?` requires `change_invoices` + invoice is Paid; `bulk_update_status?` requires `change_invoices`) | `[x]`  |
| T-20-05-09 | Implement `InvoicesController#mark_paid` action: authorises `policy(@invoice).mark_paid?`; validates `@invoice.status == "Dr"` (AC-11); calls `@invoice.update!(status: "Pd")`; creates `InvoiceAudit` for status change; redirects to `invoice_path(@invoice)` with flash | `[x]`  |
| T-20-05-10 | Implement `InvoicesController#reopen` action: authorises `policy(@invoice).reopen?`; validates `@invoice.status == "Pd"` (AC-13); calls `@invoice.update!(status: "Dr")`; creates `InvoiceAudit` for status change; redirects to `invoice_path(@invoice)` with flash | `[x]`  |
| T-20-05-11 | Write RSpec request spec: `POST /invoices/:id/cancel` on Draft invoice sets status to `"Cc"` and creates audit record (AC-01) | `[x]`  |
| T-20-05-12 | Write RSpec request spec: `POST /invoices/:id/cancel` on Paid invoice returns `422` (AC-03) | `[x]`  |
| T-20-05-13 | Write RSpec request spec: `POST /invoices/bulk_update_status` updates 3 invoices to `"Pd"` and creates audit records per invoice (AC-05) | `[x]`  |
| T-20-05-14 | Write RSpec request spec: `POST /invoices/bulk_update_status` with `status: "Cc"` returns `422` (AC-06) | `[x]`  |
| T-20-05-15 | Write RSpec request spec: `PATCH /invoices/:id` with valid `remark` redirects to show page and creates audit record (AC-07) | `[x]`  |
| T-20-05-16 | Write RSpec request spec: cancelled invoice's orders re-appear in `GET /invoices/new` (AC-02) — verify via `EligibleOrdersQuery` | `[x]`  |
| T-20-05-17 | Write RSpec request spec: `POST /invoices/:id/mark_paid` on Draft invoice sets status to `"Pd"` and creates audit record (AC-10) | `[x]`  |
| T-20-05-18 | Write RSpec request spec: `POST /invoices/:id/mark_paid` on non-Draft invoice returns `422` (AC-11) | `[x]`  |
| T-20-05-19 | Write RSpec request spec: `POST /invoices/:id/reopen` on Paid invoice sets status to `"Dr"` and creates audit record (AC-12) | `[x]`  |
| T-20-05-20 | Write RSpec request spec: `POST /invoices/:id/reopen` on non-Paid invoice returns `422` (AC-13) | `[x]`  |
| T-20-05-21 | Write RSpec request spec: `POST /invoices/bulk_update_status` with empty `ids` array returns `422` with flash "Please select at least one invoice" | `[x]`  |

---

### STORY-20-06 — Print Invoice (A4 Layout)

**Status:** 🟢 Done
**Description:** A dedicated print view (`GET /invoices/:id/print`) renders an A4-formatted, printable HTML page containing the invoice header (company name, invoice number, date), customer information, a table of all associated order lines grouped by order, subtotals per order, a grand total, and the invoice remark. A "Print Invoice" button on the invoice list page (per-row) and on the invoice show page opens this view in a new browser tab. The view uses a print-specific CSS layout and excludes the application navigation.

**User Perspective:**
As a billing staff member, I want to print a professional A4 invoice for a customer, so that I can include it in shipments or send it as a formal billing document.

**Acceptance Criteria:**

| #     | Given                                                                                                                 | When                                                    | Then                                                                                                                                                                             |
| ----- | --------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | User with `view_invoices` on `GET /invoices/:id/print`                                                               | Page loads                                              | Response `200`; page renders in a print-optimised layout (no sidebar, no header nav); `<title>` is "Invoice INV-YYYYMMDD###"                                                     |
| AC-02 | Print page renders; `CompanySetting.current` has `company_name: "PSK Baby"`, `company_address: "123 Main St"`, `company_tax_id: "0105560123456"` | Page loads | Company header section shows: the stored `company_name`, `company_address`, `company_telephone`, and `company_tax_id` from `CompanySetting.current`; a "INVOICE" label; invoice number; invoice date formatted `DD/MM/YYYY` |
| AC-03 | Print page renders                                                                                                   | Page loads                                              | Customer section shows: customer full name, address, telephone                                                                                                                   |
| AC-04 | Invoice has 2 associated orders, each with 3 order lines                                                            | Page loads                                              | The line-items table groups rows by order (order number shown as a sub-header); each row shows: product name, unit, quantity, unit price, line total; a subtotal row per order    |
| AC-05 | Print page renders                                                                                                   | Page loads                                              | A totals section below the line-items table shows: Grand Total (= `invoice.total_amount` formatted as currency); Invoice Remark (if present)                                      |
| AC-06 | Print page renders                                                                                                   | Page loads                                              | Invoice status badge is visible (e.g., "DRAFT", "PAID", "CANCELLED") using an appropriate print-safe style                                                                       |
| AC-07 | User clicks "Print Invoice" button on `GET /invoices/:id` show page                                                 | Click                                                   | Browser navigates to `GET /invoices/:id/print` in a new tab (`target="_blank"`)                                                                                                  |
| AC-08 | User clicks "Print" in the Actions column of the invoice list (`GET /invoices`)                                     | Click                                                   | Browser navigates to `GET /invoices/:id/print` in a new tab                                                                                                                      |
| AC-09 | User triggers browser print dialog on `GET /invoices/:id/print`                                                    | `Ctrl+P` / `Cmd+P`                                      | The printed output fits within an A4 page width; no UI chrome (sidebar, navigation, buttons) is printed; all table columns are visible without horizontal clipping               |
| AC-10 | User without `view_invoices`                                                                                         | `GET /invoices/:id/print`                               | Response `302` redirect with flash "Not authorised"                                                                                                                              |

**Edge Cases:**

- The print view uses a dedicated layout (`app/views/layouts/print.html.erb`) that includes only base Tailwind reset and a `print.css` stylesheet (`@page { size: A4; margin: 1.5cm; }`) — it excludes the sidebar and top navigation.
- If an order line's `discount_price > 0`, a "Discount" column is shown; otherwise it is hidden to avoid blank columns.
- If an associated order has `has_vat: true`, a VAT subtotal row is shown per order beneath the line items.
- All monetary values must be formatted consistently (e.g., `number_to_currency(value, unit: "฿", separator: ".", delimiter: ",")` or the existing helper used in orders).
- The print URL does not require a separate permission codename — `view_invoices` is sufficient (same as order print pattern where `export?` is mapped to `view_orders`).
- The print page should include a `<button onclick="window.print()">Print</button>` visible on screen but hidden via `@media print` CSS.

| #          | Task                                                                                                                                                                                                                      | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-06-01 | Implement `InvoicesController#print` action: loads `@invoice` with eager-loaded associations (`customer`, `orders { order_lines { product } }`); loads `@company_setting = CompanySetting.current`; authorises `policy(@invoice).show?`; renders `invoices/print` with `layout: "print"` | `[x]`  |
| T-20-06-02 | Create `app/views/layouts/print.html.erb`: minimal HTML skeleton that loads only Tailwind base CSS + a `print.css` link; no sidebar, no navigation, no flash messages | `[x]`  |
| T-20-06-03 | Create `app/assets/stylesheets/print.css` (or Tailwind `@layer` block): `@page { size: A4 portrait; margin: 1.5cm; }`, `@media print { .no-print { display: none !important; } }`, table borders, font sizes appropriate for A4 | `[x]`  |
| T-20-06-04 | Create `app/views/invoices/print.html.erb`: company header row (`@company_setting.company_name` + `@company_setting.company_address` + `@company_setting.company_telephone` + `@company_setting.company_tax_id` + Active Storage logo if attached + "INVOICE" label + invoice number + date); customer info block (name, address, telephone); status badge; line-items table grouped by order (order number sub-header, product rows, per-order subtotal row, VAT row if applicable); totals section (Grand Total, Remark if present); print button (`onclick="window.print()"`, hidden on print) | `[x]`  |
| T-20-06-05 | Add `data-testid` attributes to all key elements in `print.html.erb`: `data-testid="invoice-number"`, `data-testid="customer-name"`, `data-testid="line-items-table"`, `data-testid="grand-total"` | `[x]`  |
| T-20-06-06 | Add "Print" link to `app/views/invoices/index.html.erb` Actions column: `link_to "Print", print_invoice_path(invoice), target: "_blank", class: "..."` (visible to all users with `view_invoices`) | `[x]`  |
| T-20-06-07 | Add "Print Invoice" button to `app/views/invoices/show.html.erb` header button row: `link_to "Print Invoice", print_invoice_path(@invoice), target: "_blank", class: "..."` | `[x]`  |
| T-20-06-08 | Write RSpec request spec: `GET /invoices/:id/print` returns `200` and renders invoice number, customer name, company name from `CompanySetting.current`, and line-items table (AC-01, AC-02, AC-03, AC-04) | `[x]`  |
| T-20-06-09 | Write RSpec request spec: `GET /invoices/:id/print` returns `302` for user without `view_invoices` (AC-10) | `[x]`  |
| T-20-06-10 | Write RSpec request spec: `GET /invoices` renders a "Print" link in each row's Actions column for user with `view_invoices` (AC-08) | `[x]`  |
| T-20-06-11 | Write RSpec request spec: `GET /invoices/:id` renders a "Print Invoice" button in the page header for user with `view_invoices` (AC-07) | `[x]`  |

---

### STORY-20-07 — Company Settings

**Status:** 🟢 Done
**Description:** A new `company_settings` single-row table stores the company name, address, telephone, tax ID, email, website, and an optional logo used in the print invoice header. An authenticated admin can update these settings via `GET /company_setting/edit`. All authenticated users can read `CompanySetting.current`; only users with the `change_company_settings` permission can update it.

**User Perspective:**
As an admin, I want to configure the company name, address, tax ID, and logo in a settings page, so that printed invoices show the correct company header without requiring a code deployment.

**Acceptance Criteria:**

| #     | Given                                                                                              | When                                                              | Then                                                                                                                                                                    |
| ----- | -------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Admin with `change_company_settings` on `GET /company_setting/edit`                               | Page loads                                                        | Response `200`; form renders with fields: Company Name (text input, required), Address (textarea), Telephone (text input), Tax ID (text input), Email (text input), Website (text input), Logo (file input showing current logo thumbnail if present) |
| AC-02 | Admin fills in all fields and uploads a PNG logo, then submits                                    | `PATCH /company_setting`                                          | Response `302` redirect to `GET /company_setting/edit`; flash success "Company settings saved"; `CompanySetting.current` reflects all updated values; logo is attached via Active Storage |
| AC-03 | Admin submits with a blank Company Name                                                           | `PATCH /company_setting`                                          | Response `422`; form re-renders with validation error "Company name can't be blank"; no record updated                                                                  |
| AC-04 | `CompanySetting.current` is called when no record exists in the database                          | Method call                                                       | Returns an unsaved `CompanySetting` instance with `company_name` defaulting to `"PSK ERP"` and all other fields `nil` or blank; does **not** raise                       |
| AC-05 | Admin uploads a logo, saves, then returns to `GET /company_setting/edit`                          | Page loads                                                        | The current logo thumbnail is displayed above the file input; a "Remove Logo" checkbox is visible                                                                       |
| AC-06 | Admin checks "Remove Logo" and saves                                                              | `PATCH /company_setting` with `remove_logo: "1"`                  | Response `302`; the Active Storage logo attachment is purged; `CompanySetting.current.logo.attached?` returns `false`                                                    |
| AC-07 | User without `change_company_settings`                                                            | `GET /company_setting/edit`                                       | Response `302` redirect with flash "Not authorised"                                                                                                                     |
| AC-08 | `GET /invoices/:id/print` is requested                                                            | Page loads                                                        | Company header reflects the values from `CompanySetting.current` (AC-02 values appear on the printed page)                                                              |

**Edge Cases:**

- `CompanySetting` uses `find_or_initialize_by(id: 1)` so there is always at most one record. The table is seeded on first access, not via a mandatory migration seed.
- The logo upload accepts only image MIME types (`image/png`, `image/jpeg`, `image/gif`); other file types return a validation error "Logo must be an image file".
- Logo is stored via Active Storage (same configuration as `order_images`); a compressed thumbnail variant is generated after attach.
- The `resource :company_setting` singular route means URLs are `/company_setting/edit` (no `:id` segment).
- No delete action is needed — the single record is always present (or auto-initialised).
- `change_company_settings` is a single codename (no separate `view_company_settings` — all authenticated users can read the setting in the print layout).
- A sidebar "Company Settings" item is added at the bottom of the sidebar, visible only to users with `change_company_settings`.

| #          | Task                                                                                                                                                                                                                         | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-07-01 | Write migration: create `company_settings` table (`company_name string not null default 'PSK ERP'`, `company_address text`, `company_telephone string(20)`, `company_tax_id string`, `company_email string`, `company_website string`, timestamps) | `[x]`  |
| T-20-07-02 | Create `app/models/company_setting.rb`: `validates :company_name, presence: true`; `has_one_attached :logo`; `validate :logo_must_be_image`; `def self.current = find_or_initialize_by(id: 1)` class method; `def self.current! = find_or_create_by!(id: 1) { |s| s.company_name = "PSK ERP" }` for write-safe access | `[x]`  |
| T-20-07-03 | Create `app/policies/company_setting_policy.rb`: `CompanySettingPolicy`; `edit?` and `update?` require `change_company_settings`; `show?` returns `true` for all authenticated users | `[x]`  |
| T-20-07-04 | Add `change_company_settings` to `Permissions::ALL` in `app/models/concerns/permissions.rb` | `[x]`  |
| T-20-07-05 | Add singular resource route to `config/routes.rb`: `resource :company_setting, only: %i[edit update]` | `[x]`  |
| T-20-07-06 | Create `app/controllers/company_settings_controller.rb`: `before_action :authenticate_user!`; `edit` action loads `@company_setting = CompanySetting.current!`; authorises `policy(@company_setting).edit?`; `update` action calls `@company_setting.update(company_setting_params)`, handles `remove_logo` param, redirects with flash | `[x]`  |
| T-20-07-07 | Create `app/views/company_settings/edit.html.erb`: page title "Company Settings"; form with fields: Company Name (required), Address, Telephone, Tax ID, Email, Website; logo upload section (current thumbnail if attached + "Remove Logo" checkbox + file input accepting image/*); Save button; data-testid attributes on all inputs | `[x]`  |
| T-20-07-08 | Update `InvoicesController#print` to use `CompanySetting.current!` instead of a hardcoded string (already captured in T-20-06-01 — ensure `@company_setting` is assigned before rendering the print template) | `[x]`  |
| T-20-07-09 | Update sidebar partial `app/views/layouts/_sidebar.html.erb` (or equivalent): add "Company Settings" nav item pointing to `edit_company_setting_path`, visible only when `policy(CompanySetting.new).edit?` | `[x]`  |
| T-20-07-10 | Write RSpec model spec for `CompanySetting`: `current` returns initialised instance when table is empty; `current!` creates default record; `logo_must_be_image` rejects non-image MIME type (AC-04, logo validation) | `[x]`  |
| T-20-07-11 | Write RSpec request spec: `PATCH /company_setting` with valid params updates record and redirects with flash (AC-02) | `[x]`  |
| T-20-07-12 | Write RSpec request spec: `PATCH /company_setting` with blank `company_name` returns `422` (AC-03) | `[x]`  |
| T-20-07-13 | Write RSpec request spec: `GET /company_setting/edit` returns `302` for user without `change_company_settings` (AC-07) | `[x]`  |
| T-20-07-14 | Write RSpec request spec: `GET /invoices/:id/print` renders the `company_name` from `CompanySetting.current` (AC-08) | `[x]`  |
| T-20-07-15 | Write RSpec policy spec for `CompanySettingPolicy`: `edit?` returns false without `change_company_settings` (AC-07); `show?` returns true for any authenticated user | `[x]`  |

---

### STORY-20-08 — Edit Invoice Orders (Add / Remove Orders on Draft Invoice)

**Status:** 🟢 Done
**Description:** A user with `change_invoices` can add eligible orders (same customer, not already on an active invoice) to an existing Draft invoice, or remove individual orders from it. Both actions recalculate `total_amount` and record `InvoiceAudit` entries. Removed orders are returned to the eligible pool on the creation page. Only Draft invoices may be edited; Paid and Cancelled invoices are immutable.

**User Perspective:**
As a billing staff member, I want to add or remove individual orders on a Draft invoice, so that I can correct the invoice before it is marked as Paid without having to cancel and recreate it.

**Acceptance Criteria:**

| #     | Given                                                                                                                      | When                                                                  | Then                                                                                                                                                                                                         |
| ----- | -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | User with `change_invoices` on `GET /invoices/:id` where invoice is Draft                                                 | Page loads                                                            | The "Associated Orders" section renders each order row with a "Remove" button; an "Add Orders" button is visible in the section header                                                                        |
| AC-02 | User clicks "Remove" on an order row of a Draft invoice                                                                   | `DELETE /invoices/:id/invoice_orders/:order_id`                       | Response `302` redirect to `GET /invoices/:id`; the `InvoiceOrder` record is destroyed; `invoice.recalculate_total!` is called; an `InvoiceAudit` of `event_type: "order_removed"` is created; the removed order re-appears in `GET /invoices/new` eligible orders table |
| AC-03 | Draft invoice has only 1 associated order; user clicks "Remove" on it                                                     | `DELETE /invoices/:id/invoice_orders/:order_id`                       | Response `302` redirect to `GET /invoices/:id`; flash error "An invoice must have at least one order"; order is not removed                                                                                   |
| AC-04 | User clicks "Add Orders" on a Draft invoice show page                                                                     | Click                                                                 | Browser navigates to `GET /invoices/:id/add_orders` — a page listing eligible orders for the same customer (orders not on any active invoice, belonging to `invoice.customer`)                                |
| AC-05 | User selects one or more eligible orders on `GET /invoices/:id/add_orders` and submits                                    | `POST /invoices/:id/invoice_orders` with `order_ids: [...]`           | Response `302` redirect to `GET /invoices/:id`; `InvoiceOrder` records created; `invoice.recalculate_total!` called; `InvoiceAudit` records of `event_type: "order_added"` created per added order; flash success |
| AC-06 | User attempts to add an order that already belongs to another active invoice                                               | `POST /invoices/:id/invoice_orders`                                   | Response `422`; flash error listing the conflicting order number; no records created                                                                                                                         |
| AC-07 | User attempts to add an order belonging to a different customer than the invoice's customer                                | `POST /invoices/:id/invoice_orders`                                   | Response `422`; flash error "Selected orders must belong to the same customer as this invoice"; no records created                                                                                            |
| AC-08 | User attempts `DELETE /invoices/:id/invoice_orders/:order_id` on a Paid or Cancelled invoice                              | Request                                                               | Response `422`; flash error "Cannot modify orders on a non-Draft invoice"                                                                                                                                    |
| AC-09 | User without `change_invoices`                                                                                             | `DELETE /invoices/:id/invoice_orders/:order_id`                       | Response `302` redirect with flash "Not authorised"                                                                                                                                                          |

**Edge Cases:**

- Only orders belonging to `invoice.customer` are shown on the `add_orders` page — cross-customer addition is blocked at both the UI and controller level.
- After any add or remove operation, `invoice.recalculate_total!` must be called to keep `total_amount` consistent.
- Removing the last order on an invoice is blocked (AC-03) — an invoice must always retain at least one order.
- "Remove" and "Add Orders" UI elements are hidden for Paid and Cancelled invoices (no `change_invoices` guard alone is sufficient — also check `invoice.status == "Dr"`).
- `invoice_orders` destroy uses `DELETE /invoices/:id/invoice_orders/:order_id` — the `:order_id` param is the `order.id`, not the `invoice_order.id`.
- The last-order guard (AC-03) returns `302` redirect with flash (business guard); the non-Draft guard (AC-08) returns `422` (hard permission rejection) — this asymmetry is intentional.

| #          | Task                                                                                                                                                                                                                                  | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-08-01 | Add nested routes under `resources :invoices`: `resources :invoice_orders, only: %i[create destroy]` and `member get :add_orders` | `[x]`  |
| T-20-08-02 | Create `app/controllers/invoice_orders_controller.rb`: `before_action :authenticate_user!`; `create` action — authorises `change_invoices`, validates invoice is Draft, validates customer match (AC-07), validates no active conflict (AC-06), creates `InvoiceOrder` records, calls `recalculate_total!`, creates `InvoiceAudit` per order, redirects with flash; `destroy` action — authorises `change_invoices`, validates invoice is Draft (AC-08), validates at least 1 order remains (AC-03), destroys record, calls `recalculate_total!`, creates `InvoiceAudit order_removed`, redirects with flash | `[x]`  |
| T-20-08-03 | Implement `InvoicesController#add_orders` action: loads `@invoice`; authorises `policy(@invoice).change?`; builds `@eligible_orders` scoped to `invoice.customer` using `EligibleOrdersQuery` with `customer_id: @invoice.customer_id` filter | `[x]`  |
| T-20-08-04 | Create `app/views/invoices/add_orders.html.erb`: page title "Add Orders to Invoice #\#{invoice_number}"; customer name displayed as read-only context; table of eligible orders (same columns as `new.html.erb`) with checkboxes; "Add Selected Orders" submit button; "Cancel" back-link to `invoice_path(@invoice)` | `[x]`  |
| T-20-08-05 | Update `app/views/invoices/show.html.erb` Associated Orders section: add "Add Orders" button (links to `add_orders_invoice_path(@invoice)`, behind Draft guard); add "Remove" button per order row (`DELETE /invoices/:id/invoice_orders/:order_id` via `data-turbo-method="delete"` + `data-turbo-confirm`, behind Draft guard) | `[x]`  |
| T-20-08-06 | Write RSpec request spec: `DELETE /invoices/:id/invoice_orders/:order_id` on a Draft invoice destroys the record, recalculates total, creates audit record (AC-02) | `[x]`  |
| T-20-08-07 | Write RSpec request spec: `DELETE /invoices/:id/invoice_orders/:order_id` when only 1 order remains returns `302` redirect to `GET /invoices/:id` with flash error "An invoice must have at least one order"; order record is not destroyed (AC-03) | `[x]`  |
| T-20-08-08 | Write RSpec request spec: `POST /invoices/:id/invoice_orders` with eligible same-customer orders creates records and recalculates total (AC-05) | `[x]`  |
| T-20-08-09 | Write RSpec request spec: `POST /invoices/:id/invoice_orders` with an already-invoiced order returns `422` (AC-06) | `[x]`  |
| T-20-08-10 | Write RSpec request spec: `POST /invoices/:id/invoice_orders` with wrong-customer order returns `422` (AC-07) | `[x]`  |
| T-20-08-11 | Write RSpec request spec: `DELETE /invoices/:id/invoice_orders/:order_id` on a Paid invoice returns `422` (AC-08) | `[x]`  |
| T-20-08-12 | Write RSpec request spec: `DELETE /invoices/:id/invoice_orders/:order_id` without `change_invoices` returns `302` with "Not authorised" (AC-09) | `[x]`  |

---

### STORY-20-09 — Orders Module Integration

**Status:** 🟢 Done
**Description:** Two changes are made to the existing Orders module to integrate it with the new Invoice Module: (1) the "Export Invoice" button is removed from the order show page since invoicing is now handled by the Invoice Module; (2) the "Combine Bills" bulk action on the orders list is updated to redirect users to `GET /invoices/new` pre-populated with the selected order IDs, replacing its previous behaviour.

**User Perspective:**
As a billing staff member, I want the "Combine Bills" action on the orders list to take me directly to the Invoice creation page with my selected orders pre-filled, so that I don't have to re-select them manually.

**Acceptance Criteria:**

| #     | Given                                                                                                         | When                                                                                      | Then                                                                                                                                                                           |
| ----- | ------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | User on `GET /orders/:id` show page                                                                           | Page loads                                                                                | No "Export Invoice" button is rendered anywhere on the page                                                                                                                    |
| AC-02 | User selects 3 orders on `GET /orders` and clicks "Combine Bills"                                             | Click                                                                                     | Browser navigates to `GET /invoices/new?order_ids[]=id1&order_ids[]=id2&order_ids[]=id3`; the 3 corresponding order rows are pre-checked in the eligible orders table           |
| AC-03 | User navigates to `GET /invoices/new?order_ids[]=id1` where `id1` is already on an active invoice             | Page loads                                                                                | The pre-selected order is shown in the table but rendered as disabled/greyed with a tooltip "Already invoiced"; it cannot be checked                                            |
| AC-04 | User navigates to `GET /invoices/new?order_ids[]=id1` where `id1` does not belong to the current user's accessible orders | Page loads                                                                     | The order does not appear in the eligible orders table; no error is shown                                                                                                                      |
| AC-05 | User on `GET /orders` with 0 orders selected clicks "Combine Bills"                                           | Click                                                                                     | Flash error "Please select at least one order" is shown; no navigation occurs                                                                                                  |

**Edge Cases:**

- The "Combine Bills" button on the orders list passes `order_ids[]` as query params to `GET /invoices/new`; `InvoicesController#new` reads these params and pre-checks the matching rows via a `data-selected="true"` attribute on each eligible order row, consumed by the existing bulk-action Stimulus controller.
- Pre-selected orders that are ineligible (already invoiced) are shown greyed-out but not removed from the table, allowing the user to see why they cannot be selected.
- The "Export Invoice" button removal must also cover any conditional rendering guards that reference it (e.g., `policy(@order).export?` checks can be removed if no longer needed).
- The "Combine Bills" button should only appear and function when at least one order checkbox is selected (existing bulk-action Stimulus controller behaviour).

| #          | Task                                                                                                                                                                                                                             | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-20-09-01 | Remove the "Export Invoice" button from `app/views/orders/show.html.erb` (and any associated `policy(@order).export?` guard if it is no longer referenced elsewhere) | `[x]`  |
| T-20-09-02 | Update the "Combine Bills" button in `app/views/orders/index.html.erb`: change the action so that clicking it constructs a `GET /invoices/new` URL with the currently selected `order_ids[]` as query params and navigates there (using `data-action` on the bulk-action Stimulus controller or a new `combine-bills` action) | `[x]`  |
| T-20-09-03 | Update `InvoicesController#new` and `EligibleOrdersQuery` to accept an optional `order_ids` param array: marks matching eligible order rows with `data-preselected="true"`; marks ineligible (already-invoiced) pre-selected rows with `data-disabled="true"` and a tooltip | `[x]`  |
| T-20-09-04 | Update `app/views/invoices/new.html.erb` order row partial: read `data-preselected` to auto-check the checkbox; read `data-disabled` to render the row greyed-out with checkbox disabled and tooltip "Already invoiced" | `[x]`  |
| T-20-09-05 | Write RSpec request spec: `GET /orders/:id` does not render any link or button with text "Export Invoice" (AC-01) | `[x]`  |
| T-20-09-06 | Write RSpec request spec: `GET /invoices/new?order_ids[]=id1&order_ids[]=id2` with eligible orders renders those rows with `data-preselected="true"` (AC-02) | `[x]`  |
| T-20-09-07 | Write RSpec request spec: `GET /invoices/new?order_ids[]=id1` where `id1` is already invoiced renders the row with `data-disabled="true"` (AC-03) | `[x]`  |
| T-20-09-08 | Write RSpec request spec: `GET /invoices/new?order_ids[]=id1` where `id1` is inaccessible to the current user does not render that order in the eligible orders table (AC-04) | `[x]`  |

