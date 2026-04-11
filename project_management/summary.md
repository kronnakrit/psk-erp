# PSK ERP — Project Summary

> Master progress tracker. Lists all epics, stories, and tasks with current status.  
> Last updated: 2026-04-10  
> **Update this file whenever a task or story status changes.**

---

## Legend

| Symbol | Meaning |
|---|---|
| 🔴 Not Started | No work begun |
| 🟡 In Progress | Actively being worked on |
| 🟢 Completed | Done and verified |
| `[ ]` | Task not started |
| `[~]` | Task in progress |
| `[x]` | Task completed |

---

## Overall Progress

| Epic | Stories | Tasks | Completed Tasks | Progress |
|---|---|---|---|---|
| EPIC-01 Project Bootstrap | 4 | 30 | 0 | 0% |
| EPIC-02 Auth & User Management | 4 | 38 | 0 | 0% |
| EPIC-03 Country / Logistic / Customer | 3 | 30 | 0 | 0% |
| EPIC-04 Product Catalog | 5 | 48 | 0 | 0% |
| EPIC-05 Stock Management | 3 | 26 | 0 | 0% |
| EPIC-06 Order Module | 6 | 53 | 0 | 0% |
| EPIC-07 Excel Export & Reporting | 4 | 30 | 0 | 0% |
| EPIC-08 Bulk Import | 3 | 24 | 0 | 0% |
| EPIC-09 Polish & Deployment | 3 | 38 | 0 | 0% |
| **TOTAL** | **35** | **317** | **0** | **0%** |

---

## EPIC-01 — Project Bootstrap & Infrastructure
**Status:** 🔴 Not Started | [Full details](./EPIC-01/stories.md)

### STORY-01-01 — Rails Application Initialisation 🔴
| Task | Status |
|---|---|
| T-01-01-01 Run `rails new psk-erp` | `[ ]` |
| T-01-01-02 Commit initial skeleton to version control | `[ ]` |
| T-01-01-03 Configure `database.yml` | `[ ]` |
| T-01-01-04 Run `rails db:create` and verify databases | `[ ]` |
| T-01-01-05 Set up `.env` and `dotenv-rails` | `[ ]` |
| T-01-01-06 Store credentials in `.env` | `[ ]` |

### STORY-01-02 — Gem Dependencies Installation 🔴
| Task | Status |
|---|---|
| T-01-02-01 Add `devise`, `devise-jwt` | `[ ]` |
| T-01-02-02 Add `pundit` | `[ ]` |
| T-01-02-03 Add `pagy` | `[ ]` |
| T-01-02-04 Add `ransack` | `[ ]` |
| T-01-02-05 Add `railsblocks` | `[ ]` |
| T-01-02-06 Add `caxlsx`, `caxlsx-rails` | `[ ]` |
| T-01-02-07 Add `roo` | `[ ]` |
| T-01-02-08 Add `sidekiq`, `redis` | `[ ]` |
| T-01-02-09 Add `chartkick`, `groupdate` | `[ ]` |
| T-01-02-10 Add testing gems | `[ ]` |
| T-01-02-11 Add RuboCop gems | `[ ]` |
| T-01-02-12 Add `rswag` | `[ ]` |
| T-01-02-13 Run `bundle install` | `[ ]` |

### STORY-01-03 — Infrastructure & Tooling Configuration 🔴
| Task | Status |
|---|---|
| T-01-03-01 Run `rails active_storage:install` | `[ ]` |
| T-01-03-02 Configure `config/storage.yml` | `[ ]` |
| T-01-03-03 Create `config/sidekiq.yml` | `[ ]` |
| T-01-03-04 Mount Sidekiq Web UI | `[ ]` |
| T-01-03-05 Configure Redis URL | `[ ]` |
| T-01-03-06 Run Tailwind CSS install | `[ ]` |
| T-01-03-07 Install Railsblocks | `[ ]` |
| T-01-03-08 Add `Procfile` | `[ ]` |
| T-01-03-09 Generate RuboCop baseline config | `[ ]` |
| T-01-03-10 Configure Pagy initialiser | `[ ]` |

