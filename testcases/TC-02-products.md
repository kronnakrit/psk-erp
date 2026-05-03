# TC-02 — Product Catalog Module
**Module:** Products, Vendors, Brands, Product Classes, Product Categories, Product Attributes, Product Images, Unit Groups  
**Based on:** EPIC-04, EPIC-15

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-02-01 — Vendor Management

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-01-01 | Create vendor with unique name | Admin logged in | 1. Navigate to `/vendors/new`<br>2. Enter name, telephone, address<br>3. Submit | Vendor created; `initial_name` auto-generated as `"{name}-{id}"` | ⏳ |
| TC-02-01-02 | Create vendor with duplicate name | Vendor with same name exists | 1. Submit form with duplicate name | 422; validation error "Name has already been taken" | ⏳ |
| TC-02-01-03 | `initial_name` auto-generation | New vendor, no initial_name entered | 1. Create vendor without setting initial_name | `initial_name` auto-set to `"{name}-{id}"` after save | ⏳ |
| TC-02-01-04 | Edit vendor | Vendor exists | 1. Navigate to `/vendors/:id/edit`<br>2. Change address<br>3. Submit | Vendor updated; changes saved | ⏳ |
| TC-02-01-05 | Delete vendor not linked to products | Vendor with no products | 1. Delete vendor | Vendor deleted; no longer in list | ⏳ |
| TC-02-01-06 | Search vendors by name | Multiple vendors exist | 1. Use search bar with partial name | Only matching vendors returned | ⏳ |

---

## TC-02-02 — Brand Management

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-02-01 | Create brand | Admin logged in | 1. Navigate to `/brands/new`<br>2. Enter name<br>3. Submit | Brand created and appears in list | ⏳ |
| TC-02-02-02 | Edit brand | Brand exists | 1. Edit name/description<br>2. Submit | Brand updated | ⏳ |
| TC-02-02-03 | Delete brand not linked to products | Brand with no products | 1. Delete brand | Brand removed | ⏳ |

---

## TC-02-03 — Product Class & Category Management

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-03-01 | Create product class | Admin logged in | 1. Navigate to `/product_classes/new`<br>2. Enter name<br>3. Submit | Product class created | ⏳ |
| TC-02-03-02 | Create product category | Admin logged in | 1. Navigate to `/product_categories/new`<br>2. Enter name<br>3. Submit | Category created | ⏳ |
| TC-02-03-03 | Attributes auto-load when product class selected | Product class with attributes exists | 1. Open product form<br>2. Select a product class from dropdown | Custom attribute fields for that class appear dynamically | ⏳ |
| TC-02-03-04 | API categories endpoint requires no auth | — | 1. GET `/api/v1/catalogs/list_product_categories` without token | Response 200; categories list returned | ⏳ |

---

## TC-02-04 — Product CRUD (Core)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-04-01 | Create Standalone product | Admin logged in; vendor, brand, product class exist | 1. Navigate to `/products/new`<br>2. Fill name, type=Standalone, select vendor<br>3. Submit | Product created; SKU auto-generated as `"{vendor.initial_name}{timestamp}"` | ⏳ |
| TC-02-04-02 | Create Parent product | Admin logged in | 1. Create product with type=Parent | Product type stored as `"Pr"`; appears as parent row in list | ⏳ |
| TC-02-04-03 | Create Child product linked to parent | Parent product exists | 1. Create product with type=Child<br>2. Select parent | Child linked to parent; appears nested in product list under parent | ⏳ |
| TC-02-04-04 | SKU auto-generated from vendor initial_name | Vendor with `initial_name` exists | 1. Create product with that vendor; leave SKU blank | SKU = `"{initial_name}{epoch}"` | ⏳ |
| TC-02-04-05 | Barcode auto-generated when blank | New product | 1. Create product without entering barcode | Barcode auto-set to epoch timestamp string | ⏳ |
| TC-02-04-06 | Duplicate name rejected for Standalone/Parent | Product with same name exists (Standalone) | 1. Create another Standalone with same name | 422; "Name has already been taken" | ⏳ |
| TC-02-04-07 | Child product can share name with parent | Parent product exists | 1. Create child product with same name as parent | Validation passes; product saved | ⏳ |
| TC-02-04-08 | Edit product | Product exists | 1. Navigate to `/products/:id/edit`<br>2. Change name, price<br>3. Submit | Product updated | ⏳ |
| TC-02-04-09 | Soft delete product | Product with no active orders | 1. Delete product via UI | Product removed from default list; accessible via deleted scope | ⏳ |
| TC-02-04-10 | Cannot delete product referenced by order line | Product linked to order line | 1. Attempt to delete product | 409 conflict; delete blocked | ⏳ |
| TC-02-04-11 | Cost field hidden without permission | User without `can_view_cost` | 1. View product detail page | `cost` field absent from HTML | ⏳ |
| TC-02-04-12 | Cost field visible with permission | User with `can_view_cost` | 1. View product detail page | `cost` field rendered with value | ⏳ |
| TC-02-04-13 | Assign product to multiple categories | Categories exist | 1. Check multiple categories in product form<br>2. Submit | Product saved with all selected categories | ⏳ |

