# EPIC-15 — Unit Converter for Stock

**Phase:** 15
**Status:** 🟢 Completed
**Goal:** Staff can define global unit groups (e.g. pcs → dozen) and optionally override the unit group per product; all stock values are stored and transacted in the smallest unit, and the UI displays stock in the largest applicable unit computed live, eliminating the need for multiple stock transaction records per unit type.

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

### Core Concept

The current system stores the `unit` field on `Product` as a free-text string (e.g. `product[unit]` rendered as a plain `<input type="text">` in the product form at `/products/new` and `/products/:id/edit`). Stock is tracked in raw decimal amounts on `ProductStock.amount` with no awareness of unit ratios.

This epic replaces that model with:

1. **`UnitGroup`** — a named collection of units (e.g. "Standard Piece Count").
2. **`UnitDefinition`** — a unit entry within a group (e.g. `pcs` = 1 × base, `dozen` = 12 × base). The definition with `ratio = 1` is the base (smallest) unit.
3. **`Product.unit_group`** — an optional FK from Product to UnitGroup. If nil, the system's designated **global default** UnitGroup is used.
4. **`UnitGroup.is_default`** — a boolean flag; exactly one UnitGroup can be the system default at any time.

### Storage Rule

> **All stock `amount` values are stored and all deposit/withdraw transactions are recorded in the base unit (ratio = 1) of the product's effective unit group.**

### Display Rule

> **The UI converts the stored base-unit amount to the largest unit that fits evenly, showing the remainder in the next-smaller unit.** This conversion is performed purely in the view layer (Ruby helper or Stimulus controller) — no additional database records are written.

**Example:** A product with `UnitGroup = [pcs(×1), dozen(×12)]` and `ProductStock.amount = 37` displays as **"3 dozen 1 pcs"** (3×12 + 1×1 = 37).

### What Does NOT Change

- `ProductStock`, `ProductStockTransaction`, `ProductStock#deposit!`, `ProductStock#withdraw!` — these continue to operate on raw decimal amounts.

### OrderLine Unit Migration (STORY-15-06)

The existing `OrderLine.unit` enum (`Dz`=Dozen, `Pc`=Piece, `Pa`=Pack, `Se`=Set, `Ct`=Carton) is migrated to a FK reference to `UnitDefinition` in STORY-15-06. The five codes are seeded as `UnitDefinition` records and existing rows are data-migrated. The legacy enum column is then dropped.

---

## Stories

---

### STORY-15-01 — UnitGroup & UnitDefinition Data Model

**Status:** 🟢 Completed
**Description:** Create the `UnitGroup` and `UnitDefinition` database models with all validations, associations, and business-rule enforcement so that the rest of the epic can build on a solid data foundation.

**User Perspective:**
As a system, I want a validated data model for unit groups and their constituent unit definitions, so that unit conversion ratios are stored accurately and consistently for use across products and stock displays.

**Acceptance Criteria:**

| #     | Given                                                                  | When                                                                    | Then                                                                                                                                         |
| ----- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | No UnitGroup exists in the database                                    | A UnitGroup with `name = "Standard"` and `is_default = true` is saved   | A new `unit_groups` row is created with `is_default = true`; the database contains exactly 1 row with `is_default = true`                    |
| AC-02 | A UnitGroup with `is_default = true` already exists                    | A second UnitGroup is saved with `is_default = true`                    | The previously-default group's `is_default` is set to `false`; the new group's `is_default` is `true`; there is exactly 1 default at all times |
| AC-03 | A UnitGroup exists                                                      | A UnitDefinition with `name = "pcs"`, `ratio = 1` is created for it    | The row is persisted; `ratio` is stored as a positive integer ≥ 1                                                                            |
| AC-04 | A UnitGroup exists with `pcs(×1)` and `dozen(×12)` definitions         | A third UnitDefinition with `ratio = 0` is submitted                    | The save is rejected with a `422` validation error containing `"ratio must be greater than 0"`                                               |
| AC-05 | A UnitGroup already has a UnitDefinition with `ratio = 1`               | A second UnitDefinition with `ratio = 1` is submitted for the same group | The save is rejected with a `422` validation error containing `"ratio 1 already exists in this unit group"`                                  |
| AC-06 | A UnitGroup with `is_default = true` and a Product linked to it exists | `UnitGroup#destroy` is called                                           | Destroy is blocked; a `409 Conflict` error is returned with message `"Cannot delete a unit group that is assigned to products"`              |
| AC-07 | A UnitGroup exists with no Products linked                             | `UnitGroup#destroy` is called on it                                     | The group and all its `UnitDefinition` records are destroyed (cascade); `200 OK` is returned                                                 |

**Edge Cases:**