### STORY-01-04 — Base Application Layout 🔴
| Task | Status |
|---|---|
| T-01-04-01 Create `application.html.erb` | `[ ]` |
| T-01-04-02 Create `_header.html.erb` partial | `[ ]` |
| T-01-04-03 Create `_sidebar.html.erb` with full menu | `[ ]` |
| T-01-04-04 Wrap main content in turbo_frame_tag | `[ ]` |
| T-01-04-05 Create `_flash.html.erb` | `[ ]` |
| T-01-04-06 Create `sidebar_controller.js` Stimulus | `[ ]` |
| T-01-04-07 Create `flash_controller.js` Stimulus | `[ ]` |
| T-01-04-08 Implement mobile-responsive sidebar | `[ ]` |
| T-01-04-09 RSpec install and configure | `[ ]` |
| T-01-04-10 Write smoke test for root route | `[ ]` |
| T-01-04-11 Verify server boots cleanly | `[ ]` |

---

## EPIC-02 — Authentication & User Management
**Status:** 🔴 Not Started | [Full details](./EPIC-02/stories.md)

### STORY-02-01 — Devise & JWT Authentication Setup 🔴
| Task | Status |
|---|---|
| T-02-01-01 Run `rails generate devise:install` | `[ ]` |
| T-02-01-02 Generate `User` model via Devise | `[ ]` |
| T-02-01-03 Add `username` and `is_active` columns | `[ ]` |
| T-02-01-04 Add `jti` column for JTI Matcher | `[ ]` |
| T-02-01-05 Configure `devise-jwt` in initialiser | `[ ]` |
| T-02-01-06 Configure JTI Matcher strategy | `[ ]` |
| T-02-01-07 Override `active_for_authentication?` | `[ ]` |
| T-02-01-08 Create `Api::V1::Auth::SessionsController` | `[ ]` |
| T-02-01-09 Implement refresh token endpoint | `[ ]` |
| T-02-01-10 Implement verify endpoint | `[ ]` |
| T-02-01-11 Create login view styled with Railsblocks | `[ ]` |
| T-02-01-12 Write RSpec request specs for auth | `[ ]` |

### STORY-02-02 — User Profile & Role Model 🔴
| Task | Status |
|---|---|
| T-02-02-01 Generate `Role` model | `[ ]` |
| T-02-02-02 Generate `Profile` model | `[ ]` |
| T-02-02-03 Add associations User ↔ Profile ↔ Role | `[ ]` |
| T-02-02-04 Add `has_many :profiles` to `Role` | `[ ]` |
| T-02-02-05 Implement `Profile#full_name` | `[ ]` |
| T-02-02-06 Add `after_create` callback for auto-Profile | `[ ]` |
| T-02-02-07 Seed admin user and Admin Role | `[ ]` |
| T-02-02-08 Write RSpec model specs | `[ ]` |

### STORY-02-03 — Pundit Authorisation Framework 🔴
| Task | Status |
|---|---|
| T-02-03-01 Run `rails generate pundit:install` | `[ ]` |
| T-02-03-02 Implement `ApplicationPolicy` base | `[ ]` |
| T-02-03-03 Add `verify_authorized` after_actions | `[ ]` |
| T-02-03-04 Create `PermissionCheckable` concern | `[ ]` |
| T-02-03-05 Create `ProductPolicy` with `can_view_cost?` | `[ ]` |
| T-02-03-06 Create `OrderPolicy` with `report?` | `[ ]` |
| T-02-03-07 Rescue `NotAuthorizedError` → 403 JSON | `[ ]` |
| T-02-03-08 Write RSpec policy specs | `[ ]` |

### STORY-02-04 — User & Role Management UI 🔴
| Task | Status |
|---|---|
| T-02-04-01 Implement `UsersController` | `[ ]` |
| T-02-04-02 Implement force password controller | `[ ]` |
| T-02-04-03 Implement `ProfilesController` | `[ ]` |
| T-02-04-04 Build User list view | `[ ]` |
| T-02-04-05 Build User form view | `[ ]` |
| T-02-04-06 Implement `RolesController` CRUD | `[ ]` |
| T-02-04-07 Implement `PermissionsController` | `[ ]` |
| T-02-04-08 Add permission guards to sidebar | `[ ]` |
| T-02-04-09 Add API routes for user/role actions | `[ ]` |
| T-02-04-10 Write RSpec request specs | `[ ]` |

