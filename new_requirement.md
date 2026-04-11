# PSK ERP — New System Requirements & Implementation Plan

> This document defines the architecture, UI design, data models, and phased build plan for the **new PSK ERP system** — a Ruby on Rails rebuild of the wholesale order management platform. All functional behaviour from `requirements.md` is preserved; this document adds implementation decisions, UI structure, and a step-by-step delivery plan.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Technology Stack](#2-technology-stack)
3. [UI/UX Design System](#3-uiux-design-system)
4. [Application Layout](#4-application-layout)
5. [Domain Model & Database Schema](#5-domain-model--database-schema)
6. [Module Specifications](#6-module-specifications)
7. [API Design](#7-api-design)
8. [Security Architecture](#8-security-architecture)
9. [Implementation Plan](#9-implementation-plan)
10. [Testing Strategy](#10-testing-strategy)

---

## 1. System Overview

**PSK ERP** is a wholesale order management platform for PSK Baby. The new system is a full reimplementation in Ruby on Rails, retaining 100% of existing business logic while adopting modern tooling, a clean UI, and improved security posture.

### Goals of the Rebuild

| Goal | Detail |
|---|---|
| **Modern stack** | Rails 8, Hotwire (Turbo + Stimulus), PostgreSQL |
| **Clean UI** | Railsblocks UI framework; consistent sidebar + header layout |
| **Security** | Fix all ⚠️ issues identified in original; JWT authentication; signed export URLs |
| **Maintainability** | Conventional Rails structure, RSpec test suite, well-named abstractions |
| **Same functionality** | All features from requirements.md are reproduced exactly |

### Core Capabilities (unchanged)

- Product catalogue management with parent/child product hierarchies
- Real-time stock tracking per branch
- Sales order lifecycle management (Draft → Paid → Completed / Cancelled)
- Customer relationship management
- Logistics company assignment per order and customer
- Sales and customer reports exported as Excel spreadsheets
- Role-based access control including field-level `cost` visibility
- JWT-based authentication API

---

## 2. Technology Stack

| Layer | Technology | Notes |
|---|---|---|
| **Language** | Ruby 3.3+ | |
| **Framework** | Ruby on Rails 8.x | API + Web (hybrid) |
| **UI Framework** | Railsblocks | Component-based; Tailwind CSS under the hood |
| **Frontend JS** | Hotwire (Turbo + Stimulus) | Partial page updates without full-page reloads |
| **Database** | PostgreSQL 16+ | |
| **Authentication** | Devise + JWT (devise-jwt gem) | Short-lived access tokens + refresh tokens |
| **Authorization** | Pundit | Policy objects per model; replaces raw permission checks |
| **Background Jobs** | Sidekiq + Redis | Async Excel generation, image compression |
| **File Storage** | Active Storage + Local / S3 | Image uploads with thumbnail variants |
| **Excel Generation** | caxlsx (axlsx-rails) | Report and invoice generation |
| **Excel Import** | roo gem | Bulk product import from .xlsx |
| **Pagination** | Pagy | Lightweight; custom response shape |
| **Search** | Ransack | Model-level search + filtering |
| **Testing** | RSpec + FactoryBot + Shoulda Matchers | |
| **Code Quality** | RuboCop (rubocop-rails, rubocop-rspec) | |
| **API Docs** | rswag | OpenAPI schema auto-generated from specs |

---

## 3. UI/UX Design System

### 3.1 Railsblocks

Railsblocks provides ready-made, Tailwind-based UI components (cards, tables, forms, badges, modals, alerts). All views use Railsblocks components for consistency.

Key components used:
- `rb_sidebar` / `rb_nav_item` — sidebar navigation
- `rb_header` — top header bar with user menu
- `rb_table` — paginated data tables
- `rb_card` — content panels
- `rb_badge` — status labels (order status, logistic status)
- `rb_modal` — confirmation dialogs
- `rb_form` — form wrappers with validation error display
- `rb_alert` — flash message display

### 3.2 Colour Palette & Status Badges

| Status | Badge Colour |
|---|---|
| Draft | Gray |
| Paid | Blue |
| Completed | Green |
| Cancelled | Red |
| Wait to Send | Yellow |
| Sent | Green |
| Handpick | Purple |
| To Warehouse | Orange |

---

## 4. Application Layout

### 4.1 Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│  HEADER                                                  │
│  [Logo / Brand]          [User Name ▾]  [Logout]        │
├───────────────┬─────────────────────────────────────────┤
│   SIDEBAR     │   MAIN CONTENT AREA                     │
│               │                                         │
│ · Dashboard   │   <turbo-frame id="main-content">       │
│ · Order       │     Page-specific content here          │
│ · Catalog ▾   │   </turbo-frame>                        │
│   · Product   │                                         │
│   · Product   │                                         │
│     Class     │                                         │
│   · Product   │                                         │
│     Category  │                                         │
│   · Supplier  │                                         │
│   · Brand     │                                         │
│ · User Group  │                                         │
│ · User        │                                         │
│ · Customer    │                                         │
│ · Logistic    │                                         │
│   Company     │                                         │
└───────────────┴─────────────────────────────────────────┘
```

### 4.2 Sidebar Menu

```
Dashboard
Order
Catalog (collapsible)
  ├── Product
  ├── Product Class
  ├── Product Category
  ├── Supplier (Vendor)
  └── Brand
User Group
User
Customer
Logistic Company
```

**Behaviour:**
- Sidebar is always visible on desktop (≥ 1024px).
- On mobile, sidebar collapses to an icon-only rail; a hamburger button expands the full sidebar as an overlay.
- Active menu items are highlighted.
- The Catalog group expands/collapses via Stimulus controller; state is persisted in `localStorage`.
- Each menu item is wrapped in a permission check — items the user cannot access are hidden.

### 4.3 Header

- Left: Application logo / name ("PSK ERP").
- Right: Logged-in user's full name with a dropdown → "My Profile", "Logout".
- Flash messages (success/error/warning) appear below the header as dismissable alerts rendered via Turbo Stream.

### 4.4 Page Layout Conventions

Every content page follows:

1. **Page header row** — title on the left, primary action button (e.g. "New Order") on the right.
2. **Filter/search bar** — inline search input + optional filter dropdowns.
3. **Data table** — Railsblocks `rb_table` with sortable columns, pagination, and row-level action buttons (Edit, Delete).
4. **Detail/form panel** — rendered inside a `turbo_frame_tag` for inline updates without full page reload.

---

## 5. Domain Model & Database Schema

### 5.1 Base Concerns (Mixins)

```ruby
# app/models/concerns/timestamped.rb
# Adds: created_at, updated_at (standard Rails timestamps)
# Default scope: order(created_at: :desc)

# app/models/concerns/soft_deletable.rb
# Adds: deleted_at:datetime
# Default scope: where(deleted_at: nil)
# Instance method: soft_delete!, restore!, hard_delete!(hard: true)
# Scopes: .active, .deleted, .with_deleted

# app/models/concerns/image_compressible.rb
# After save: generate thumb variant via Active Storage (quality: 20)
# Naming convention: thumb_{original_filename}
```

### 5.2 Full Schema (all tables)

#### `users` (Devise)
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `email` | string (unique) | Devise default |
| `username` | string (unique) | Login identifier |
| `encrypted_password` | string | Devise |
| `is_active` | boolean | Default true; deactivated users cannot log in |
| `created_at` / `updated_at` | datetime | |

#### `profiles`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `user_id` | bigint FK → users | unique |
| `role_id` | bigint FK → roles | Nullable |
| `first_name` | string | |
| `last_name` | string | |
| `address` | text | |
| `remark` | text | |
| `telephone` | string(255) | |

#### `roles`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `name` | string | |
| `group_id` | bigint FK → groups (via Devise/CanCan or manual) | |
| `permissions` | string[] | PostgreSQL array of codenames |

#### `vendors`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `name` | string (unique) | |
| `initial_name` | string (unique) | Auto-generated if blank |
| `description` | text | |
| `address` | text | |
| `remark` | text | |
| `telephone` | string | |
| `created_at` / `updated_at` | datetime | |

#### `brands`
| Column | Type |
|---|---|
| `id` | bigint PK |
| `name` | string |
| `description` | text |
| `remark` | text |
| `created_at` / `updated_at` | datetime |

#### `product_classes`
| Column | Type |
|---|---|
| `id` | bigint PK |
| `name` | string |
| `created_at` / `updated_at` | datetime |

#### `product_categories`
| Column | Type |
|---|---|
| `id` | bigint PK |
| `name` | string |
| `created_at` / `updated_at` | datetime |

#### `attributes`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `name` | string | |
| `product_class_id` | bigint FK → product_classes | |
| Unique index on (name, product_class_id) | | |

#### `products`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `sku` | string (unique) | Auto-generated |
| `product_type` | string(2) | `Sa`, `Pr`, `Ch` |
| `barcode` | string | Auto-generated |
| `name` | string | |
| `description` | text | English |
| `description_th` | text | Thai |
| `unit` | string | |
| `price` | decimal(20,2) | |
| `cost` | decimal(20,2) | Permission-controlled |
| `remark` | text | |
| `brand_id` | bigint FK → brands | |
| `product_class_id` | bigint FK → product_classes | |
| `vendor_id` | bigint FK → vendors | |
| `parent_id` | bigint FK → products | Self-referential; nil for non-Child |
| `enable_stock` | boolean | Default false |
| `deleted_at` | datetime | Soft delete |
| `created_at` / `updated_at` | datetime | |

#### `product_category_products` (join table)
| Column | Type |
|---|---|
| `product_id` | bigint FK |
| `product_category_id` | bigint FK |

#### `product_attributes`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `product_id` | bigint FK → products | |
| `attribute_id` | bigint FK → attributes | |
| `value` | string | |
| Unique index on (product_id, attribute_id) | | |

#### `branches`
| Column | Type |
|---|---|
| `id` | bigint PK |
| `name` | string (unique) |

#### `product_stocks`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `branch_id` | bigint FK → branches | |
| `product_id` | bigint FK → products | |
| `amount` | decimal(12,2) | Default 0 |
| `holding_amount` | decimal(12,2) | Default 0 |
| Unique index on (branch_id, product_id) | | |

#### `product_stock_transactions`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `product_stock_id` | bigint FK → product_stocks | |
| `transaction_type` | string(2) | `IB`, `OB` |
| `amount` | decimal(12,2) | |
| `related_object_type` | string | Polymorphic |
| `related_object_id` | bigint | Polymorphic |
| `reason` | string(255) | |
| `recal_checkpoint` | decimal(12,2) | Default 0 |
| `created_at` / `updated_at` | datetime | |

#### `countries`
| Column | Type | Notes |
|---|---|---|
| `iso_3166_1_a2` | string(2) PK | Natural PK |
| `iso_3166_1_a3` | string(3) | |
| `iso_3166_1_numeric` | string(3) | |
| `printable_name` | string(255) | |
| `name` | string(255) | |

#### `logistic_companies`
| Column | Type |
|---|---|
| `id` | bigint PK |
| `name` | string |
| `address` | text |
| `remark` | text |
| `telephone` | string(255) |
| `created_at` / `updated_at` | datetime |

#### `customers`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `first_name` | string | |
| `last_name` | string | Nullable |
| `address` | text | |
| `remark` | text | |
| `telephone` | string(255) | |
| `country_id` | string(2) FK → countries | Nullable |
| `logistic_company_id` | bigint FK → logistic_companies | |
| `deleted_at` | datetime | Soft delete |
| `created_at` / `updated_at` | datetime | |

#### `orders`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `order_number` | string (unique) | Auto-generated `YYYYMMDD###` |
| `logistic_company_id` | bigint FK → logistic_companies | `on_delete: :nullify` (fixed from original) |
| `customer_id` | bigint FK → customers | `on_delete: :cascade` |
| `telephone` | string(20) | |
| `address` | text | |
| `has_vat` | boolean | Default false |
| `is_included_vat` | boolean | Default false |
| `total_price` | decimal(20,2) | Auto-calculated |
| `discount_price` | decimal(20,2) | Default 0 |
| `is_discount_percentage` | boolean | Default false |
| `discount_percentage` | decimal(20,2) | Default 0 |
| `vat_price` | decimal(20,2) | Auto-calculated |
| `grand_total` | decimal(20,2) | Auto-calculated |
| `remark` | text | |
| `internal_note` | text | |
| `status` | string(2) | `Dr`, `Pd`, `Cp`, `Cc` |
| `running_date` | date | Defaults to today |
| `is_withholding_tax` | boolean | Default true |
| `withholding_tax` | decimal(20,2) | Default 0 |
| `logistic_status` | string(3) | `WTS`, `ST`, `HP`, `TWH` |
| `created_by_id` | bigint FK → users | |
| `updated_by_id` | bigint FK → users | |
| `created_at` / `updated_at` | datetime | |

#### `order_lines`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `order_id` | bigint FK → orders | |
| `product_id` | bigint FK → products | `on_delete: :restrict` |
| `unit` | string(2) | `Dz`, `Pc`, `Pa`, `Se`, `Ct` |
| `quantity` | decimal(8,2) | |
| `unit_price` | decimal(20,2) | |
| `discount_price` | decimal(20,2) | Default 0 |
| `total_price` | decimal(20,2) | |
| `description` | text | |
| `remark` | text | |
| `idx` | integer | Sort index |
| `created_at` / `updated_at` | datetime | |

#### `order_images`
| Column | Type |
|---|---|
| `id` | bigint PK |
| `order_id` | bigint FK → orders |
| (image via Active Storage) | |

#### `product_images`
| Column | Type |
|---|---|
| `id` | bigint PK |
| `product_id` | bigint FK → products |
| (image + thumb via Active Storage) | |

#### `uploads`
| Column | Type | Notes |
|---|---|---|
| `id` | bigint PK | |
| `file` (Active Storage) | | Stored at `uploads/YYYY/MM/DD/` |
| `created_at` / `updated_at` | datetime | |

---

## 6. Module Specifications

### 6.1 Authentication Module

**Implementation:** Devise + devise-jwt

- Login → `POST /api/v1/auth/sign_in` returns `{ access_token, refresh_token }` in the response body.
- Logout → `DELETE /api/v1/auth/sign_out` (token blocklisted via JTIMatcher).
- Refresh → `POST /api/v1/auth/refresh` using the refresh token.
- Verify → `POST /api/v1/auth/verify`.
- All other endpoints require a valid `Authorization: Bearer <token>` header.
- Inactive users (`is_active = false`) are rejected with `403 Forbidden`.

**Web UI:** Devise standard login form at `/login`, styled with Railsblocks. No registration page (admin creates users).

### 6.2 Authorization Module

**Implementation:** Pundit policy objects

- One `Policy` class per model: `OrderPolicy`, `ProductPolicy`, etc.
- Policies translate HTTP action → permission codename → check against `current_user.profile.role.permissions`.
- `ProductPolicy#show?` also enforces `can_view_cost`: if user lacks `can_view_cost`, the serializer omits `cost`.
- `OrderPolicy#report?` enforces `see_sale_graph`.
- `ApplicationController` calls `authorize @resource` and `policy_scope(Resource)` for every action.

### 6.3 Dashboard

**Route:** `GET /`

Displays an aggregated overview using Turbo Frames for live refresh:

| Widget | Data |
|---|---|
| Total Orders Today | Count of all orders with today's `running_date` |
| Pending Draft Orders | Count of Draft orders |
| Total Revenue (This Month) | Sum of `grand_total` for Completed orders this month |
| Recent Orders | Table of last 10 orders |
| Sales Graph | Monthly bar chart (uses Chartkick + Groupdate) |

### 6.4 User Management Module

**Web Routes (`/users`):**
- `GET /users` — list with search
- `GET /users/new` — new user form
- `POST /users` — create
- `GET /users/:id/edit` — edit form
- `PATCH /users/:id` — update
- `POST /users/:id/deactivate`
- `POST /users/:id/activate`
- `POST /users/force_password/:id` — force password reset

**API routes** mirror web routes under `/api/v1/users/`.

**Profile:** `GET/PUT /api/v1/users/profile`.

### 6.5 Role & Permission Module

**Web Routes (`/roles`, `/groups`, `/permissions`):**
- Full CRUD for roles and groups.
- Permissions list is read-only (seeded from Rails permissions).

**Implementation notes:**
- `Role` stores `permissions` as a PostgreSQL string array column.
- A Pundit concern reads `current_user.profile.role.permissions` to check any codename.

### 6.6 Product Catalog Module

#### Vendor (`/vendors`)
- Full CRUD with Railsblocks table.
- POST `/vendors/initialize_names` — batch-generate `initial_name` for vendors missing one.
- Model callback: `before_save :auto_set_initial_name`.

#### Brand (`/brands`)
- Full CRUD.

#### Product Class (`/product_classes`)
- Full CRUD.

#### Product Category (`/product_categories`)
- Full CRUD + unpaginated JSON endpoint `GET /api/v1/catalogs/list_product_categories`.

#### Attribute (`/attributes`)
- Full CRUD scoped to a product class.

#### Product (`/products`)
- List shows Standalone + Parent types only (paginated via Pagy).
- Child products shown as nested rows inside their parent's detail view.
- Edit form for child products uses its own `PUT /child_products/:id` route.
- SKU and barcode auto-generated in `before_validation :auto_generate_identifiers`.
- Duplicate name check in model validation (scope: non-Child products).
- Last price lookup: `GET /api/v1/catalogs/products/:id/last_price/:customer_id`.
- Advanced search form with Ransack, covering all fields in §5.6.
- Bulk import via the File Upload module (see §6.11).

#### Product Image (`/product_images`)
- Full CRUD; thumbnail auto-generated via Active Storage variant on upload.

### 6.7 Stock Management Module

#### Branch (`/branches`)
- Simple CRUD; typically only one record in production.

#### ProductStock (`/stocks`)
- List with product + branch info.
- Deposit / Withdraw via custom actions with stock transaction ledger.
- `recalculate_checkpoint` action replays transactions from last snapshot.
- `GET /stocks/:id/transactions` returns paginated ledger entries.
- Auto-create stock record on first access (`find_or_create_by!`).

### 6.8 Customer Module

**Web Routes (`/customers`):**
- Full CRUD with soft delete.
- Default manager excludes soft-deleted; admin scopes restore them when needed.
- Search by name via `POST /api/v1/customers/filter`.

### 6.9 Logistic Company Module

**Web Routes (`/logistic_companies`):**
- Full CRUD.
- Filter by name via `POST /api/v1/logistic_companies/filter`.

### 6.10 Order Module

#### Order List Views
- `/orders` — all orders
- `/orders?status=Dr` — draft
- `/orders?status=Pd` — paid
- `/orders?status=Cp` — completed
- `/orders?status=Cc` — cancelled
- Status tabs rendered at the top of the orders list using Turbo Frames for instant switching.

#### Order Detail / Edit
- Nested order lines editable inline using Stimulus controllers.
- Line creation/deletion triggers Turbo Stream update of the grand total summary.
- Grand total auto-calculated server-side on every line change (see §9.2 of requirements.md).

#### Order Number Generation
- Service object `OrderNumberGenerator#call(running_date)` implements the collision-safe loop.

#### Grand Total Calculation
- Service object `GrandTotalCalculator#call(order)` runs the full 7-step formula.
- Called via `after_save` on `OrderLine` (create/update/destroy).

#### Order Status Badges
- Status displayed as Railsblocks `rb_badge` with appropriate colour.

#### Bulk Status Update
- Checkbox selection on list + top action bar → `PATCH /api/v1/orders/bulk_update_status`.

#### Excel Export
- `GET /orders/:id/export` — **requires authentication** (fixed from original).
- Alternatively, a signed time-limited token is issued server-side and used in a short-lived download URL.
- Generated by `OrderExcelService#build(order)` using caxlsx.

#### Combine Bills
- `POST /orders/combine_bills` — generates a combined billing `.xlsx` for multiple orders.

### 6.11 File Upload / Bulk Import Module

- `POST /uploads` — receives an `.xlsx` file.
- After upload, triggers `BulkProductImportJob` (Sidekiq) which:
  1. Parses sheets using the `roo` gem.
  2. Maps sheet name → ProductClass.
  3. Upserts Vendor, Brand, Category, Attribute records.
  4. Creates/updates Product and ProductAttribute records.
- Import results (success/failure counts) stored and returned via Turbo Stream notification.

### 6.12 Reporting Module

All report actions gate behind `see_sale_graph` Pundit policy.

| Report | Endpoint | Output |
|---|---|---|
| Sales Graph | `POST /api/v1/orders/report_order` | JSON (year/month aggregates per status) |
| Customer Report | `POST /api/v1/orders/customer_report` | `.xlsx` download |
| Sales Report | `POST /api/v1/orders/sales_report` | `.xlsx` download |

Reports generated synchronously for small datasets; optionally async via Sidekiq for large date ranges.

### 6.13 Country Module

- Seeded from ISO 3166-1 data file (`db/seeds/countries.rb`).
- `GET /api/v1/countries` — public, no authentication required.

---

## 7. API Design

### 7.1 Versioning
All API routes under `/api/v1/`.

### 7.2 Pagination
Pagy with default page size of 20. Clients pass `page` and `page_size` params.

Response envelope:
```json
{
  "count": 150,
  "next": "/api/v1/orders?page=3",
  "previous": "/api/v1/orders?page=1",
  "results": [...]
}
```

### 7.3 Search & Filtering
- Ransack predicates via `?q[name_cont]=foo`.
- Simple `search` param supported as alias for common text search.

### 7.4 Error Responses

| Scenario | HTTP Status | Body |
|---|---|---|
| Validation failure | 400 | `{ "errors": { "field": ["message"] } }` |
| Not found | 404 | `{ "error": "Not Found" }` |
| Forbidden | 403 | `{ "error": "Forbidden" }` |
| Protected relation conflict | 409 | `{ "error": "Cannot delete: record is referenced" }` |

### 7.5 API Documentation
- rswag gem generates OpenAPI 3.0 spec from RSpec request specs.
- Swagger UI at `/api-docs`.

---

## 8. Security Architecture

### 8.1 Authentication Security
- JWT access tokens expire after **15 minutes**; refresh tokens expire after **7 days**.
- JTI (JWT ID) tracked in database; logout invalidates the token immediately.
- Inactive users rejected during token decode.

### 8.2 Authorization
- Every controller action calls `authorize` (Pundit) — missing call raises `Pundit::AuthorizationNotPerformedError` caught by `after_action :verify_authorized`.
- `cost` field on products excluded from serializer unless user has `can_view_cost`.

### 8.3 Export Endpoint Security (Fixed)
- Original: no authentication on order export.
- **New:** export requires valid Bearer token OR a signed URL generated with `Rails.application.message_verifier(:export)` valid for 10 minutes.

### 8.4 Logistic Company Delete Behaviour (Fixed)
- Original: `on_delete: :cascade` on nullable FK — deleting a logistic company deleted all its orders.
- **New:** `on_delete: :nullify` — orders remain; `logistic_company` is set to null.

### 8.5 HTTP Status Codes (Fixed)
- Protected relation DELETE: `409 Conflict` (not `406`).

### 8.6 Input Validation
- All model validations enforced at Active Record level.
- Numeric inputs coerced and validated (prices, quantities must be ≥ 0).
- File uploads: permitted MIME types checked server-side.

### 8.7 CSRF
- Standard Rails CSRF protection for HTML forms.
- API routes exempt (JWT stateless); SameSite cookie policy enforced.

---

## 9. Implementation Plan

The project is divided into **9 phases**. Each phase has clear deliverables and acceptance criteria. Phases should be completed in order; later phases depend on earlier ones.

---

### Phase 1 — Project Bootstrap & Infrastructure
**Goal:** A working Rails app skeleton with all dependencies installed, database connected, and base layout rendering.

**Steps:**
1. `rails new psk-erp --database=postgresql --skip-test` (using RSpec instead).
2. Add gems to `Gemfile`:
   - `devise`, `devise-jwt`
   - `pundit`
   - `pagy`
   - `ransack`
   - `railsblocks` (or equivalent Tailwind component gem)
   - `caxlsx`, `caxlsx-rails`
   - `roo`
   - `sidekiq`
   - `redis`
   - `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `faker`
   - `rubocop-rails`, `rubocop-rspec`
   - `rswag`
   - `chartkick`, `groupdate`
3. Run `bundle install`.
4. Configure PostgreSQL in `database.yml`; run `rails db:create`.
5. Set up `.env` / credentials for JWT secret, Redis URL, DB credentials.
6. Configure Sidekiq (`config/sidekiq.yml`; mount at `/sidekiq` behind admin auth).
7. Configure Active Storage (`rails active_storage:install`).
8. Set up Tailwind CSS (via `tailwindcss-rails`).
9. Install Railsblocks: follow gem setup docs, configure in `application.rb`.
10. Create base `ApplicationLayout` with:
    - `_header.html.erb` partial
    - `_sidebar.html.erb` partial with the full menu structure
    - Main content area wrapped in `turbo_frame_tag "main_content"`
11. Add flash message support via `_flash.html.erb` + Stimulus dismiss controller.
12. RuboCop baseline: `bundle exec rubocop --auto-gen-config`.
13. RSpec setup: `rails generate rspec:install`; configure FactoryBot and Shoulda Matchers.

**Acceptance criteria:** `rails server` starts, the layout renders with empty sidebar, no errors.

---

### Phase 2 — Authentication & User Management
**Goal:** Users can log in; admins can manage users and assign roles.

**Steps:**
1. `rails generate devise:install`; configure Devise for User model.
2. Add `jti` column and configure `devise-jwt` with JTIMatcher strategy.
3. Add `is_active` boolean to `users`; override Devise `active_for_authentication?`.
4. Generate `Profile` model with FK to `User`; create `1:1` association.
5. Generate `Role` model with `permissions` string array column (PostgreSQL).
6. Add `role_id` FK to `profiles`.
7. Write Pundit `ApplicationPolicy` base class.
8. Implement `UsersController` (CRUD + activate/deactivate + force_password).
9. Write `ProfilesController` (show/update own profile).
10. Build User list view with Railsblocks table and search (Ransack).
11. Build User form view (new/edit) with Railsblocks form.
12. Build Role CRUD (`RolesController`, `GroupsController`, `PermissionsController`).
13. Add sidebar auth guard: hide menu items user cannot access.
14. Seed one admin user in `db/seeds.rb`.
15. Write RSpec model specs for User, Profile, Role.
16. Write RSpec request specs for auth endpoints.

**Acceptance criteria:** Admin can log in, create users, assign roles, and the correct menu items appear per role.

---

### Phase 3 — Country, Logistic Company & Customer Modules
**Goal:** Reference data and customer management fully functional.

**Steps:**
1. Generate `Country` model with natural primary key (`iso_3166_1_a2`). No timestamps.
2. Seed country data from ISO 3166-1 CSV/YAML into `db/seeds/countries.rb`.
3. Add public `GET /api/v1/countries` endpoint (no auth).
4. Generate `LogisticCompany` model + CRUD controller + views.
5. Add `POST /api/v1/logistic_companies/filter` (search by name).
6. Generate `Customer` model with `SoftDeletable` concern.
7. Write `Customer#get_fullname` instance method.
8. Add `customers` default scope excluding `deleted_at IS NOT NULL`.
9. Implement `CustomersController` (CRUD + soft delete).
10. Add `POST /api/v1/customers/filter` search endpoint.
11. Build Customer list + form views with Railsblocks.
12. Write model + request specs for all three modules.

**Acceptance criteria:** Customers, logistic companies, and countries are manageable; soft delete hides customers from list.

---

### Phase 4 — Product Catalog Module
**Goal:** Full product catalogue including vendor, brand, class, category, attribute, and product CRUD.

**Steps:**
1. Generate models: `Vendor`, `Brand`, `ProductClass`, `ProductCategory`, `Attribute`, `ProductAttribute`, `Product`.
2. Set up all associations (see §5 of requirements.md):
   - `Product belongs_to :vendor, :brand, :product_class`
   - `Product has_many :product_attributes`
   - `Product has_and_belongs_to_many :product_categories` (join table `product_category_products`)
   - `Product belongs_to :parent, class_name: 'Product', optional: true`
   - `Product has_many :children, class_name: 'Product', foreign_key: :parent_id, dependent: :destroy`
3. Add model callbacks:
   - `Vendor: before_save :auto_set_initial_name`
   - `Product: before_validation :auto_generate_sku, :auto_generate_barcode`
4. Add model validations:
   - Duplicate name check for Standalone/Parent in `Product`.
   - Block delete if associated order lines exist (`before_destroy :check_order_lines`).
5. Implement `VendorsController` (CRUD + `initialize_names` action).
6. Implement `BrandsController`, `ProductClassesController`, `ProductCategoriesController`.
7. Implement `AttributesController`, `ProductAttributesController`.
8. Implement `ProductsController`:
   - List (Sa + Pr only, paginated)
   - Show (with child list as nested frame)
   - New/Edit form with dynamic attribute fields (Stimulus controller)
   - `parent` action: returns child products of a parent
   - `child` action: child product detail
   - `advance_search` action (Ransack)
   - `last_price` action
   - `filters` action (`has_stock` filter)
9. Implement `ChildProductsController` (PUT + DELETE only).
10. Add unpaginated `GET /api/v1/catalogs/list_product_categories` endpoint.
11. Build all views using Railsblocks components.
12. Add Pundit policies; enforce `can_view_cost` in Product serializer.
13. Write model + request specs.

**Acceptance criteria:** Full product catalogue CRUD works; child products are managed under parents; cost field is hidden for users without the permission.

---

### Phase 5 — Stock Management Module
**Goal:** Inventory stock tracking with deposit, withdraw, and checkpoint recalculation.

**Steps:**
1. Generate models: `Branch`, `ProductStock`, `ProductStockTransaction`.
2. Set up associations and constraints (unique on branch + product).
3. Add `total_amount` computed getter: `amount - holding_amount`.
4. Implement `ProductStock` service methods:
   - `deposit!(amount:, reason:, related_object: nil)`
   - `withdraw!(amount:, reason:, related_object: nil)`
   - `withdraw_from_holding!(amount:, reason:, related_object: nil)`
   - `recalculate_checkpoint!`
5. Add `ProductStock.find_or_initialize_for(product:, branch:)` class method for auto-creation.
6. Implement `StocksController` (list, show, deposit, withdraw, recalculate_checkpoint, transactions).
7. Build Stock list + detail views with Railsblocks.
8. Seed default branch (`Branch.find_or_create_by!(name: 'Main Branch')`).
9. Write model + request specs including checkpoint recalculation.

**Acceptance criteria:** Stock levels update on deposit/withdraw; transactions are logged; checkpoint recalculation reconciles the balance.

---

### Phase 6 — Order Module (Core)
**Goal:** Full order lifecycle from creation to completion, with nested order lines and grand total auto-calculation.

**Steps:**
1. Generate models: `Order`, `OrderLine`, `OrderImage`.
2. Set up associations; fix `logistic_company` FK to `on_delete: :nullify`.
3. Implement `OrderNumberGenerator` service object.
4. Implement `GrandTotalCalculator` service object (full 7-step formula from §9.2).
5. Add `after_save` callback on `OrderLine` → calls `order.recalculate_grand_total!`.
6. Add `Order#set_created_by` / `#set_updated_by` callbacks (set from `Current.user`).
7. Set up `Current` attributes for `user` (use `ActiveSupport::CurrentAttributes`).
8. Implement `OrdersController`:
   - Standard CRUD
   - `draft`, `paid`, `completed`, `cancelled` filtered list actions
   - `dashboard` aggregated stats action
   - `advance_search` with Ransack + custom date range scopes
   - `filter` by status
   - `bulk_update_status`
   - `combine_bills`
9. Implement `OrderLinesController` (CRUD; triggers grand total recalculation via Turbo Stream).
10. Implement `OrderImagesController` (CRUD).
11. Build Order list view with status tab bar (Turbo Frame switching).
12. Build Order detail/edit view with inline line editor and running grand total display.
13. Add Stimulus controller for order line form (add/remove lines dynamically).
14. Add order line stock integration logic (§14.18 of requirements.md):
    - `after_create :handle_stock_create`
    - `after_update :handle_stock_update`
    - `before_destroy :handle_stock_destroy`
15. Write model + request specs including grand total calculation edge cases.

**Acceptance criteria:** Full order lifecycle works; grand total auto-updates; stock adjustments fire on line changes; bulk status update works.

---

### Phase 7 — Excel Export & Reporting Module
**Goal:** All Excel-based reports and exports working, with secure download URLs.

**Steps:**
1. Implement `OrderExcelService` using caxlsx:
   - Invoice structure: header, body, summary (§10.4).
   - Called from `GET /orders/:id/export`.
2. Implement signed export URL pattern:
   - `GET /orders/:id/export_token` returns `{ token: "...", expires_at: "..." }`.
   - `GET /orders/download?token=...` verifies the signed token and streams the file.
3. Implement `CombinedBillsService` (§10.5).
4. Implement `CustomerReportService` (§10.2) — completed orders by customer.
5. Implement `SalesReportService` (§10.3) — completed orders by staff.
6. Implement `SalesGraphService` (§10.1) — monthly aggregates using Groupdate.
7. Build reporting UI:
   - Date range picker for start/end date.
   - Download buttons for each report.
   - Sales graph using Chartkick on the Dashboard.
8. Gate all report endpoints behind `see_sale_graph` Pundit policy.
9. Write service-level specs for each Excel service.

**Acceptance criteria:** All three Excel reports download correctly; order invoice exports securely; sales graph renders on the dashboard.

---

### Phase 8 — Bulk Product Import Module
**Goal:** Excel file upload triggers background import of products.

**Steps:**
1. Generate `Upload` model with Active Storage attachment.
2. Implement `UploadsController` — accepts `.xlsx` multipart upload.
3. Validate MIME type server-side (only `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`).
4. Implement `BulkProductImportJob` (Sidekiq):
   - Parse with `roo`.
   - Each sheet → ProductClass.
   - Column mapping per §5.8 of requirements.md.
   - Upsert related entities.
   - Track results (rows processed, rows failed).
5. On job completion, broadcast result via Action Cable / Turbo Stream to the uploader's session.
6. Add import status/history view.
7. Write job specs with fixture `.xlsx` files.

**Acceptance criteria:** Uploading a valid Excel file creates/updates products in the background; user sees import result notification.

---

### Phase 9 — Polish, API Documentation & Deployment Prep
**Goal:** System is production-ready with full test coverage, API docs, and deployment config.

**Steps:**
1. Complete rswag API spec generation:
   - Write Swagger request specs for every API endpoint.
   - Run `rails rswag:specs:swaggerize` to generate `swagger.json`.
   - Mount Swagger UI at `/api-docs`.
2. Finalize RuboCop compliance: `bundle exec rubocop --autocorrect-all`.
3. RSpec full suite: aim for ≥ 90% coverage (SimpleCov).
4. Add database indexes audit:
   - FK columns indexed.
   - `order_number` unique index.
   - `sku` unique index.
   - `(branch_id, product_id)` unique index on `product_stocks`.
5. Add `Procfile` for Foreman: `web: rails server`, `sidekiq: bundle exec sidekiq`.
6. Configure `config/environments/production.rb`:
   - Force SSL.
   - Active Storage → S3 (or equivalent).
   - Log level: `:info`.
7. Database seeds:
   - Default admin user.
   - Default branch.
   - Country data.
   - Default permissions seeded via `rails db:seed`.
8. Write `README.md` with setup instructions, environment variables, and deployment guide.
9. Final security checklist review:
   - JWT secret in credentials (not committed).
   - All model validations present.
   - All Pundit policies in place.
   - `verify_authorized` after_action enforced.
   - Export endpoint secured.
   - `logistic_company` FK uses `nullify`.
   - 409 returned for protected deletes.

**Acceptance criteria:** Full test suite passes; API docs accessible; system is deployable to a production environment.

---

## 10. Testing Strategy

### 10.1 Test Layers

| Layer | Framework | Scope |
|---|---|---|
| Model specs | RSpec + Shoulda Matchers | Validations, associations, callbacks, service methods |
| Request specs | RSpec + rswag | API endpoints; auth, permission, response shape |
| Service specs | RSpec | Business logic (GrandTotalCalculator, OrderNumberGenerator, etc.) |
| Job specs | RSpec + Sidekiq::Testing | Background job behaviour |
| System specs | RSpec + Capybara | Critical user flows (login, create order, export) |

### 10.2 Key Test Cases

- Grand total calculation (all combinations of VAT / withholding tax / discount modes).
- Order number generation (collision-safe; daily reset).
- Soft delete (customers hidden from list; available in admin scope).
- Cost field hidden for users without `can_view_cost`.
- Stock auto-creation on first access.
- Stock deposit/withdraw/checkpoint recalculation.
- Order line stock integration (create, update, delete triggers correct stock movements).
- Bulk product import (valid and invalid Excel files).
- Signed export URL expiry.

### 10.3 Factory Conventions

```ruby
# spec/factories/orders.rb
FactoryBot.define do
  factory :order do
    association :customer
    association :created_by, factory: :user
    running_date { Date.today }
    status { "Dr" }
    logistic_status { "WTS" }
    is_withholding_tax { true }
    withholding_tax { 3 }
    has_vat { false }
    is_included_vat { false }
    is_discount_percentage { false }
    discount_price { 0 }
  end
end
```

---

## Appendix A — Rails Directory Structure

```
app/
  controllers/
    api/
      v1/
        auth/
        catalogs/
        customers/
        logistic_companies/
        orders/
        stocks/
        users/
    application_controller.rb
    orders_controller.rb       # Web UI
    products_controller.rb
    customers_controller.rb
    ...
  models/
    concerns/
      soft_deletable.rb
      image_compressible.rb
    order.rb
    order_line.rb
    product.rb
    ...
  services/
    grand_total_calculator.rb
    order_number_generator.rb
    order_excel_service.rb
    combined_bills_service.rb
    customer_report_service.rb
    sales_report_service.rb
    sales_graph_service.rb
    bulk_product_import_service.rb
  jobs/
    bulk_product_import_job.rb
    export_report_job.rb
  policies/
    application_policy.rb
    order_policy.rb
    product_policy.rb
    customer_policy.rb
    ...
  serializers/          # Active Model Serializers or simple presenters
  views/
    layouts/
      application.html.erb
      _header.html.erb
      _sidebar.html.erb
      _flash.html.erb
    orders/
    products/
    customers/
    ...
  javascript/
    controllers/
      sidebar_controller.js
      order_line_controller.js
      flash_controller.js
      ...
config/
  routes.rb
db/
  seeds/
    countries.rb
    admin_user.rb
spec/
  factories/
  models/
  requests/
    api/
      v1/
  services/
  jobs/
  system/
```

---

## Appendix B — Route Summary

```ruby
# config/routes.rb (outline)
Rails.application.routes.draw do
  root to: "dashboard#index"

  # Devise + JWT
  devise_for :users, controllers: { sessions: "api/v1/auth/sessions" }

  # Web UI
  resources :users do
    member do
      post :activate
      post :deactivate
    end
    collection do
      post :force_password
    end
  end
  resource :profile, only: [:show, :edit, :update]

  resources :roles
  resources :vendors do
    collection { post :initialize_names }
  end
  resources :brands
  resources :product_classes
  resources :product_categories
  resources :attributes
  resources :product_attributes
  resources :products do
    member do
      get :parent
      get :child
      get :last_price
    end
    collection do
      get :advance_search
      get :filters
    end
  end
  resources :child_products, only: [:update, :destroy]
  resources :product_images

  resources :branches
  resources :stocks, only: [:index, :show] do
    member do
      post :deposit
      post :withdraw
      post :recalculate_checkpoint
      get  :transactions
    end
  end

  resources :customers do
    collection { post :filter }
  end

  resources :logistic_companies do
    collection { post :filter }
  end

  resources :orders do
    member do
      get  :export
      get  :export_token
    end
    collection do
      get  :draft
      get  :paid
      get  :completed
      get  :cancelled
      get  :dashboard
      get  :advance_search
      post :filter
      patch :bulk_update_status
      post :combine_bills
      post :report_order
      post :customer_report
      post :sales_report
    end
  end
  resources :order_lines
  resources :order_images

  resources :uploads, only: [:create]
  resources :countries, only: [:index, :show, :create, :update, :destroy]

  # API
  namespace :api do
    namespace :v1 do
      # ... mirrors all resources above
    end
  end

  # API Docs
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
end
```