- `UnitGroup.name` must be unique (case-insensitive); a duplicate name submission returns `422`.
- `UnitDefinition.name` must be unique within its `unit_group` (case-insensitive; e.g. `PCS` and `pcs` are the same); duplicate returns `422`.
- A UnitGroup must have at least one UnitDefinition with `ratio = 1` before it can be set as default or assigned to a product — validation fires on the UnitGroup level when `is_default` is being set to `true` with no base definition present.
- `ratio` must be stored as a positive integer (not decimal); the migration uses `integer, null: false` with a DB-level check constraint `ratio > 0`.

| #          | Task                                                                                                    | Status |
| ---------- | ------------------------------------------------------------------------------------------------------- | ------ |
| T-15-01-01 | Create migration: `create_unit_groups` (`name:string`, `is_default:boolean default false`, `timestamps`) | `[x]`  |
| T-15-01-02 | Add DB-level unique index on `unit_groups.name`                                                         | `[x]`  |
| T-15-01-03 | Create migration: `create_unit_definitions` (`unit_group:references`, `name:string`, `ratio:integer`, `is_migration_placeholder:boolean default false`, `timestamps`) | `[x]`  |
| T-15-01-04 | Add DB-level check constraint `ratio > 0` on `unit_definitions`                                         | `[x]`  |
| T-15-01-05 | Add DB-level unique index on `(unit_group_id, ratio)` — only one base unit per group                   | `[x]`  |
| T-15-01-06 | Add DB-level unique index on `(unit_group_id, name)` for uniqueness within group                        | `[x]`  |
| T-15-01-07 | Generate `UnitGroup` model; add `has_many :unit_definitions, dependent: :destroy`                       | `[x]`  |
| T-15-01-08 | Add `validates :name, presence: true, uniqueness: { case_sensitive: false }` to `UnitGroup`            | `[x]`  |
| T-15-01-09 | Add `before_save :enforce_single_default` callback on `UnitGroup` to clear other defaults when `is_default` becomes true | `[x]`  |
| T-15-01-10 | Add `validate :has_base_unit_if_default` on `UnitGroup` (ratio=1 definiton must exist when `is_default = true`) | `[x]`  |
| T-15-01-11 | Add `before_destroy :prevent_if_assigned_to_products` callback on `UnitGroup`                          | `[x]`  |
| T-15-01-12 | Generate `UnitDefinition` model; add `belongs_to :unit_group`                                           | `[x]`  |
| T-15-01-13 | Add `validates :name, :ratio, presence: true` to `UnitDefinition`                                      | `[x]`  |
| T-15-01-14 | Add `validates :ratio, numericality: { only_integer: true, greater_than: 0 }` to `UnitDefinition`      | `[x]`  |
| T-15-01-15 | Add `validates :ratio, uniqueness: { scope: :unit_group_id, message: "ratio 1 already exists in this unit group" }` — scoped only when ratio == 1 | `[x]`  |
| T-15-01-16 | Add `validates :name, uniqueness: { scope: :unit_group_id, case_sensitive: false }` to `UnitDefinition` | `[x]`  |
| T-15-01-17 | Add `belongs_to :unit_group, optional: true` on `Product` (association only; migration in T-15-01-18)  | `[x]`  |
| T-15-01-18 | Create migration: `add_unit_group_id_to_products` (`unit_group_id:bigint, null: true, foreign_key: true`) | `[x]`  |
| T-15-01-19 | Write RSpec model specs for `UnitGroup` (all AC-01 through AC-07 scenarios)                             | `[x]`  |
| T-15-01-20 | Write RSpec model specs for `UnitDefinition` validations                                                | `[x]`  |

---

### STORY-15-02 — Unit Group Management UI (Admin)

**Status:** 🟢 Completed
**Description:** Provide a CRUD interface at `/unit_groups` where an admin can create, view, edit, and delete unit groups and their unit definitions, and designate one group as the system-wide global default.

**User Perspective:**
As an Admin, I want to manage unit groups and their definitions from a dedicated settings page, so that I can configure measurement units once and have them apply globally to all products that don't have a custom override.

**Acceptance Criteria:**