---

## TC-02-05 — Product Unit Group Integration (EPIC-15)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-05-01 | Assign unit group to product | Unit groups exist | 1. Open product edit form<br>2. Select unit group from dropdown<br>3. Submit | Product `unit_group_id` saved; unit group name shows in product list and detail | ⏳ |
| TC-02-05-02 | Clear unit group from product | Product has unit group | 1. Edit product<br>2. Select "— none —" from unit group dropdown<br>3. Submit | `unit_group_id` set to null | ⏳ |
| TC-02-05-03 | Effective unit group falls back to default | Product has no unit group; default unit group exists | 1. Check effective unit group for product | Returns the default unit group | ⏳ |
| TC-02-05-04 | Unit group name shown in product index | Product with unit group | 1. Navigate to `/products` | "กลุ่มหน่วย" column shows unit group name; "—" if not set | ⏳ |
| TC-02-05-05 | Unit definitions available via API | Product with unit group containing definitions | 1. GET `/api/v1/catalogs/products` | Response includes `unit_definitions` array with `id`, `name`, `ratio` per product | ⏳ |
| TC-02-05-06 | Unit text column removed | Any product | 1. Inspect product form | No "หน่วย" text input field present | ⏳ |

---

## TC-02-06 — Product Search & Advanced Search

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-06-01 | Search by product name | Products exist | 1. Enter partial name in search bar<br>2. Submit | Only products with matching name shown | ⏳ |
| TC-02-06-02 | Search by SKU | Products exist | 1. Enter SKU in search bar | Product with matching SKU returned | ⏳ |
| TC-02-06-03 | Filter products with stock (`has_stock=true`) | Products with `enable_stock=true` and stock > 0 | 1. GET `/api/v1/catalogs/products?has_stock=true` | Only products with `enable_stock: true` AND non-zero stock returned | ⏳ |
| TC-02-06-04 | Advance search by vendor | Multiple products with different vendors | 1. Select vendor filter<br>2. Submit | Only products from selected vendor shown | ⏳ |
| TC-02-06-05 | `last_price` endpoint | Product has previous order lines for customer | 1. GET `/api/v1/catalogs/products/:id/last_price?customer_id=X` | Returns most recent unit_price from order lines for that product/customer combo | ⏳ |
| TC-02-06-06 | `last_price` fallback to product.price | No prior orders for product/customer | 1. GET last_price for product with no order history | Returns `product.price` | ⏳ |

---

## TC-02-07 — Product Images

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-07-01 | Upload product image | Product exists | 1. Open product detail<br>2. Upload image file | Image attached; thumbnail auto-generated at quality 20 | ⏳ |
| TC-02-07-02 | Multiple images per product | Product exists | 1. Upload multiple images | All images attached and visible in product gallery | ⏳ |
| TC-02-07-03 | Delete product image | Image attached | 1. Click delete on image | Image removed from Active Storage | ⏳ |
| TC-02-07-04 | Featured image displayed in product list | Product has featured image | 1. Navigate to `/products` | Product thumbnail shown in product list row | ⏳ |

---

## TC-02-08 — Bulk Product Import (EPIC-08)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-02-08-01 | Upload valid .xlsx file | Admin logged in | 1. Navigate to `/uploads/new`<br>2. Select valid `.xlsx` file<br>3. Submit | File stored; SolidQueue job enqueued; success message shown | ⏳ |
| TC-02-08-02 | Upload non-.xlsx file | Admin logged in | 1. Try to upload `.csv` or `.pdf` file | 422; validation error "must be .xlsx" | ⏳ |
| TC-02-08-03 | Import job creates products from sheet | Valid xlsx with product data | 1. Import job runs | Products created/updated per sheet data; vendor/brand/category upserted | ⏳ |
| TC-02-08-04 | Import real-time notification | User on upload page | 1. Trigger import job | Turbo Stream notification appears without page reload when job completes | ⏳ |
| TC-02-08-05 | Child products linked to parent in sheet | xlsx has parent then child rows | 1. Import runs | Child product `parent_id` set to most recent parent row in same sheet | ⏳ |
