# Wholesales System — Functional Requirements

> This document captures all business logic, data models, API behaviours, and system rules derived from a thorough code analysis of the existing project. It is tech-stack‑agnostic and intended as the single source of truth for rebuilding the system from scratch.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Domain Model](#2-domain-model)
3. [Authentication & User Management](#3-authentication--user-management)
4. [Role & Permission System](#4-role--permission-system)
5. [Product Catalog Module](#5-product-catalog-module)
6. [Stock Management Module](#6-stock-management-module)
7. [Customer Module](#7-customer-module)
8. [Logistic Module](#8-logistic-module)
9. [Order Module](#9-order-module)
10. [Reporting & Analytics Module](#10-reporting--analytics-module)
11. [File Upload Module](#11-file-upload-module)
12. [Country Module](#12-country-module)
13. [API Design Rules](#13-api-design-rules)
14. [System-Wide Business Rules](#14-system-wide-business-rules)

---

## 1. System Overview

The system is a **wholesale order management platform** for a retail/wholesale business (PSK Baby). It allows staff to manage products, customers, orders, inventory, logistics, and reporting. The business operates with multi-branch stock support (currently one branch, architecturally designed to scale to more).

**Core capabilities:**
- Product catalogue management with parent/child product hierarchies
- Real-time stock tracking per branch
- Sales order lifecycle management (Draft → Paid → Completed / Cancelled)
- Customer relationship management
- Logistics company assignment per order and customer
- Sales and customer reports exported as Excel spreadsheets
- Role-based access control down to the field level (e.g. hide cost price)
- JWT-based authentication API

---

## 2. Domain Model

### 2.1 Entity Relationship Overview

```
User ──────────── Profile
                     │
                   Role ──── Permissions (array of codenames)

Vendor ────────── Product ──── Brand
                     │            
                ProductClass     
                     │            
              ProductCategory (M2M)
                     │
              ProductAttribute ──── Attribute
                     │
              ProductImage(s)
                     │
              ProductStock (per Branch)
                     │
          ProductStockTransaction

Customer ─────── Country
    │
LogisticCompany

Order ──────────── Customer
    │                  │
    │              LogisticCompany (order-level override)
    │
  OrderLine ──── Product
    │
  OrderImage(s)
    │
  CreatedBy (User)
  UpdatedBy (User)
```

### 2.2 Base Model Behaviour

All entities inherit one or both of:

| Mixin | Fields | Behaviour |
|---|---|---|
| **TimestampedModel** | `created_at`, `updated_at` | Auto-managed; default ordering is most-recent first |
| **SoftDeletionModel** | `deleted_at` | Soft delete: sets `deleted_at` timestamp instead of removing the row. A custom manager filters out soft-deleted records. Hard delete is available via a `hard=True` flag. |
| **CompressImageModel** | `image`, `thumb_image` | On save, generates a compressed thumbnail at quality=20 stored as `thumb_{original_name}` |

---

## 3. Authentication & User Management

### 3.1 Authentication

- All API endpoints require authentication **except** the login/token endpoints.
- Authentication is token-based using **short-lived access tokens** and **refresh tokens**.
- Token endpoints:
  - `POST /api/v1/token/` — obtain access + refresh token pair (username + password)
  - `POST /api/v1/token/refresh/` — obtain a new access token using a refresh token
  - `POST /api/v1/api/token/verify/` — verify an access token

### 3.2 User Profile

Every authenticated user has exactly one **Profile** record (1:1 relationship).

| Field | Type | Notes |
|---|---|---|
| `first_name` | text | Staff member's first name |
| `last_name` | text | Staff member's last name |
| `address` | text | Optional |
| `remark` | text | Optional internal notes |
| `telephone` | string (max 255) | Optional |
| `user` | FK → auth user | One-to-one; the underlying login credential record |
| `role` | FK → Role | Nullable; must be set for permission control to work |

### 3.3 User Management API (`/api/v1/users/`)

| Action | Method | URL | Description |
|---|---|---|---|
| List / create users | GET / POST | `/users/users/` | Search by username, name, email, telephone, remark |
| Retrieve / update / delete user | GET / PUT / PATCH / DELETE | `/users/users/{id}/` | |
| Get own profile | GET | `/users/profile/` | Returns the currently authenticated user's profile |
| Update own profile | PUT | `/users/profile/` | Updates the authenticated user's own profile |
| Deactivate user | POST | `/users/users/{id}/deactivate/` | Sets `is_active = false` on the underlying auth user |
| Activate user | POST | `/users/users/{id}/activate/` | Sets `is_active = true` on the underlying auth user |
| Force set password | POST | `/users/force-password/{id}/` | Admin action; requires `password1` and `password2` fields to match |

---

## 4. Role & Permission System

### 4.1 Role Model

| Field | Type | Notes |
|---|---|---|
| `name` | text | Human-readable role label |
| `permissions` | array of strings | Codenames of granted permissions |
| `group` | FK → auth group | Maps to the system's native group/permission infrastructure |

### 4.2 Permission Enforcement

- All standard CRUD operations are protected by model-level permissions mapped to HTTP methods:
  - `GET` → `view_<model>`
  - `POST` → `add_<model>`
  - `PUT/PATCH` → `change_<model>`
  - `DELETE` → `delete_<model>`
- Two special custom permissions exist:
  - `can_view_cost` (on Product) — when a user lacks this permission, the product cost price must be hidden/excluded from the response.
  - `see_sale_graph` (on Order) — required to access sales graph/reporting endpoints.

### 4.3 Role API (`/api/v1/roles/`)

Three sub-resources are exposed:

| Resource | URL | Notes |
|---|---|---|
| Roles | `/roles/roles/` | Full CRUD. Search by name. |
| Groups | `/roles/groups/` | Full CRUD on native auth groups. Search by name. |
| Permissions | `/roles/permissions/` | Read-only list of all available permission codenames. Search by name. |

---

## 5. Product Catalog Module

### 5.1 Vendor

Represents the supplier of products.

| Field | Type | Notes |
|---|---|---|
| `name` | text (unique) | Vendor's full name |
| `initial_name` | text (unique) | Short code used to prefix SKUs; auto-generated as `{name}-{id}` if left blank |
| `description` | text | Optional |
| `address` | text | Optional |
| `remark` | text | Optional |
| `telephone` | text | Optional |

**Behaviours:**
- If `initial_name` is empty at save time, it is auto-set to `{name}-{id}`.
- `initial_name` is used as part of SKU generation.

**API endpoints (`/api/v1/catalogs/vendors/`):** Full CRUD. List search fields: `name`, `remark`, `telephone`, `address`, `initial_name`.  
Extra endpoint: `POST /api/v1/catalogs/initial-vendors/` — admin utility that batch-generates `initial_name` values for all vendors that are missing one. Returns `{ "detail": "initial vendor name success!" }`. This is a one-time migration action, not a data retrieval endpoint.

### 5.2 Brand

| Field | Type |
|---|---|
| `name` | text |
| `description` | text |
| `remark` | text |

**API endpoints (`/api/v1/catalogs/brands/`):** Full CRUD. List search fields: `name`, `remark`.

### 5.3 Product Class

A classification grouping (e.g. "clothing", "toys"). Also used as the Excel sheet name during bulk import.

| Field | Type |
|---|---|
| `name` | text |

**API endpoints (`/api/v1/catalogs/product_classes/`):** Full CRUD.

### 5.4 Product Category

A tagging/categorisation system (many-to-many with Product).

| Field | Type |
|---|---|
| `name` | text |

**API endpoints (`/api/v1/catalogs/product_categories/`):** Full CRUD. List search fields: `name`.

`GET /api/v1/catalogs/list-product-category/` — read-only, **no pagination**, returns all categories at once. Used when a full list is needed without paging (e.g. to populate a dropdown).

### 5.5 Attribute & Product Attribute

**Attribute** — defines a custom attribute column tied to a product class (e.g. "Color", "Size").

| Field | Type | Notes |
|---|---|---|
| `name` | text | |
| `product_class` | FK → ProductClass | |

**Constraint:** Unique together on (name, product_class).

**ProductAttribute** — links an attribute value to a specific product.

| Field | Type | Notes |
|---|---|---|
| `product` | FK → Product | |
| `attribute` | FK → Attribute | |
| `value` | text | |

**Constraint:** Unique together on (product, attribute) — a product cannot have the same attribute assigned twice.

**API endpoints (`/api/v1/catalogs/attributes/`, `/api/v1/catalogs/product_attributes/`):** Full CRUD.

### 5.6 Product

The central entity of the catalog.

| Field | Type | Notes |
|---|---|---|
| `sku` | text (unique) | Auto-generated if blank: `{vendor.initial_name}{unix_timestamp}` |
| `product_type` | enum | `Sa` = Standalone, `Pr` = Parent, `Ch` = Child |
| `barcode` | text | Auto-generated from unix timestamp if blank |
| `name` | text | |
| `description` | text | English description |
| `description_th` | text | Thai description |
| `unit` | text | Unit of measure |
| `price` | decimal (20,2) | Selling price |
| `cost` | decimal (20,2) | Cost price — access controlled by `can_view_cost` permission |
| `remark` | text | |
| `brand` | FK → Brand | |
| `product_class` | FK → ProductClass | |
| `product_categories` | M2M → ProductCategory | Note: the underlying DB column in the original codebase is misspelled as `product_catogories` — use the correct spelling `product_categories` in the new implementation |
| `vendor` | FK → Vendor | |
| `parent` | FK → Product (self) | Only set for `Ch` type products |
| `featured_image` | image | Default placeholder used if none provided |
| `enable_stock` | boolean | When true, stock levels are tracked and enforced |

**Product Types:**
- **Standalone (`Sa`)** — an independent product with no variants.
- **Parent (`Pr`)** — a product that has child variants (e.g. a shirt that comes in sizes).
- **Child (`Ch`)** — a variant of a parent product; inherits vendor, brand, and product class from the parent.

**Behaviours:**
- SKU is auto-generated on first save if blank.
- Barcode is auto-generated (unix timestamp) if blank.
- Deleting a Parent product cascades deletion to all its Child products.
- A product that has been ordered cannot be deleted (protected by the order line relationship).
- Duplicate name check: for Standalone and Parent types, duplicate names within those two types are rejected.
- **Last price lookup**: given a product and customer, returns the unit price from the most recent order line for that combination. Falls back to the product's current price if no history exists.

**API endpoints (`/api/v1/catalogs/`):**

| Action | Method | URL |
|---|---|---|
| List products | GET | `/products/` (Standalone + Parent only, paginated) |
| Retrieve product | GET | `/products/{id}/` |
| Create product | POST | `/products/` |
| Update product | PUT/PATCH | `/products/{id}/` |
| Delete product | DELETE | `/products/{id}/` |
| Get child products of parent | GET | `/products/{id}/parent/` |
| Get child product detail | GET | `/products/{id}/child/` |
| Advanced search | GET | `/advance-search/` (see filtering below) |
| Last price for customer | GET | `/product/{id}/last-price/{customer_id}/` |
| Filter products | GET | `/filters/` |
| Update child product | PUT | `/child-product/{id}/` | Only PUT and DELETE are allowed (no PATCH) |
| Delete child product | DELETE | `/child-product/{id}/` | |

**Advanced search filters:** `name`, `description_th`, `description`, `barcode`, `sku`, `unit`, `vendor`, `product_type`, `brand`, `product_category` — all case-insensitive partial matches.

**Standard search fields:** `name`, `sku`, `barcode`, `price`, `cost`.

**`/filters/` filter parameters:**

| Parameter | Type | Description |
|---|---|---|
| `has_stock` | boolean | When `true`, returns only products that have stock tracking enabled and a non-zero stock amount |

### 5.7 Product Image

| Field | Type | Notes |
|---|---|---|
| `image` | image | Stored at configured upload path |
| `thumb_image` | image | Auto-generated compressed thumbnail |
| `product` | FK → Product | |

**API endpoints (`/api/v1/catalogs/product_images/`):** Full CRUD.

### 5.8 Bulk Product Import (Excel)

`POST /api/v1/file-upload/` with a multipart Excel file.

**Import rules:**
- Each sheet name maps to a **ProductClass**.
- Required columns per row: `vendor`, `sku`, `brand`, `product_categories`, `product_type`, `barcode`, `name`, `unit`, `price`, `cost`, `description_en`, `description_th`.
- Columns prefixed with `attr` are treated as product attributes.
- If `product_type` is Standalone or Parent, a top-level product is created/updated.
- If `product_type` is Child, the row is linked to the most recent Parent product in the sheet via an `index` column.
- All related entities (vendor, brand, category, attribute) are **upserted** — created if they don't exist.
- Missing numeric values default to 0.

---

## 6. Stock Management Module

### 6.1 Branch

| Field | Type |
|---|---|
| `name` | text (unique) |

The system currently operates with a single branch. The architecture is designed to support multiple branches.

### 6.2 ProductStock

Tracks the stock level of a single product at a single branch.

| Field | Type | Notes |
|---|---|---|
| `branch` | FK → Branch | |
| `product` | FK → Product | |
| `amount` | decimal (12,2) | Total physical stock |
| `holding_amount` | decimal (12,2) | Reserved/allocated stock (not yet shipped) |
| `total_amount` (computed) | decimal | `amount - holding_amount` = available stock |

**Constraint:** Unique together on (branch, product).

**Behaviours:**
- **Deposit** — increases `amount` by the given quantity; records an Inbound transaction.
- **Withdraw** — decreases `amount` by the given quantity; records an Outbound transaction. 
- **Withdraw from holding** — performs a withdraw and simultaneously decreases `holding_amount` (used when an allocated order ships).
- **Recalculate checkpoint** — recomputes `amount` from all transactions since the last checkpoint snapshot, then saves the total as a new checkpoint on the most recent transaction. Used to reconcile the stock balance.

**API endpoints (`/api/v1/stocks/`):**

| Action | Method | URL |
|---|---|---|
| List | GET | `/stocks/` |
| Retrieve | GET | `/stocks/{id}/` |
| Deposit | POST | `/stocks/{id}/deposit/` — body: `{ amount, reason }` |
| Withdraw | POST | `/stocks/{id}/withdraw/` — body: `{ amount, reason }` |
| Recalculate | POST | `/stocks/{id}/recalculate_checkpoint/` |
| Transactions | GET | `/stocks/{id}/transactions/` |

### 6.3 ProductStockTransaction

An immutable ledger entry.

| Field | Type | Notes |
|---|---|---|
| `stock` | FK → ProductStock | |
| `transaction_type` | enum | `IB` = Inbound, `OB` = Outbound |
| `amount` | decimal (12,2) | |
| `related_object` | generic FK | Optional link to the entity that caused this transaction (e.g. User, OrderLine) |
| `reason` | string (max 255) | Short reason for the transaction |
| `recal_checkpoint` | decimal (12,2) | Snapshot of the running balance at checkpoint; 0 if not a checkpoint |

---

## 7. Customer Module

### 7.1 Customer

Customers use **soft delete** — they are never permanently removed.

| Field | Type | Notes |
|---|---|---|
| `first_name` | text | |
| `last_name` | text | Optional |
| `address` | text | |
| `remark` | text | Internal notes |
| `telephone` | string (max 255) | |
| `country` | FK → Country | Nullable |
| `logistic_company` | FK → LogisticCompany | Default preferred carrier |
| `deleted_at` | datetime | Null = active; set = soft-deleted |

**Computed field:** `get_fullname()` returns `first_name` if no last name, otherwise `first_name + ' ' + last_name`.

**API endpoints (`/api/v1/customers/`):**

| Action | Method | URL |
|---|---|---|
| List customers | GET | `/customers/` |
| Retrieve | GET | `/customers/{id}/` |
| Create | POST | `/customers/` |
| Update | PUT/PATCH | `/customers/{id}/` |
| Delete (soft) | DELETE | `/customers/{id}/` |
| Search customers | POST | `/filter/customer/` — body: `{ search_text }`, searches first and last name |

**Search fields (list):** `first_name`, `last_name`, `address`, `remark`, `telephone`, `logistic_company__name`.

---

## 8. Logistic Module

### 8.1 LogisticCompany

| Field | Type |
|---|---|
| `name` | text |
| `address` | text |
| `remark` | text |
| `telephone` | string (max 255) |

**API endpoints (`/api/v1/logistic_companies/`):** Full CRUD. List search fields: `name`, `address`, `remark`, `telephone`.  
Extra: `POST /filter/logistic/` — body: `{ search_text }`, filters by name (case-insensitive).

---

## 9. Order Module

### 9.1 Order

The central transactional entity.

| Field | Type | Notes |
|---|---|---|
| `order_number` | text (unique) | Auto-generated; format: `YYYYMMDD###` (e.g. `20260101001`) |
| `logistic_company` | FK → LogisticCompany | Nullable; shipping carrier for this order. ⚠️ Original code uses `on_delete=CASCADE` here despite the field being nullable — deleting a logistic company would delete all its associated orders. The new implementation should use `SET_NULL` instead. |
| `customer` | FK → Customer | Required. Deleting a customer cascades and deletes all their orders. |
| `telephone` | string (max 20) | Order-level contact (may differ from customer's default) |
| `address` | text | Delivery address |
| `has_vat` | boolean | Whether VAT applies to this order |
| `is_included_vat` | boolean | When true, price is VAT-inclusive; when false, VAT is added on top |
| `total_price` | decimal (20,2) | Sum of all order line totals (auto-calculated) |
| `discount_price` | decimal (20,2) | Absolute discount amount |
| `is_discount_percentage` | boolean | If true, discount is applied as a percentage |
| `discount_percentage` | decimal (20,2) | Discount percentage (0–100); used when `is_discount_percentage` is true |
| `vat_price` | decimal (20,2) | Calculated VAT amount |
| `grand_total` | decimal (20,2) | Final payable amount (auto-calculated) |
| `remark` | text | Customer-facing notes |
| `internal_note` | text | Internal staff notes (not shown on invoice) |
| `status` | enum | See Order Status below |
| `running_date` | date | Date used to generate order number; defaults to today |
| `is_withholding_tax` | boolean | Whether withholding tax applies; **default is `true`** |
| `withholding_tax` | decimal (20,2) | Withholding tax percentage |
| `logistic_status` | enum | See Logistic Status below |
| `created_by` | FK → User | Auto-set to the authenticated user on create |
| `updated_by` | FK → User | Auto-set to the authenticated user on update |

**Order Status:**

| Code | Label | Description |
|---|---|---|
| `Dr` | Draft | Order is being prepared |
| `Pd` | Paid | Payment received |
| `Cp` | Completed | Fully fulfilled and closed |
| `Cc` | Cancelled | Cancelled; excluded from sales reports |

**Logistic Status:**

| Code | Label |
|---|---|
| `WTS` | Wait to Send |
| `ST` | Sent |
| `HP` | Handpick |
| `TWH` | To Warehouse |

### 9.2 Grand Total Calculation

This is the core financial calculation. It runs automatically on every save and whenever an order line is created, updated, or deleted.

```
1. total_price = SUM(all order line totals)

2. discount_amount:
   - If is_discount_percentage = true:  total_price × (discount_percentage / 100)
   - If is_discount_percentage = false: discount_price (absolute value)

3. price_with_discount = total_price - discount_amount

4. price_excl_vat:
   - If is_included_vat = true:  price_with_discount / 1.07  (reverse out the embedded 7% VAT)
   - If is_included_vat = false: price_with_discount

5. vat_price:
   - If has_vat = false: 0
   - If has_vat = true and is_included_vat = true:  price_with_discount - (price_with_discount / 1.07)
   - If has_vat = true and is_included_vat = false: price_with_discount × 0.07

6. withholding_tax_amount:
   - If is_withholding_tax = false: 0
   - If is_withholding_tax = true:  price_excl_vat × (withholding_tax / 100)

7. grand_total = price_excl_vat + vat_price - withholding_tax_amount
```

All monetary values are rounded to 2 decimal places using standard half-up rounding.

### 9.3 Order Number Generation

- Format: `{YYYYMMDD}{zero-padded 3-digit sequence}` where the sequence resets per day.
- Example: `20260409001`, `20260409002`.
- The system counts existing orders for the same `running_date` and increments until a unique number is found (collision-safe loop).

### 9.4 OrderLine

| Field | Type | Notes |
|---|---|---|
| `order` | FK → Order | |
| `product` | FK → Product | Protected; can't delete a product if it has order lines |
| `unit` | enum | `Dz`=Dozen (default), `Pc`=Piece, `Pa`=Pack, `Se`=Set, `Ct`=Carton |
| `quantity` | decimal (8,2) | |
| `unit_price` | decimal (20,2) | Price per unit at time of order |
| `discount_price` | decimal (20,2) | Line-level discount |
| `total_price` | decimal (20,2) | `quantity × unit_price - discount_price` |
| `description` | text | Additional line description |
| `remark` | text | Line-level remarks |
| `idx` | integer | Explicit sort index for front-end rendering |

**Behaviour:** When an order line is created, updated, or deleted, the parent order's grand total is **automatically recalculated** and saved.

### 9.5 OrderImage

| Field | Type | Notes |
|---|---|---|
| `order` | FK → Order | |
| `image` | image | Full-size |
| `thumb_image` | image | Auto-generated compressed thumbnail |

### 9.6 Order API

**Base URL:** `/api/v1/orders/`

| Action | Method | URL | Notes |
|---|---|---|---|
| List orders | GET | `/order/` | Search: status, order_number, telephone, customer name, logistic |
| Retrieve order | GET | `/order/{id}/` | Full detail with nested lines |
| Create order | POST | `/order/` | `created_by` set automatically |
| Update order | PUT/PATCH | `/order/{id}/` | `updated_by` set automatically |
| Delete order | DELETE | `/order/{id}/` | |
| List draft orders | GET | `/order/draft/` | Filtered + paginated |
| List paid orders | GET | `/order/paid/` | Filtered + paginated |
| List completed orders | GET | `/order/completed/` | Filtered + paginated |
| List cancelled orders | GET | `/order/cancelled/` | Filtered + paginated |
| Dashboard summary | GET | `/order/dashboard/` | Aggregated order stats |
| Export order to Excel | GET | `/order/{id}/export/` | ⚠️ **Security concern:** original implementation requires no authentication. Anyone with a valid order ID can download the invoice. The new implementation should require authentication or use a signed time-limited token. |
| Combine bills | POST | `/order/combine_bills/` | Body: `{ ids: [...] }`; downloads combined `.xlsx` for multiple orders of same customer |
| Advanced search | GET | `/advance-search/` | See Advanced Search section |
| Filter by status | POST | `/filter/` | Body: `{ search_text: status_code }` |
| Bulk status update | PATCH | `/bulk-update-status/` | Body: `{ ids: [...], status }` or `{ is_selected_all: true, status }` |
| Order lines | CRUD | `/order_lines/` | Search: order_number, product name |
| Order images | CRUD | `/order_images/` | Filter by `order__id` |

**Order create payload structure:**
```json
{
  "customer": 1,
  "logistic_company": 2,
  "telephone": "0812345678",
  "address": "...",
  "has_vat": false,
  "is_included_vat": false,
  "is_withholding_tax": true,
  "withholding_tax": 3,
  "is_discount_percentage": false,
  "discount_price": "0.00",
  "remark": "",
  "internal_note": "",
  "status": "Dr",
  "logistic_status": "WTS",
  "order_lines": [
    {
      "product": 5,
      "unit": "Pc",
      "quantity": "10.00",
      "unit_price": "100.00",
      "discount_price": "0.00",
      "total_price": "1000.00",
      "description": "",
      "remark": "",
      "idx": 0
    }
  ]
}
```

**Advanced search query parameters:**

| Parameter | Type | Description |
|---|---|---|
| `created_by` | profile id | Filter by creator |
| `updated_by` | profile id | Filter by last updater |
| `created_date_start` | date | Start of creation date range |
| `created_date_end` | date | End of creation date range |
| `updated_date_start` | date | Start of update date range |
| `updated_date_end` | date | End of update date range |
| `customer_id` | int | Filter by customer |
| `order_status` | status code | Filter by order status |
| `logistic_status` | status code | Filter by logistic status |

---

## 10. Reporting & Analytics Module

All report endpoints require the `see_sale_graph` permission.

### 10.1 Sales Graph (`POST /api/v1/orders/report-order/`)

Returns order count and grand total aggregated by **year and month** across all four statuses (Draft, Paid, Completed, Cancelled) for a given date range.

**Request body:** `{ "start_date": "YYYY-MM-DD", "end_date": "YYYY-MM-DD" }`

**Response:**
```json
{
  "draft": [{ "created_at__year": 2026, "created_at__month": 4, "grand_total__sum": 10000 }],
  "paid": [...],
  "completed": [...],
  "cancelled": [...]
}
```

### 10.2 Customer Summary Report (`POST /api/v1/orders/customer-report/`)

Downloads an Excel file breaking down **completed orders** by customer for a date range.

**Columns:** No., Customer Name, Total Purchase Amount, Number of Bills.

**Sorted by:** Total purchase amount descending.

**File name format:** `customer_report{start_date}-{end_date}.xlsx`

### 10.3 Sales Summary Report (`POST /api/v1/orders/sales-report/`)

Downloads an Excel file breaking down **completed orders** by staff member (created_by) for a date range.

**Columns:** No., Staff Name, Total Sales Amount, Number of Bills.

**Sorted by:** Total sales amount descending.

**File name format:** `sales_report{start_date}-{end_date}.xlsx`

### 10.4 Order Excel Export (`GET /api/v1/orders/order/{id}/export/`)

> ⚠️ **Security concern:** The original implementation disables authentication entirely on this endpoint. The new system must protect this endpoint — either require standard authentication, or generate a signed time-limited download URL.

Downloads a single order as a formatted Excel invoice.

**Invoice structure:**
- Header: Date, Order Number, Customer Name, Telephone, Address, Remark
- Body: Row Number, Quantity, Unit, Description (product name + description + remark), Price per Unit, Line Total
- Summary: Total, Discount, VAT 7% (if included VAT), Grand Total

**File name format:** `order-{order_number}.xlsx`

### 10.5 Combine Bills (`POST /api/v1/orders/order/combine_bills/`)

Downloads a combined billing statement for multiple orders belonging to the same customer.

**Request body:** `{ "ids": [1, 2, 3] }`

**Statement structure:**
- Header: Date (today), Customer Name, Due Date (blank)
- Body: Row Number, Bill Number, Billing Date, Amount
- Summary: Total, Prepared by (current user's name), Received by (blank line)

**File name format:** `ใบรวมบิล-{customer_name}.xlsx`

---

## 11. File Upload Module

### 11.1 Generic File Upload

| Field | Type |
|---|---|
| `file` | file stored at `uploads/{YYYY}/{MM}/{DD}/` |

Used to support the Excel bulk product import flow.

**API endpoints (`/api/v1/file-upload/`):** Standard upload endpoint.

---

## 12. Country Module

Standard ISO 3166-1 country reference data. Does **not** include timestamps (`created_at`/`updated_at`). The country list endpoint requires **no authentication** — permission classes are empty by design (public reference data).

| Field | Type | Notes |
|---|---|---|
| `iso_3166_1_a2` | string (2 chars, **primary key**) | ISO 3166-1 alpha-2 code (e.g. `TH`, `US`) |
| `iso_3166_1_a3` | string (3 chars) | ISO 3166-1 alpha-3 code (e.g. `THA`) |
| `iso_3166_1_numeric` | string (3 chars) | ISO 3166-1 numeric code (e.g. `764`) |
| `printable_name` | string (max 255) | Display name shown in UI |
| `name` | string (max 255) | Official country name |

Linked from Customer via FK on `iso_3166_1_a2`.

**API endpoints (`/api/v1/countries/`):** Full CRUD.

---

## 13. API Design Rules

### 13.1 Versioning
All API routes are prefixed with `/api/v1/`.

### 13.2 Pagination
- Default page size: **20 items per page**.
- Clients can override the page size by passing a `page_size` query parameter.
- All list endpoints are paginated.
- Custom paginator is used throughout for consistent response shape.

### 13.3 Response Format
- JSON for all API responses.
- Binary (Excel `.xlsx`) for report/export endpoints with appropriate `Content-Disposition` headers.

### 13.4 Search
- All searchable list endpoints support a `search` query parameter matching against a defined set of fields using case-insensitive partial matching.

### 13.5 Filtering
- Filter backends support field-level exact-match and range filtering.
- Advanced search endpoints provide flexible multi-field filtering via query parameters.

### 13.6 Error Handling
- Validation errors return `400 Bad Request` with field-level error details.
- Object not found returns `404 Not Found`.
- Permission denial returns `403 Forbidden`.
- Protected relation (e.g. deleting a product that has been ordered) returns `409 Conflict` with a human-readable error message. (The original implementation incorrectly used `406 Not Acceptable` for this case — use the semantically correct `409 Conflict` in the new system.)

### 13.7 API Documentation
The system exposes:
- OpenAPI schema at `/docs/schema/`
- Swagger UI at `/docs/schema/swagger-ui/`
- ReDoc UI at `/docs/schema/redoc/`

---

## 14. System-Wide Business Rules

1. **Monetary precision** — All prices, totals, and calculations must be rounded to exactly 2 decimal places using standard arithmetic rounding throughout.

2. **Order number uniqueness** — Order numbers are unique per day and generated using a collision-safe loop.

3. **Grand total auto-recalculation** — Any change to an order line (create, update, delete) must trigger an automatic recalculation of the parent order's grand total.

4. **Order lines in create payload** — When creating an order, order lines can be submitted in the same payload (`order_lines` field). Each line can include an optional `id` to update an existing line.

5. **Product cost privacy** — Users without the `can_view_cost` permission must never see the `cost` field in any product response.

6. **Soft delete for customers** — Customers are never hard-deleted. All customer list queries must exclude soft-deleted records by default. A separate manager (`objects_with_deleted`) must be available for admin/reporting use.

7. **Stock auto-creation** — When a product's stock record is first accessed for a given branch and none exists, it should be automatically created with an amount of 0.

8. **Holding stock** — Stock can be placed "on hold" (allocated) without being shipped. The available stock at any time is `amount - holding_amount`. Fulfilling an order moves stock from holding to withdrawn.

9. **Stock recalculation** — The system must support reconciling the stock balance by replaying all transactions from the last checkpoint. This is used to fix any discrepancy between the stored `amount` and the transaction ledger.

10. **Last customer price** — When adding a product to an order, the system can look up the most recent price that a specific customer paid for that product to assist the user.

11. **Duplicate product name check** — Before creating a Standalone or Parent product, the system should warn or reject creation if another non-Child product with the same name already exists.

12. **SKU generation** — A vendor's `initial_name` is the mandatory prefix for product SKUs. Changing a vendor's `initial_name` does not retroactively update existing SKUs but a migration utility exists to batch-update them.

13. **Image compression** — All uploaded images that use the `CompressImageModel` base must have a compressed thumbnail generated automatically at quality 20 on every save.

14. **Bulk status update** — Orders can have their status updated in bulk either by supplying a list of IDs or by selecting all orders. Both modes are mutually exclusive per request.

15. **Running date vs. created date** — The `running_date` on an order is the business date (can be backdated). The `created_at` timestamp is the actual system creation time. Order numbers use `running_date`.

16. **Multi-language product descriptions** — Products store both an English (`description`) and a Thai (`description_th`) description. Both must be maintained.

17. **Withholding tax** — The withholding tax percentage is stored at the order level and deducted from the pre-VAT subtotal. It is calculated as `price_excl_vat × (withholding_tax_percentage / 100)`.

18. **Order line stock integration** — When `enable_stock = true` on a product, stock adjustments happen automatically on every order line change:
    - **On create:** withdraws `quantity` from the product's stock at the default branch.
    - **On update (quantity changed):** re-deposits the previous quantity then withdraws the new quantity, producing two ledger entries.
    - **On delete:** deposits the full quantity back to stock (full reversal); the linked stock transaction records are nullified before the line is removed.
    - If `enable_stock = false` on the product, no stock movements occur regardless of order line changes.