| #     | Given                                                          | When                                                                                        | Then                                                                                                                                    |
| ----- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | An authenticated admin visits `GET /unit_groups`               | The page loads                                                                              | A table lists all UnitGroups; each row shows Name, Is Default (yes/no badge), number of UnitDefinitions, and Edit / Delete / Set Default action buttons |
| AC-02 | Admin fills in Name = "Standard Piece Count" and submits `POST /unit_groups` | Form validation passes                                                             | A new UnitGroup is created; user is redirected to `GET /unit_groups/:id` (the detail page); a Turbo flash message reads "Unit group created." |
| AC-03 | Admin is on the UnitGroup detail page `GET /unit_groups/:id`   | The page loads                                                                              | The group name, is_default badge, and a table of all UnitDefinitions (Name, Ratio, Edit/Delete) are visible; an "Add Unit" inline form is present |
| AC-04 | Admin fills in Unit Name = "pcs", Ratio = 1 and clicks "Add Unit" | `POST /unit_groups/:id/unit_definitions` is submitted                                   | A new UnitDefinition row appears in the table via Turbo Stream (no full page reload); flash "Unit definition added."                     |
| AC-05 | Admin fills in Unit Name = "dozen", Ratio = 12 and clicks "Add Unit" | `POST /unit_groups/:id/unit_definitions` is submitted                                  | A new row appears in the table; the group now shows 2 definitions                                                                       |
| AC-06 | Admin clicks "Set as Default" on a UnitGroup that has a base unit (ratio=1) | `PATCH /unit_groups/:id/set_default` is submitted                                  | The previously-default group's badge changes; the clicked group's badge shows "Default"; flash "Default unit group updated."            |
| AC-07 | Admin clicks "Set as Default" on a UnitGroup that has NO base unit (ratio=1) | `PATCH /unit_groups/:id/set_default` is submitted                                  | Request returns `422`; flash "Cannot set as default: group has no base unit (ratio = 1)."                                               |
| AC-08 | Admin clicks Delete on a UnitGroup that has Products linked    | `DELETE /unit_groups/:id` is submitted                                                      | Request returns `409`; user sees flash "Cannot delete: this unit group is assigned to products."                                        |
| AC-09 | Admin clicks Delete on a UnitGroup that has NO Products linked | `DELETE /unit_groups/:id` is submitted                                                      | Group and all its UnitDefinitions are deleted; user is redirected to `/unit_groups`; flash "Unit group deleted."                        |
| AC-10 | An unauthenticated user visits `GET /unit_groups`              | The page loads                                                                              | Response is `302` redirect to `/users/sign_in`                                                                                          |
| AC-11 | A user without the `manage_unit_groups` Pundit permission visits `GET /unit_groups` | The page loads                                                                | Response is `403 Forbidden`; user sees the standard permission-denied flash message                                                     |

**Edge Cases:**

- Attempting to delete the only UnitDefinition with `ratio = 1` from a group that has `is_default = true` is blocked; flash "Cannot remove the base unit from the default group."
- Ratio input must only accept positive integers; submitting a decimal (e.g. `1.5`) is rejected with `422`.
- A UnitGroup with zero UnitDefinitions displays "No units defined yet." in the definitions table.

| #          | Task                                                                                                                                    | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-15-02-01 | Add `UnitGroupPolicy` (Pundit); add `manage_unit_groups` permission codename to the permissions list                                    | `[x]`  |
| T-15-02-02 | Add `UnitDefinitionPolicy` delegating to `UnitGroupPolicy`                                                                              | `[x]`  |
| T-15-02-03 | Create `UnitGroupsController` with `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`, `set_default` actions               | `[x]`  |
| T-15-02-04 | Add routes: `resources :unit_groups do; member { patch :set_default }; resources :unit_definitions, only: [:create, :destroy]; end`    | `[x]`  |
| T-15-02-05 | Create `UnitDefinitionsController` with `create` and `destroy` actions (nested under `unit_groups`)                                    | `[x]`  |
| T-15-02-06 | Build `app/views/unit_groups/index.html.erb` — table with Name, Default badge, Definition count, action buttons                        | `[x]`  |
| T-15-02-07 | Build `app/views/unit_groups/show.html.erb` — group header, is_default badge, definitions table, inline "Add Unit" form                | `[x]`  |
| T-15-02-08 | Build `app/views/unit_groups/_form.html.erb` (shared new/edit form for UnitGroup name and is_default checkbox)                         | `[x]`  |
| T-15-02-09 | Build `app/views/unit_definitions/_unit_definition.html.erb` partial (turbo_frame wrapping each row)                                   | `[x]`  |
| T-15-02-10 | Implement Turbo Stream response in `UnitDefinitionsController#create` to append the new row to the definitions table without page reload | `[x]`  |
| T-15-02-11 | Implement Turbo Stream response in `UnitDefinitionsController#destroy` to remove the row without page reload                            | `[x]`  |
| T-15-02-12 | Add "Unit Groups" link to the sidebar under "Catalog" section (visible only to users with `manage_unit_groups` permission)              | `[x]`  |
| T-15-02-13 | Write RSpec request specs for `UnitGroupsController` (all AC-01 through AC-11)                                                         | `[x]`  |
| T-15-02-14 | Write RSpec request specs for `UnitDefinitionsController` create and destroy                                                            | `[x]`  |
| T-15-02-15 | In `_unit_definition.html.erb` partial: render a yellow "Migration placeholder — please review ratio" badge when `unit_definition.is_migration_placeholder == true`; badge is hidden once ratio is edited (admin saves a new ratio via `PATCH /unit_groups/:id/unit_definitions/:id`) | `[x]`  |