---

## EPIC-03 — Country, Logistic Company & Customer
**Status:** 🔴 Not Started | [Full details](./EPIC-03/stories.md)

### STORY-03-01 — Country Module 🔴
| Task | Status |
|---|---|
| T-03-01-01 Generate `Country` model | `[ ]` |
| T-03-01-02 Configure natural PK migration | `[ ]` |
| T-03-01-03 Add validations | `[ ]` |
| T-03-01-04 Create country seeds | `[ ]` |
| T-03-01-05 Implement `CountriesController` | `[ ]` |
| T-03-01-06 Set public access on index/show | `[ ]` |
| T-03-01-07 Expose public API endpoint | `[ ]` |
| T-03-01-08 Build Country list view | `[ ]` |
| T-03-01-09 Write RSpec specs | `[ ]` |

### STORY-03-02 — Logistic Company Module 🔴
| Task | Status |
|---|---|
| T-03-02-01 Generate `LogisticCompany` model | `[ ]` |
| T-03-02-02 Add validations | `[ ]` |
| T-03-02-03 Implement `LogisticCompaniesController` | `[ ]` |
| T-03-02-04 Add Ransack search | `[ ]` |
| T-03-02-05 Implement filter endpoint | `[ ]` |
| T-03-02-06 Build list view | `[ ]` |
| T-03-02-07 Build form view | `[ ]` |
| T-03-02-08 Add `LogisticCompanyPolicy` | `[ ]` |
| T-03-02-09 Write RSpec specs | `[ ]` |

### STORY-03-03 — Customer Module 🔴
| Task | Status |
|---|---|
| T-03-03-01 Generate `Customer` model | `[ ]` |
| T-03-03-02 Include `SoftDeletable` concern | `[ ]` |
| T-03-03-03 Implement `SoftDeletable` concern | `[ ]` |
| T-03-03-04 Implement `Customer#get_fullname` | `[ ]` |
| T-03-03-05 Implement `CustomersController` | `[ ]` |
| T-03-03-06 Implement filter endpoint | `[ ]` |
| T-03-03-07 Add Ransack search | `[ ]` |
| T-03-03-08 Build list view with soft-delete | `[ ]` |
| T-03-03-09 Build form view | `[ ]` |
| T-03-03-10 Add `CustomerPolicy` | `[ ]` |
| T-03-03-11 Write RSpec model specs | `[ ]` |
| T-03-03-12 Write RSpec request specs | `[ ]` |

---

## EPIC-04 — Product Catalog Module
**Status:** 🔴 Not Started | [Full details](./EPIC-04/stories.md)

### STORY-04-01 — Vendor & Brand Management 🔴
| Task | Status |
|---|---|
| T-04-01-01 Generate `Vendor` model | `[ ]` |
| T-04-01-02 Add `auto_set_initial_name` callback | `[ ]` |
| T-04-01-03 Add validations | `[ ]` |
| T-04-01-04 Implement `VendorsController` | `[ ]` |
| T-04-01-05 Add `initialize_names` collection action | `[ ]` |
| T-04-01-06 Add Ransack search | `[ ]` |
| T-04-01-07 Build Vendor views | `[ ]` |
| T-04-01-08 Generate `Brand` model | `[ ]` |
| T-04-01-09 Implement `BrandsController` | `[ ]` |
| T-04-01-10 Build Brand views | `[ ]` |
| T-04-01-11 Add Vendor and Brand Policies | `[ ]` |
| T-04-01-12 Write Vendor model specs | `[ ]` |
| T-04-01-13 Write Vendor request specs | `[ ]` |

### STORY-04-02 — Product Class & Category Management 🔴
| Task | Status |
|---|---|
| T-04-02-01 Generate `ProductClass` model | `[ ]` |
| T-04-02-02 Implement `ProductClassesController` | `[ ]` |
| T-04-02-03 Build ProductClass views | `[ ]` |
| T-04-02-04 Generate `ProductCategory` model | `[ ]` |
| T-04-02-05 Implement `ProductCategoriesController` | `[ ]` |
| T-04-02-06 Add unpaginated list endpoint | `[ ]` |
| T-04-02-07 Build ProductCategory views | `[ ]` |
| T-04-02-08 Add Policies | `[ ]` |
| T-04-02-09 Write RSpec specs | `[ ]` |

