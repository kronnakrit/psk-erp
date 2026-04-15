# EPIC-04 — Product Catalog Module

**Phase:** 4  
**Status:** 🟢 Completed  
**Goal:** Complete product catalogue with vendor (SKU prefix), brand, product class, product category, custom attributes, and products supporting parent/child hierarchy. Cost field hidden for unauthorised users.

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

### STORY-04-01 — Vendor & Brand Management
**Status:** 🟢 Completed  
**Description:** Full CRUD for Vendor (with `initial_name` auto-generation) and Brand. Vendor `initial_name` used as product SKU prefix. Batch-generate missing `initial_name` values via admin action.

| # | Task | Status |
|---|---|---|
| T-04-01-01 | Generate `Vendor` model: `name:string` (unique), `initial_name:string` (unique), `description:text`, `address:text`, `remark:text`, `telephone:string`, timestamps | `[x]` |
| T-04-01-02 | Add `before_save :auto_set_initial_name` on `Vendor`: sets `"#{name}-#{id}"` when `initial_name` is blank (runs after id is assigned on create) | `[x]` |
| T-04-01-03 | Add validations: presence and uniqueness of `name`; uniqueness of `initial_name` when present | `[x]` |
| T-04-01-04 | Implement `VendorsController` with full CRUD | `[~]` |
| T-04-01-05 | Add `POST /vendors/initialize_names` collection action: batch-sets `initial_name` for all vendors where it is nil | `[ ]` |
| T-04-01-06 | Add Ransack search on `name`, `remark`, `telephone`, `address`, `initial_name` | `[x]` |
| T-04-01-07 | Build Vendor list and form views with Railsblocks | `[x]` |
| T-04-01-08 | Generate `Brand` model: `name:string`, `description:text`, `remark:text`, timestamps | `[x]` |
| T-04-01-09 | Implement `BrandsController` with full CRUD; Ransack search on `name`, `remark` | `[x]` |
| T-04-01-10 | Build Brand list and form views with Railsblocks | `[x]` |
| T-04-01-11 | Add `VendorPolicy` and `BrandPolicy` with standard Pundit predicates | `[x]` |
| T-04-01-12 | Write RSpec model specs for Vendor (auto_set_initial_name callback) and Brand | `[x]` |
| T-04-01-13 | Write RSpec request specs for Vendor CRUD and `initialize_names` action | `[x]` |

---

### STORY-04-02 — Product Class & Category Management
**Status:** 🟢 Completed  
**Description:** Full CRUD for ProductClass and ProductCategory. ProductCategory also exposes an unpaginated endpoint for dropdown population.

| # | Task | Status |
|---|---|---|
| T-04-02-01 | Generate `ProductClass` model: `name:string`, timestamps | `[ ]` |
| T-04-02-02 | Implement `ProductClassesController` with full CRUD | `[ ]` |
| T-04-02-03 | Build ProductClass list and form views | `[ ]` |
| T-04-02-04 | Generate `ProductCategory` model: `name:string`, timestamps | `[ ]` |
| T-04-02-05 | Implement `ProductCategoriesController` with full CRUD and Ransack search on `name` | `[ ]` |
| T-04-02-06 | Add `GET /api/v1/catalogs/list_product_categories` — unpaginated, returns all categories (no auth required for this read-only endpoint) | `[ ]` |
| T-04-02-07 | Build ProductCategory list and form views | `[ ]` |
| T-04-02-08 | Add `ProductClassPolicy` and `ProductCategoryPolicy` | `[ ]` |
| T-04-02-09 | Write RSpec model and request specs | `[ ]` |

---

### STORY-04-03 — Attribute System
**Status:** 🟡 In Progress  
**Description:** Attributes are custom fields tied to a ProductClass (e.g. "Color" for class "Clothing"). ProductAttributes link an attribute value to a specific product.

| # | Task | Status |
|---|---|---|
| T-04-03-01 | Generate `Attribute` model: `name:string`, `product_class_id:bigint` FK, timestamps | `[ ]` |
| T-04-03-02 | Add unique index on `(name, product_class_id)` | `[ ]` |
| T-04-03-03 | Add `belongs_to :product_class` and `has_many :product_attributes` associations | `[ ]` |
| T-04-03-04 | Generate `ProductAttribute` model: `product_id:bigint` FK, `attribute_id:bigint` FK, `value:string`, timestamps | `[ ]` |
| T-04-03-05 | Add unique index on `(product_id, attribute_id)` | `[ ]` |
| T-04-03-06 | Implement `AttributesController` with full CRUD scoped to a product class | `[ ]` |
| T-04-03-07 | Implement `ProductAttributesController` with full CRUD | `[ ]` |
| T-04-03-08 | Add `AttributePolicy` and `ProductAttributePolicy` | `[ ]` |
| T-04-03-09 | Write RSpec model and request specs including uniqueness constraint tests | `[ ]` |