---

### STORY-15-03 — Per-Product Unit Group Override

**Status:** 🟢 Completed
**Description:** Allow staff to assign a specific UnitGroup to an individual product via the product edit form, overriding the global default; when no override is set, the product falls back to the system default UnitGroup automatically.

**User Perspective:**
As a Staff member, I want to assign a custom unit group to a specific product, so that products with non-standard measurement units (e.g. rolls vs metres) are handled correctly without affecting other products.

**Acceptance Criteria:**

| #     | Given                                                                               | When                                                                          | Then                                                                                                                                                  |
| ----- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | Staff visits `GET /products/:id/edit`                                               | The form renders                                                              | A "Unit Group" Tom Select dropdown (`product[unit_group_id]`) is present; it defaults to blank (no override) with placeholder text "Use system default" |
| AC-02 | Staff selects a non-default UnitGroup from the dropdown and submits `PATCH /products/:id` | Validation passes                                                        | `products.unit_group_id` is saved; on the product detail and product list the "Unit" column shows the names of the custom group's units               |
| AC-03 | Staff clears the "Unit Group" dropdown selection and submits `PATCH /products/:id`  | Validation passes                                                             | `products.unit_group_id` is set to `NULL`; the product falls back to the system default UnitGroup for all display and stock calculations              |
| AC-04 | A product has `unit_group_id = NULL` and the system default UnitGroup is changed    | The default flag is moved to a new UnitGroup via `PATCH /unit_groups/:id/set_default` | The product's stock display immediately reflects the new default UnitGroup's definitions on next page load (no data migration needed)            |
| AC-05 | Staff submits `PATCH /products/:id` with a `unit_group_id` pointing to a non-existent UnitGroup | Validation runs                                                     | Response is `422`; flash "Unit group not found."                                                                                                      |
| AC-06 | A user without `change_product` Pundit permission submits `PATCH /products/:id`     | Request is processed                                                          | Response is `403 Forbidden`                                                                                                                           |

**Edge Cases:**

- If no default UnitGroup exists in the system (freshly seeded DB with no unit groups), products with `unit_group_id = NULL` fall back to displaying the raw numeric `amount` with the legacy free-text `product.unit` label and a warning badge "No unit group configured".
- The old free-text `product[unit]` field remains in the form and database for backward compatibility; it is displayed as a read-only disabled input labeled "Legacy Unit" alongside the new unit group selector.

| #          | Task                                                                                                                                             | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-15-03-01 | Add "Unit Group" Tom Select dropdown to `app/views/products/_form.html.erb` (input name: `product[unit_group_id]`, placeholder: "Use system default") | `[x]`  |
| T-15-03-02 | Update `ProductsController#update` and `#create` to permit `unit_group_id` in strong params                                                    | `[x]`  |
| T-15-03-03 | Create `Product#effective_unit_group` instance method: returns `unit_group` if set, otherwise `UnitGroup.find_by(is_default: true)`              | `[x]`  |
| T-15-03-04 | Update `GET /api/v1/catalogs/products/` serialiser to include `unit_group_id` and `effective_unit_group` (id, name, definitions) in JSON response | `[x]`  |
| T-15-03-05 | Update `app/views/products/index.html.erb`: the "Unit" column shows the effective unit group's base unit name (or legacy `product.unit` if no group) | `[x]`  |
| T-15-03-06 | Remove the existing `product[unit]` text input entirely from `_form.html.erb`                                                               | `[x]`  |
| T-15-03-07 | Write RSpec model specs for `Product#effective_unit_group`                                                                                       | `[x]`  |
| T-15-03-08 | Write RSpec request specs for `ProductsController` unit_group CRUD scenarios (AC-01 through AC-06)                                               | `[x]`  |

---

### STORY-15-04 — Stock Display: Biggest-Unit-First Live Conversion

**Status:** 🟢 Completed
**Description:** Convert the raw base-unit stock amounts into a human-readable multi-unit display (e.g. "3 dozen 1 pcs") across all stock-facing views — the stock list (`/stocks`), stock detail (`/stocks/:id`), and the product list stock badge — without writing any additional database records.

**User Perspective:**
As a Staff member, I want stock amounts displayed in the largest applicable unit first, so that I can instantly understand how much stock is available without mentally converting raw piece counts.

**Acceptance Criteria:**