### STORY-04-03 — Attribute System 🔴
| Task | Status |
|---|---|
| T-04-03-01 Generate `Attribute` model | `[ ]` |
| T-04-03-02 Add unique index on (name, product_class_id) | `[ ]` |
| T-04-03-03 Add associations | `[ ]` |
| T-04-03-04 Generate `ProductAttribute` model | `[ ]` |
| T-04-03-05 Add unique index on (product_id, attribute_id) | `[ ]` |
| T-04-03-06 Implement `AttributesController` | `[ ]` |
| T-04-03-07 Implement `ProductAttributesController` | `[ ]` |
| T-04-03-08 Add Policies | `[ ]` |
| T-04-03-09 Write RSpec specs | `[ ]` |

### STORY-04-04 — Product Core (CRUD & Business Logic) 🔴
| Task | Status |
|---|---|
| T-04-04-01 Generate `Product` model | `[ ]` |
| T-04-04-02 Set up join table | `[ ]` |
| T-04-04-03 Add all associations | `[ ]` |
| T-04-04-04 Add SKU auto-generation callback | `[ ]` |
| T-04-04-05 Add barcode auto-generation callback | `[ ]` |
| T-04-04-06 Add duplicate name validation | `[ ]` |
| T-04-04-07 Add `prevent_if_ordered` before_destroy | `[ ]` |
| T-04-04-08 Include `SoftDeletable` | `[ ]` |
| T-04-04-09 Implement `last_price_for` class method | `[ ]` |
| T-04-04-10 Implement `ProductsController` CRUD | `[ ]` |
| T-04-04-11 Implement `parent` action | `[ ]` |
| T-04-04-12 Implement `child` action | `[ ]` |
| T-04-04-13 Implement `advance_search` action | `[ ]` |
| T-04-04-14 Implement `last_price` action | `[ ]` |
| T-04-04-15 Implement `filters` action | `[ ]` |
| T-04-04-16 Implement `ChildProductsController` | `[ ]` |
| T-04-04-17 Build Product list view | `[ ]` |
| T-04-04-18 Build Product form with dynamic attributes | `[ ]` |
| T-04-04-19 Enforce `can_view_cost` in serialiser | `[ ]` |
| T-04-04-20 Add `ProductPolicy` | `[ ]` |
| T-04-04-21 Write RSpec model specs | `[ ]` |
| T-04-04-22 Write RSpec request specs | `[ ]` |

### STORY-04-05 — Product Image Management 🔴
| Task | Status |
|---|---|
| T-04-05-01 Generate `ProductImage` model | `[ ]` |
| T-04-05-02 Add Active Storage attachments | `[ ]` |
| T-04-05-03 Implement `ImageCompressible` concern | `[ ]` |
| T-04-05-04 Include `ImageCompressible` in `ProductImage` | `[ ]` |
| T-04-05-05 Implement `ProductImagesController` | `[ ]` |
| T-04-05-06 Build image upload UI | `[ ]` |
| T-04-05-07 Add `ProductImagePolicy` | `[ ]` |
| T-04-05-08 Add `featured_image` to `Product` | `[ ]` |
| T-04-05-09 Write RSpec specs | `[ ]` |

---

## EPIC-05 — Stock Management Module
**Status:** 🔴 Not Started | [Full details](./EPIC-05/stories.md)

### STORY-05-01 — Branch Setup 🔴
| Task | Status |
|---|---|
| T-05-01-01 Generate `Branch` model | `[ ]` |
| T-05-01-02 Add presence / uniqueness validations | `[ ]` |
| T-05-01-03 Implement `BranchesController` | `[ ]` |
| T-05-01-04 Build Branch views | `[ ]` |
| T-05-01-05 Add `BranchPolicy` | `[ ]` |
| T-05-01-06 Add `Branch.default` class method | `[ ]` |
| T-05-01-07 Seed default branch | `[ ]` |
| T-05-01-08 Write RSpec specs | `[ ]` |