---

### STORY-04-04 — Product Core (CRUD & Business Logic)
**Status:** 🟢 Completed  
**Description:** Central product model with all fields, auto-generation of SKU/barcode, parent/child hierarchy, duplicate name validation, cost permission enforcement, last-price lookup, and advanced search.

| # | Task | Status |
|---|---|---|
| T-04-04-01 | Generate `Product` model with all columns per schema in §5.2 of new_requirement.md | `[x]` |
| T-04-04-02 | Set up join table `product_category_products` (product_id, product_category_id) | `[x]` |
| T-04-04-03 | Add all Product associations: `belongs_to :vendor, :brand, :product_class`; `has_and_belongs_to_many :product_categories`; `belongs_to :parent, optional: true`; `has_many :children, dependent: :destroy` | `[x]` |
| T-04-04-04 | Add `before_validation :auto_generate_sku`: build `"#{vendor.initial_name}#{Time.now.to_i}"` when `sku` is blank | `[x]` |
| T-04-04-05 | Add `before_validation :auto_generate_barcode`: use `Time.now.to_i.to_s` when `barcode` is blank | `[x]` |
| T-04-04-06 | Add `validate :unique_name_for_non_child` to reject duplicate names among Standalone and Parent products | `[x]` |
| T-04-04-07 | Add `before_destroy :prevent_if_ordered` raising `409` if any `OrderLine` references this product | `[x]` |
| T-04-04-08 | Add `SoftDeletable` concern to `Product` | `[x]` |
| T-04-04-09 | Implement `Product.last_price_for(product_id:, customer_id:)` class method: queries most recent order line for that combination; falls back to `product.price` | `[x]` |
| T-04-04-10 | Implement `ProductsController` with `index` (Sa + Pr only), `show`, `new`, `create`, `edit`, `update`, `destroy` | `[x]` |
| T-04-04-11 | Implement `parent` action: returns all children of the given parent product | `[x]` |
| T-04-04-12 | Implement `child` action: returns full detail of a child product | `[x]` |
| T-04-04-13 | Implement `advance_search` action using Ransack with all fields listed in §5.6 | `[x]` |
| T-04-04-14 | Implement `last_price` action calling `Product.last_price_for` | `[x]` |
| T-04-04-15 | Implement `filters` action: when `has_stock=true`, return only products with `enable_stock: true` and non-zero stock | `[x]` |
| T-04-04-16 | Implement `ChildProductsController` with `update` (PUT only) and `destroy` | `[x]` |
| T-04-04-17 | Build Product list view with Railsblocks table (Standalone + Parent rows; expand children in nested turbo frame) | `[x]` |
| T-04-04-18 | Build Product new/edit form with dynamic attribute fields driven by Stimulus (loads attributes when product_class changes) | `[x]` |
| T-04-04-19 | Enforce `can_view_cost` in `ProductPolicy#can_view_cost?`; exclude `cost` from serialiser/view when false | `[x]` |
| T-04-04-20 | Add `ProductPolicy` with all standard and custom predicates | `[x]` |
| T-04-04-21 | Write RSpec model specs: SKU/barcode generation, duplicate name validation, `last_price_for`, soft delete | `[x]` |
| T-04-04-22 | Write RSpec request specs: CRUD, advance search, last price, filters, cost-hidden scenario | `[x]` |

---

### STORY-04-05 — Product Image Management
**Status:** 🟢 Completed  
**Description:** Products can have multiple images. Each image has a compressed thumbnail auto-generated via Active Storage variants at quality 20.

| # | Task | Status |
|---|---|---|
| T-04-05-01 | Generate `ProductImage` model: `product_id:bigint` FK, timestamps | `[x]` |
| T-04-05-02 | Add Active Storage `has_one_attached :image` and `has_one_attached :thumb_image` to `ProductImage` | `[x]` |
| T-04-05-03 | Implement `ImageCompressible` concern: `after_create :generate_thumbnail` using Active Storage variant with `quality: 20` | `[x]` |
| T-04-05-04 | Include `ImageCompressible` in `ProductImage` | `[x]` |
| T-04-05-05 | Implement `ProductImagesController` with full CRUD | `[x]` |
| T-04-05-06 | Build image upload UI within Product detail view (drag-and-drop using Stimulus) | `[x]` |
| T-04-05-07 | Add `ProductImagePolicy` | `[x]` |
| T-04-05-08 | Also add `has_one_attached :featured_image` to `Product` with default placeholder | `[x]` |
| T-04-05-09 | Write RSpec specs: image upload, thumbnail generation | `[x]` |