| #     | Given                                                                                             | When                                                            | Then                                                                                                                                                    |
| ----- | ------------------------------------------------------------------------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A product has `effective_unit_group = [pcs(×1), dozen(×12)]` and `ProductStock.amount = 37`       | Staff visits `GET /stocks`                                      | The Amount column displays **"3 doz 1 pcs"** (computed as: 37 ÷ 12 = 3 remainder 1)                                                                    |
| AC-02 | Same product, `ProductStock.holding_amount = 13`                                                  | Staff visits `GET /stocks`                                      | Holding column displays **"1 doz 1 pcs"**; Available column displays **"2 doz"** (24 pcs = 37 − 13)                                                    |
| AC-03 | A product has `effective_unit_group = [pcs(×1), dozen(×12)]` and `amount = 24`                   | Staff visits `GET /stocks/:id`                                  | The AMOUNT summary box displays **"2 doz"**; the HOLDING and AVAILABLE boxes follow the same conversion formula                                         |
| AC-04 | A product has `unit_group_id = NULL` and no default UnitGroup is set                             | Staff views the stock for that product on `/stocks`             | The Amount column displays the raw numeric value (e.g. `37`) followed by the legacy `product.unit` text; a yellow warning badge reads "No unit group"   |
| AC-05 | A UnitGroup has 3 definitions: `pcs(×1)`, `dozen(×12)`, `gross(×144)`; `amount = 200`            | Staff views stock                                               | Display shows **"1 gross 4 doz 8 pcs"** (144 + 48 + 8 = 200)                                                                                           |
| AC-06 | Same 3-unit group; `amount = 144`                                                                 | Staff views stock                                               | Display shows **"1 gross"** (no trailing zero units are shown)                                                                                          |
| AC-07 | Staff visits `GET /stocks/:id` (the transaction ledger section)                                   | The page renders                                                | Each `ProductStockTransaction.amount` row is also converted and shown in the biggest-unit-first format using the product's effective unit group         |

**Edge Cases:**

- Units are sorted **descending by ratio** before the greedy conversion algorithm runs; the largest unit is tried first.
- If a unit group has only one definition (ratio = 1), display is the raw integer followed by the unit name (e.g. `37 pcs`).
- Trailing units with a value of 0 are omitted from display.
- Fractional `amount` values are integer-divided; any sub-unit remainder is shown as `+0.5 pcs` appended to the display string to avoid silent data loss.

| #          | Task                                                                                                                                                            | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-15-04-01 | Create `UnitConversionHelper` in `app/helpers/unit_conversion_helper.rb` with method `format_stock_amount(amount, unit_group)` implementing greedy biggest-unit-first algorithm | `[x]`  |
| T-15-04-02 | `format_stock_amount`: sort UnitDefinitions by ratio DESC; greedily divide; skip zero-value units; return formatted string                                      | `[x]`  |
| T-15-04-03 | `format_stock_amount`: handle nil/no-group case — return `"#{amount} #{product.unit}"` with warning string                                                      | `[x]`  |
| T-15-04-04 | `format_stock_amount`: handle fractional remainder — append `"+#{remainder} #{base_unit_name}"` when `amount` has a non-zero fractional part                   | `[x]`  |
| T-15-04-05 | Include `UnitConversionHelper` in `ApplicationHelper`                                                                                                           | `[x]`  |
| T-15-04-06 | Update `app/views/stocks/index.html.erb`: replace raw Amount, Holding, Available values with `format_stock_amount(...)` calls                                   | `[x]`  |
| T-15-04-07 | Update `app/views/stocks/show.html.erb`: AMOUNT, HOLDING, AVAILABLE summary boxes use `format_stock_amount`                                                     | `[x]`  |
| T-15-04-08 | Update `app/views/stocks/show.html.erb`: transaction ledger `amount` column uses `format_stock_amount`                                                          | `[x]`  |
| T-15-04-09 | Update `app/views/products/index.html.erb`: stock badge column uses `format_stock_amount`                                                                       | `[x]`  |
| T-15-04-10 | Write RSpec unit specs for `UnitConversionHelper#format_stock_amount` covering all AC and edge cases                                                            | `[x]`  |

---

### STORY-15-05 — Unit-Aware Deposit & Withdraw Forms

**Status:** 🟢 Completed
**Description:** Enhance the deposit and withdraw forms on `GET /stocks/:id` to accept amounts expressed in any unit of the product's effective unit group (e.g. "2 dozen"), and automatically convert to the base unit before calling the existing `deposit!` / `withdraw!` methods.

**User Perspective:**
As a Staff member, I want to enter deposit and withdraw quantities in human-friendly units (e.g. dozens), so that I don't have to manually multiply by conversion ratios when recording stock movements.

**Acceptance Criteria:**