### STORY-05-02 — Product Stock Tracking 🔴
| Task | Status |
|---|---|
| T-05-02-01 Generate `ProductStock` model | `[ ]` |
| T-05-02-02 Add unique index (branch_id, product_id) | `[ ]` |
| T-05-02-03 Add associations | `[ ]` |
| T-05-02-04 Implement `total_amount` getter | `[ ]` |
| T-05-02-05 Implement `find_or_create_for!` class method | `[ ]` |
| T-05-02-06 Implement `deposit!` method | `[ ]` |
| T-05-02-07 Implement `withdraw!` method | `[ ]` |
| T-05-02-08 Implement `withdraw_from_holding!` method | `[ ]` |
| T-05-02-09 Implement `StocksController` index/show | `[ ]` |
| T-05-02-10 Add deposit / withdraw member actions | `[ ]` |
| T-05-02-11 Build Stock list view | `[ ]` |
| T-05-02-12 Build Stock detail view | `[ ]` |
| T-05-02-13 Add `StockPolicy` | `[ ]` |
| T-05-02-14 Write RSpec model specs | `[ ]` |
| T-05-02-15 Write RSpec request specs | `[ ]` |

### STORY-05-03 — Stock Transaction Ledger & Checkpoint 🔴
| Task | Status |
|---|---|
| T-05-03-01 Generate `ProductStockTransaction` model | `[ ]` |
| T-05-03-02 Add associations (polymorphic) | `[ ]` |
| T-05-03-03 Add validations | `[ ]` |
| T-05-03-04 Implement `recalculate_checkpoint!` | `[ ]` |
| T-05-03-05 Add `recalculate_checkpoint` member action | `[ ]` |
| T-05-03-06 Add `transactions` member action | `[ ]` |
| T-05-03-07 Build transaction list view | `[ ]` |
| T-05-03-08 Write RSpec model specs | `[ ]` |
| T-05-03-09 Write RSpec request specs | `[ ]` |

---

## EPIC-06 — Order Module (Core)
**Status:** 🔴 Not Started | [Full details](./EPIC-06/stories.md)

### STORY-06-01 — Order Model & Number Generation 🔴
| Task | Status |
|---|---|
| T-06-01-01 Generate `Order` model | `[ ]` |
| T-06-01-02 Add FK to logistic_companies (nullify) | `[ ]` |
| T-06-01-03 Add FK to customers (cascade) | `[ ]` |
| T-06-01-04 Add FKs for created_by / updated_by | `[ ]` |
| T-06-01-05 Add status and logistic_status enums | `[ ]` |
| T-06-01-06 Set up `Current` attributes | `[ ]` |
| T-06-01-07 Add created_by / updated_by callbacks | `[ ]` |
| T-06-01-08 Implement `OrderNumberGenerator` service | `[ ]` |
| T-06-01-09 Add `before_create :generate_order_number` | `[ ]` |
| T-06-01-10 Set default `running_date` | `[ ]` |
| T-06-01-11 Write `OrderNumberGenerator` RSpec specs | `[ ]` |
| T-06-01-12 Write Order model specs | `[ ]` |

### STORY-06-02 — Grand Total Calculation 🔴
| Task | Status |
|---|---|
| T-06-02-01 Implement `GrandTotalCalculator` service | `[ ]` |
| T-06-02-02 Step 1: total_price | `[ ]` |
| T-06-02-03 Step 2: discount_amount | `[ ]` |
| T-06-02-04 Step 3: price_with_discount | `[ ]` |
| T-06-02-05 Step 4: price_excl_vat | `[ ]` |
| T-06-02-06 Step 5: vat_price | `[ ]` |
| T-06-02-07 Step 6: withholding_tax_amount | `[ ]` |
| T-06-02-08 Step 7: grand_total | `[ ]` |
| T-06-02-09 Apply BigDecimal half-up rounding | `[ ]` |
| T-06-02-10 Add `recalculate_grand_total!` on Order | `[ ]` |
| T-06-02-11 Write RSpec specs for all 8 combinations | `[ ]` |

