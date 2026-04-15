# EPIC-03 — Country, Logistic Company & Customer

**Phase:** 3  
**Status:** 🟢 Completed  
**Goal:** ISO 3166-1 country reference data seeded and publicly accessible; logistic companies managed via full CRUD; customers managed with soft delete.

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

### STORY-03-01 — Country Module
**Status:** 🟢 Completed  
**Description:** Implement the Country reference model using `iso_3166_1_a2` as the natural primary key. Seed all ISO 3166-1 countries. The list endpoint requires no authentication.

| # | Task | Status |
|---|---|---|
| T-03-01-01 | Generate `Country` model with columns: `iso_3166_1_a2:string` (PK, limit 2), `iso_3166_1_a3:string` (limit 3), `iso_3166_1_numeric:string` (limit 3), `printable_name:string`, `name:string` | `[x]` |
| T-03-01-02 | Configure migration to set `iso_3166_1_a2` as primary key (no auto-increment id, no timestamps) | `[x]` |
| T-03-01-03 | Add validations: presence and uniqueness of `iso_3166_1_a2`; length exactly 2 | `[x]` |
| T-03-01-04 | Create `db/seeds/countries.rb` with all ISO 3166-1 alpha-2 country data (upsert-safe) | `[x]` |
| T-03-01-05 | Implement `CountriesController` with full CRUD | `[x]` |
| T-03-01-06 | Set `skip_before_action :authenticate_user!` and empty `permission_classes` on `CountriesController#index` and `#show` | `[x]` |
| T-03-01-07 | Expose `GET /api/v1/countries` without authentication | `[x]` |
| T-03-01-08 | Build Country list view (Railsblocks table) for admin management | `[x]` |
| T-03-01-09 | Write RSpec model specs and request specs (public access verified) | `[x]` |

---

### STORY-03-02 — Logistic Company Module
**Status:** 🟢 Completed  
**Description:** Full CRUD for LogisticCompany. Searchable by name, address, remark, telephone. Additional name-based filter endpoint.

| # | Task | Status |
|---|---|---|
| T-03-02-01 | Generate `LogisticCompany` model: `name:string`, `address:text`, `remark:text`, `telephone:string` (limit 255), timestamps | `[x]` |
| T-03-02-02 | Add validations: presence of `name` | `[x]` |
| T-03-02-03 | Implement `LogisticCompaniesController` with full CRUD | `[x]` |
| T-03-02-04 | Add Ransack search on `name`, `address`, `remark`, `telephone` to the list action | `[x]` |
| T-03-02-05 | Implement `POST /api/v1/logistic_companies/filter` with `{ search_text }` body filtering by name (case-insensitive) | `[x]` |
| T-03-02-06 | Build list view: Railsblocks table with search bar and pagination | `[x]` |
| T-03-02-07 | Build new/edit form view with Railsblocks form | `[x]` |
| T-03-02-08 | Add `LogisticCompanyPolicy` with standard Pundit CRUD predicates | `[x]` |
| T-03-02-09 | Write RSpec model specs and request specs (CRUD + filter endpoint) | `[x]` |

---

### STORY-03-03 — Customer Module
**Status:** 🟢 Completed  
**Description:** Full CRUD for Customer with soft delete. Deleted customers are hidden from the default list. `get_fullname` helper returns full display name. Search by name, address, telephone, logistic company name.

| # | Task | Status |
|---|---|---|
| T-03-03-01 | Generate `Customer` model: `first_name:string`, `last_name:string`, `address:text`, `remark:text`, `telephone:string`, `country_id:string` (FK to countries, nullable), `logistic_company_id:bigint` (FK, nullable), `deleted_at:datetime` | `[x]` |
| T-03-03-02 | Include `SoftDeletable` concern in `Customer`; default scope excludes `deleted_at IS NOT NULL` | `[x]` |
| T-03-03-03 | Implement `SoftDeletable` Rails concern (if not already done in EPIC-01): adds `soft_delete!`, `restore!` instance methods and `.active`, `.deleted`, `.with_deleted` scopes | `[x]` |
| T-03-03-04 | Implement `Customer#get_fullname`: returns `first_name` if `last_name` blank, else `"#{first_name} #{last_name}"` | `[x]` |
| T-03-03-05 | Implement `CustomersController` with `index`, `show`, `new`, `create`, `edit`, `update`, `destroy` (soft delete on destroy) | `[x]` |
| T-03-03-06 | Implement `POST /api/v1/customers/filter` with `{ search_text }` searching first and last name | `[x]` |
| T-03-03-07 | Add Ransack search on `first_name`, `last_name`, `address`, `remark`, `telephone`, `logistic_company_name` to list | `[x]` |
| T-03-03-08 | Build Customer list view: Railsblocks table with soft-delete indicator and restore button for admin | `[x]` |
| T-03-03-09 | Build new/edit form view with country and logistic company dropdowns | `[x]` |
| T-03-03-10 | Add `CustomerPolicy` with standard Pundit CRUD predicates | `[x]` |
| T-03-03-11 | Write RSpec model specs: soft delete, restore, `get_fullname`, scopes | `[x]` |
| T-03-03-12 | Write RSpec request specs: CRUD, soft delete, filter endpoint | `[x]` |