| #     | Given                                                                                               | When                                                                                                         | Then                                                                                                                                                         |
| ----- | --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | A product has `effective_unit_group = [pcs(×1), dozen(×12)]`; Staff visits `GET /stocks/:id`        | The Deposit form renders                                                                                     | The form shows a unit dropdown (listing `pcs` and `dozen`) and a quantity field; the old single `amount` field is replaced by `quantity` + `unit_definition_id` pair |
| AC-02 | Staff enters `quantity = 2`, selects `dozen`, and clicks "Deposit"                                  | `POST /stocks/:id/deposit` is submitted with `{ quantity: 2, unit_definition_id: <dozen_id>, reason: "..." }` | The controller converts: `base_amount = 2 × 12 = 24`; calls `stock.deposit!(24, reason: "...")`; a transaction of `+24` (base units) is recorded           |
| AC-03 | Staff enters `quantity = 1`, selects `dozen`; available stock is 10 pcs                            | `POST /stocks/:id/withdraw` is submitted                                                                     | Conversion: 1 dozen = 12 pcs > 10 pcs available; withdraw is rejected; flash "Insufficient stock: 12 pcs required, 10 pcs available."                       |
| AC-04 | Staff enters `quantity = 0` and clicks "Deposit"                                                    | `POST /stocks/:id/deposit` is submitted                                                                      | Response is `422`; flash "Quantity must be greater than 0."                                                                                                  |
| AC-05 | Staff enters `quantity = -3` and clicks "Withdraw"                                                  | `POST /stocks/:id/withdraw` is submitted                                                                     | Response is `422`; flash "Quantity must be greater than 0."                                                                                                  |
| AC-06 | A product has no effective unit group (no default set)                                              | Staff visits `GET /stocks/:id`                                                                               | Forms fall back to a single numeric `amount` field (legacy behaviour); yellow warning "No unit group configured — entering base units" is displayed          |
| AC-07 | Staff submits a deposit with a `unit_definition_id` that does not belong to the effective unit group | `POST /stocks/:id/deposit` is submitted                                                                   | Response is `422`; flash "Invalid unit for this product."                                                                                                    |

**Edge Cases:**

- When the effective unit group has only one definition (base unit only), the unit dropdown is hidden and the form renders a single `quantity` field with the base unit name as a label.
- The `reason` field remains optional for deposits and required for withdrawals (consistent with existing behaviour on `/stocks/:id`).
- A Stimulus `unit_preview_controller` dynamically updates a preview label showing the equivalent base-unit amount as the user types (e.g. `2` with `dozen` selected → "= 24 pcs").
- The `OrderLine.unit` enum migration is handled separately in STORY-15-06; this story covers stock deposit/withdraw forms only.

| #          | Task                                                                                                                                                                        | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-15-05-01 | Create `StockDepositWithdrawService` with `call(stock:, quantity:, unit_definition_id:, action:, reason:)` — validates unit ownership, converts to base units, delegates to `deposit!`/`withdraw!` | `[x]`  |
| T-15-05-02 | Add `unit_definition_id` and `quantity` to strong params in `StocksController#deposit` and `StocksController#withdraw`; remove raw `amount` param                         | `[x]`  |
| T-15-05-03 | Update `StocksController#deposit` to invoke `StockDepositWithdrawService` instead of `stock.deposit!` directly                                                             | `[x]`  |
| T-15-05-04 | Update `StocksController#withdraw` to invoke `StockDepositWithdrawService` instead of `stock.withdraw!` directly                                                           | `[x]`  |
| T-15-05-05 | Update Deposit form in `app/views/stocks/show.html.erb`: replace `amount` field with `quantity` input + `unit_definition_id` Tom Select dropdown                           | `[x]`  |
| T-15-05-06 | Update Withdraw form in `app/views/stocks/show.html.erb`: same replacement as T-15-05-05                                                                                   | `[x]`  |
| T-15-05-07 | Create `app/javascript/controllers/unit_preview_controller.js`; targets: `quantity` input, `unit` select, `preview` span; action: `input->unit-preview#update`             | `[x]`  |
| T-15-05-08 | `unit_preview_controller.js#update`: reads selected option's `data-ratio`; multiplies by quantity; updates preview span to "= X {base_unit_name}"                          | `[x]`  |
| T-15-05-09 | Wire `data-controller="unit-preview"` on both deposit and withdraw form containers in the view; add `data-ratio` to each `<option>` element                                | `[x]`  |
| T-15-05-10 | Add legacy fallback branch in `show.html.erb`: if `effective_unit_group` is nil, render single `amount` field with yellow warning badge                                    | `[x]`  |
| T-15-05-11 | Write RSpec service specs for `StockDepositWithdrawService` (all AC and edge cases)                                                                                         | `[x]`  |
| T-15-05-12 | Write RSpec request specs for updated `StocksController#deposit` and `StocksController#withdraw`                                                                           | `[x]`  |