### STORY-06-03 — Order CRUD & Status Management 🔴
| Task | Status |
|---|---|
| T-06-03-01 Implement `OrdersController` CRUD | `[ ]` |
| T-06-03-02 Add filtered list actions (draft/paid/etc) | `[ ]` |
| T-06-03-03 Implement `dashboard` action | `[ ]` |
| T-06-03-04 Implement `advance_search` action | `[ ]` |
| T-06-03-05 Implement `POST /filter` action | `[ ]` |
| T-06-03-06 Build Order list with status tab bar | `[ ]` |
| T-06-03-07 Build Order detail view | `[ ]` |
| T-06-03-08 Build Order new/edit form | `[ ]` |
| T-06-03-09 Display status badges with colours | `[ ]` |
| T-06-03-10 Add `OrderPolicy` | `[ ]` |
| T-06-03-11 Add API routes | `[ ]` |
| T-06-03-12 Write RSpec request specs | `[ ]` |

### STORY-06-04 — Order Lines Management 🔴
| Task | Status |
|---|---|
| T-06-04-01 Generate `OrderLine` model | `[ ]` |
| T-06-04-02 Add after_*_commit callbacks → recalculate | `[ ]` |
| T-06-04-03 Implement `total_price` before_save logic | `[ ]` |
| T-06-04-04 Accept nested order_lines in Order | `[ ]` |
| T-06-04-05 Implement `OrderLinesController` | `[ ]` |
| T-06-04-06 Build inline order line editor (Stimulus) | `[ ]` |
| T-06-04-07 Turbo Stream: broadcast grand total update | `[ ]` |
| T-06-04-08 Add dynamic "Add Line" button | `[ ]` |
| T-06-04-09 Add `OrderLinePolicy` | `[ ]` |
| T-06-04-10 Write RSpec model specs | `[ ]` |
| T-06-04-11 Write RSpec request specs | `[ ]` |

### STORY-06-05 — Order Line Stock Integration 🔴
| Task | Status |
|---|---|
| T-06-05-01 Add `handle_stock_on_create` callback | `[ ]` |
| T-06-05-02 Add `handle_stock_on_update` callback | `[ ]` |
| T-06-05-03 Add `handle_stock_on_destroy` callback | `[ ]` |
| T-06-05-04 Skip callbacks when `enable_stock: false` | `[ ]` |
| T-06-05-05 Write RSpec model specs | `[ ]` |
| T-06-05-06 Write RSpec integration spec | `[ ]` |

### STORY-06-06 — Bulk Status Update & Order Images 🔴
| Task | Status |
|---|---|
| T-06-06-01 Implement `bulk_update_status` action | `[ ]` |
| T-06-06-02 Validate mutual exclusivity | `[ ]` |
| T-06-06-03 Implement IDs path | `[ ]` |
| T-06-06-04 Implement select-all path | `[ ]` |
| T-06-06-05 Build bulk selection UI | `[ ]` |
| T-06-06-06 Generate `OrderImage` model | `[ ]` |
| T-06-06-07 Include `ImageCompressible` in OrderImage | `[ ]` |
| T-06-06-08 Implement `OrderImagesController` | `[ ]` |
| T-06-06-09 Add `OrderImagePolicy` | `[ ]` |
| T-06-06-10 Write RSpec request specs | `[ ]` |

---

## EPIC-07 — Excel Export & Reporting Module
**Status:** 🔴 Not Started | [Full details](./EPIC-07/stories.md)

### STORY-07-01 — Order Invoice Excel Export (Secured) 🔴
| Task | Status |
|---|---|
| T-07-01-01 Implement `OrderExcelService#build` | `[ ]` |
| T-07-01-02 Apply monetary cell formatting | `[ ]` |
| T-07-01-03 Add authenticated `GET /orders/:id/export` | `[ ]` |
| T-07-01-04 Implement signed URL generation | `[ ]` |
| T-07-01-05 Implement `GET /orders/download?token` | `[ ]` |
| T-07-01-06 Return 403 for expired / tampered token | `[ ]` |
| T-07-01-07 Add Export button on Order detail view | `[ ]` |
| T-07-01-08 Write RSpec service spec | `[ ]` |
| T-07-01-09 Write RSpec request specs | `[ ]` |