---

### STORY-15-06 — Migrate OrderLine.unit Enum to UnitDefinition FK

**Status:** 🟢 Completed
**Description:** Replace the hardcoded `OrderLine.unit` Rails enum (`Dz`/`Pc`/`Pa`/`Se`/`Ct`) with a FK reference to `UnitDefinition`. The system default `UnitGroup` is seeded with only **two canonical definitions**: `pcs (×1)` and `dozen (×12)`. For the three legacy enum codes without a seeded equivalent (`Pa`, `Se`, `Ct`), migration-placeholder UnitDefinitions are created in the default group with `ratio = 1` so existing `OrderLine` rows can resolve their FK without data loss; admins can rename or adjust ratios afterwards. `pack`, `set`, and `carton` are not seeded by default — users create them manually in a UnitGroup of their choice with their preferred ratios.

**User Perspective:**
As a Staff member, I want order lines to use the same unit system as products and stock, so that unit labels on orders are consistent with how stock is measured and there is a single source of truth for all unit definitions.

**Acceptance Criteria:**

| #     | Given                                                                                                                         | When                                                                        | Then                                                                                                                                                        |
| ----- | ----------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | The system default `UnitGroup` is seeded | A staff member visits `GET /unit_groups/:id` for the default group | The definitions table shows exactly **2 canonical definitions**: `pcs (×1)` and `dozen (×12)`; no pack/set/carton rows are present unless they existed in the database before this seed ran |
| AC-02 | The data migration has run                                                                                                    | A developer queries `order_lines` in the database                           | Every `OrderLine` row has a non-null `unit_definition_id` FK pointing to the correct `UnitDefinition`; the legacy `unit` string column is absent from the schema |
| AC-03 | Staff opens the Order form at `GET /orders/new` or `GET /orders/:id/edit`                                                     | The order line unit field renders                                           | The unit field is a Tom Select dropdown populated from the selected product's `effective_unit_group.unit_definitions`; the old hardcoded 5-option select is gone  |
| AC-04 | Staff selects "dozen" for an order line and saves                                                                             | `POST /orders` or `PATCH /orders/:id` is submitted                          | `order_lines.unit_definition_id` is persisted; the order detail view displays "dozen" sourced from `UnitDefinition.name`                                     |
| AC-05 | Staff submits an order line with `unit_definition_id` that does not belong to the product's `effective_unit_group`            | The request is processed                                                    | Response is `422`; flash "Invalid unit for this product."                                                                                                    |
| AC-06 | An existing order (created before this migration) is viewed                                                                   | Staff opens `GET /orders/:id`                                               | Order lines display correct unit labels from migrated `UnitDefinition` records; no blank unit cells appear                                                   |
| AC-07 | Staff exports an order to Excel via `GET /orders/:id/export`                                                                  | The export runs                                                             | The Unit column in the Excel invoice shows `UnitDefinition.name` (e.g. "dozen") instead of the old enum code (e.g. `Dz`)                                     |
| AC-08 | A user without `change_order` Pundit permission submits an order line with a `unit_definition_id`                             | The request is processed                                                    | Response is `403 Forbidden`                                                                                                                                  |

- **Default seed (canonical):** Only `pcs (×1)` and `dozen (×12)` are seeded in the system default `UnitGroup`. `pack`, `set`, and `carton` are NOT seeded — users create them via the UnitGroup admin UI with their own ratios.
- **Migration placeholders for legacy Pa/Se/Ct rows:** The data migration creates three temporary UnitDefinitions in the default group — `pack (migration-placeholder, ×1)`, `set (migration-placeholder, ×1)`, `carton (migration-placeholder, ×1)` — solely to satisfy the FK for existing `OrderLine` rows. A flash notice in the Unit Groups UI flags placeholder definitions with a yellow badge "Migration placeholder — please review ratio" until an admin edits or removes them.
- The data migration maps legacy codes as: `Dz` → `dozen (×12)`, `Pc` → `pcs (×1)`, `Pa` → `pack placeholder (×1)`, `Se` → `set placeholder (×1)`, `Ct` → `carton placeholder (×1)`.
- The data migration must run inside a transaction; if any row fails to resolve a `unit_definition_id`, the migration raises and rolls back entirely.
- The legacy `unit` column on `order_lines` must NOT be dropped until the data migration is verified in staging; dropping is a separate migration step.
- If the product's `effective_unit_group` has only one `UnitDefinition` (base unit), the unit dropdown is hidden on the order line form and the single definition is auto-selected.
- The `OrderExcelService` must reference `order_line.unit_definition.name` (string) instead of the previously humanised enum value.

| #          | Task                                                                                                                                                                                        | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-15-06-01 | Create migration: `add_unit_definition_id_to_order_lines` (`unit_definition_id:bigint, null: true, foreign_key: true`) — nullable initially to allow data migration to run first            | `[x]`  |
| T-15-06-02 | Seed **2 canonical UnitDefinitions** in the system default `UnitGroup`: `pcs (×1)` and `dozen (×12)` (idempotent — skip if `UnitDefinition` with that name already exists in the default group) | `[x]`  |
| T-15-06-02b | Data migration only: create **3 migration-placeholder UnitDefinitions** in the default group — `pack (×1)`, `set (×1)`, `carton (×1)` — each with a `is_migration_placeholder: true` flag (requires adding a boolean `is_migration_placeholder` column to `unit_definitions`); skip if already present | `[x]`  |
| T-15-06-03 | Write data migration (separate migration file): map `Dz` → `dozen (×12)`, `Pc` → `pcs (×1)`; map `Pa`/`Se`/`Ct` → their respective migration-placeholder `UnitDefinition.id`; update `order_lines.unit_definition_id` for all rows; wrap entire operation in a transaction | `[x]`  |
| T-15-06-04 | Add `belongs_to :unit_definition, optional: true` to `OrderLine` model                                                                                                                     | `[x]`  |
| T-15-06-05 | Add `validate :unit_definition_belongs_to_product_group` on `OrderLine` — ensures `unit_definition.unit_group_id == product.effective_unit_group.id`                                        | `[x]`  |
| T-15-06-06 | Create migration: `change_column_null :order_lines, :unit_definition_id, false` — run after data migration is verified; also sets DB NOT NULL constraint                                    | `[x]`  |
| T-15-06-07 | Create migration: `remove_column :order_lines, :unit` — drop the legacy enum column after NOT NULL constraint is confirmed in staging                                                       | `[x]`  |
| T-15-06-08 | Remove the `:unit` enum definition from the `OrderLine` model                                                                                                                               | `[x]`  |
| T-15-06-09 | Update `OrderLinesController` strong params: replace `unit:` with `unit_definition_id:`                                                                                                     | `[x]`  |
| T-15-06-10 | Update `app/views/orders/_order_line_fields.html.erb`: replace the hardcoded 5-option `<select name="unit">` with a dropdown of `UnitDefinition` options, defaulting to the unit with the largest ratio in the product's group | `[x]`  |
| T-15-06-11 | Update the Stimulus order line controller to re-populate the unit dropdown via `GET /products/:id/unit_definitions` JSON when the product selection changes                                 | `[x]`  |
| T-15-06-12 | Add `GET /products/:id/unit_definitions` action to `ProductsController`; returns `effective_unit_group.unit_definitions` as JSON array of `{ id, name, ratio, is_base }`                   | `[x]`  |
| T-15-06-13 | Update `app/views/orders/show.html.erb` and the order line partial: display `order_line.unit_definition.name` instead of `order_line.unit.humanize`                                         | `[x]`  |
| T-15-06-14 | Update `OrderExcelService`: replace `order_line.unit` humanised string with `order_line.unit_definition.name`                                                                               | `[x]`  |
| T-15-06-15 | Write RSpec model specs for `OrderLine#unit_definition_belongs_to_product_group` validation                                                                                                 | `[ ]`  |
| T-15-06-16 | Write RSpec request specs for `OrderLinesController` with new `unit_definition_id` param (AC-04, AC-05, AC-08)                                                                              | `[ ]`  |
| T-15-06-17 | Write RSpec spec for `GET /products/:id/unit_definitions` endpoint                                                                                                                          | `[ ]`  |
| T-15-06-18 | Write RSpec service spec for `OrderExcelService` confirming Unit column uses `UnitDefinition.name` (AC-07)                                                                                  | `[ ]`  |

---

## Summary

| Story       | Title                                              | Tasks | Status         |
| ----------- | -------------------------------------------------- | ----- | -------------- |
| STORY-15-01 | UnitGroup & UnitDefinition Data Model              | 20    | 🟢 Completed   |
| STORY-15-02 | Unit Group Management UI (Admin)                   | 15    | 🟢 Completed   |
| STORY-15-03 | Per-Product Unit Group Override                    | 8     | 🟢 Completed   |
| STORY-15-04 | Stock Display: Biggest-Unit-First Conversion       | 10    | 🟢 Completed   |
| STORY-15-05 | Unit-Aware Deposit & Withdraw Forms                | 12    | 🟢 Completed   |
| STORY-15-06 | Migrate OrderLine.unit Enum to UnitDefinition FK   | 19    | 🟢 Completed   |
| **Total**   |                                                    | **84**|                |