### STORY-07-02 — Combined Bills Export 🔴
| Task | Status |
|---|---|
| T-07-02-01 Implement `CombinedBillsService#build` | `[ ]` |
| T-07-02-02 Validate same-customer constraint | `[ ]` |
| T-07-02-03 Implement `POST /orders/combine_bills` | `[ ]` |
| T-07-02-04 Set UTF-8 encoded filename header | `[ ]` |
| T-07-02-05 Add Combine Bills UI action | `[ ]` |
| T-07-02-06 Write RSpec service spec | `[ ]` |
| T-07-02-07 Write RSpec request spec | `[ ]` |

### STORY-07-03 — Customer & Sales Summary Reports 🔴
| Task | Status |
|---|---|
| T-07-03-01 Implement `CustomerReportService#build` | `[ ]` |
| T-07-03-02 Generate Customer Report Excel | `[ ]` |
| T-07-03-03 Implement customer report endpoint | `[ ]` |
| T-07-03-04 Implement `SalesReportService#build` | `[ ]` |
| T-07-03-05 Generate Sales Report Excel | `[ ]` |
| T-07-03-06 Implement sales report endpoint | `[ ]` |
| T-07-03-07 Gate behind `see_sale_graph` Pundit policy | `[ ]` |
| T-07-03-08 Build reporting UI on dashboard | `[ ]` |
| T-07-03-09 Write RSpec service specs | `[ ]` |
| T-07-03-10 Write RSpec request specs | `[ ]` |

### STORY-07-04 — Sales Graph 🔴
| Task | Status |
|---|---|
| T-07-04-01 Implement `SalesGraphService#call` | `[ ]` |
| T-07-04-02 Implement `report_order` endpoint | `[ ]` |
| T-07-04-03 Gate behind `see_sale_graph` policy | `[ ]` |
| T-07-04-04 Add Chartkick bar chart to Dashboard | `[ ]` |
| T-07-04-05 Configure Groupdate for empty months | `[ ]` |
| T-07-04-06 Write RSpec service spec | `[ ]` |
| T-07-04-07 Write RSpec request spec | `[ ]` |

---

## EPIC-08 — Bulk Product Import Module
**Status:** 🔴 Not Started | [Full details](./EPIC-08/stories.md)

### STORY-08-01 — File Upload Infrastructure 🔴
| Task | Status |
|---|---|
| T-08-01-01 Generate `Upload` model | `[ ]` |
| T-08-01-02 Add `status` column | `[ ]` |
| T-08-01-03 Add `result_summary:jsonb` column | `[ ]` |
| T-08-01-04 Implement `UploadsController#create` | `[ ]` |
| T-08-01-05 Enqueue `BulkProductImportJob` on upload | `[ ]` |
| T-08-01-06 Build Upload UI | `[ ]` |
| T-08-01-07 Build Upload history list view | `[ ]` |
| T-08-01-08 Add Uploads to Catalog sidebar | `[ ]` |
| T-08-01-09 Add `UploadPolicy` | `[ ]` |
| T-08-01-10 Write RSpec request specs | `[ ]` |

### STORY-08-02 — Bulk Product Import Job 🔴
| Task | Status |
|---|---|
| T-08-02-01 Implement `BulkProductImportJob` | `[ ]` |
| T-08-02-02 Update status to `processing` on start | `[ ]` |
| T-08-02-03 Open file with `roo` | `[ ]` |
| T-08-02-04 Map sheet name → ProductClass | `[ ]` |
| T-08-02-05 Map required columns per row | `[ ]` |
| T-08-02-06 Handle `attr` prefix columns | `[ ]` |
| T-08-02-07 Upsert Vendor | `[ ]` |
| T-08-02-08 Upsert Brand | `[ ]` |
| T-08-02-09 Upsert ProductCategory | `[ ]` |
| T-08-02-10 Upsert Standalone/Parent products | `[ ]` |
| T-08-02-11 Link Child products to parent by index | `[ ]` |
| T-08-02-12 Default missing numeric values to 0 | `[ ]` |
| T-08-02-13 Track processed/failed counters | `[ ]` |
| T-08-02-14 Update status to `completed` on finish | `[ ]` |
| T-08-02-15 Handle exceptions → status `failed` | `[ ]` |
| T-08-02-16 Write RSpec job spec with fixture xlsx | `[ ]` |
| T-08-02-17 Write edge-case specs | `[ ]` |

### STORY-08-03 — Import Status Notifications 🔴
| Task | Status |
|---|---|
| T-08-03-01 Configure Action Cable with Redis | `[ ]` |
| T-08-03-02 Create `ImportNotificationsChannel` | `[ ]` |
| T-08-03-03 Broadcast Turbo Stream on job completion | `[ ]` |
| T-08-03-04 Add `user_id` FK to `Upload` | `[ ]` |
| T-08-03-05 Wire Action Cable in Upload history view | `[ ]` |
| T-08-03-06 Display completion banner notification | `[ ]` |
| T-08-03-07 Write RSpec job spec for broadcast | `[ ]` |

---

## EPIC-09 — Polish, API Docs & Deployment Prep
**Status:** 🔴 Not Started | [Full details](./EPIC-09/stories.md)

### STORY-09-01 — API Documentation (rswag) 🔴
| Task | Status |
|---|---|
| T-09-01-01 Run `rails generate rswag:install` | `[ ]` |
| T-09-01-02 rswag spec: Auth endpoints | `[ ]` |
| T-09-01-03 rswag spec: User and Profile endpoints | `[ ]` |
| T-09-01-04 rswag spec: Role / Group / Permission endpoints | `[ ]` |
| T-09-01-05 rswag spec: Vendor, Brand, ProductClass, Category | `[ ]` |
| T-09-01-06 rswag spec: Product endpoints | `[ ]` |
| T-09-01-07 rswag spec: Stock endpoints | `[ ]` |
| T-09-01-08 rswag spec: Customer and LogisticCompany | `[ ]` |
| T-09-01-09 rswag spec: Order endpoints | `[ ]` |
| T-09-01-10 rswag spec: Upload and Country | `[ ]` |
| T-09-01-11 Run `rswag:specs:swaggerize` | `[ ]` |
| T-09-01-12 Mount Rswag engines in routes | `[ ]` |
| T-09-01-13 Verify Swagger UI at `/api-docs` | `[ ]` |

### STORY-09-02 — Test Coverage & Code Quality 🔴
| Task | Status |
|---|---|
| T-09-02-01 Configure SimpleCov (90% minimum) | `[ ]` |
| T-09-02-02 Run full RSpec suite | `[ ]` |
| T-09-02-03 Fix all failing specs | `[ ]` |
| T-09-02-04 Review coverage; write missing specs | `[ ]` |
| T-09-02-05 Cover all 8 grand total combinations | `[ ]` |
| T-09-02-06 Cover stock edge cases | `[ ]` |
| T-09-02-07 Cover signed URL expiry | `[ ]` |
| T-09-02-08 Run `bundle exec rubocop` | `[ ]` |
| T-09-02-09 Auto-fix RuboCop offences | `[ ]` |
| T-09-02-10 Manually fix remaining offences | `[ ]` |
| T-09-02-11 Add CI workflow (rspec + rubocop) | `[ ]` |

### STORY-09-03 — DB Indexes, Seeds & Production Config 🔴
| Task | Status |
|---|---|
| T-09-03-01 Audit all FK index coverage | `[ ]` |
| T-09-03-02 Verify `order_number` unique index | `[ ]` |
| T-09-03-03 Verify `products.sku` unique index | `[ ]` |
| T-09-03-04 Verify `product_stocks` unique index | `[ ]` |
| T-09-03-05 Add index on `orders.running_date` | `[ ]` |
| T-09-03-06 Add index on `orders.status` / `logistic_status` | `[ ]` |
| T-09-03-07 Add index on `customers.deleted_at` | `[ ]` |
| T-09-03-08 Configure `production.rb` | `[ ]` |
| T-09-03-09 Configure S3 Active Storage for production | `[ ]` |
| T-09-03-10 Write `db/seeds.rb` orchestrator | `[ ]` |
| T-09-03-11 Ensure seeds are idempotent | `[ ]` |
| T-09-03-12 Write `README.md` | `[ ]` |
| T-09-03-13 Final security checklist review | `[ ]` |
| T-09-03-14 Verify `rails db:seed` on fresh DB | `[ ]` |
