# EPIC-12 — Delivery Order Print (บิลขนส่ง)

**Phase:** 12
**Status:** 🟢 Completed
**Goal:** Users can click a "Print" link on any row of the Orders list to open a standalone, printable Delivery Order (บิลขนส่ง) HTML page in a new browser tab; the page displays the order header, a Code128 barcode of the order number, a 7-column order-lines table, grand total summary, and a manual signature space — formatted for either A4 (≥ 16 order lines per page) or A5 — and provides a Print button that triggers the browser's native print dialog.

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

## Background & Observed Current State

From browser inspection of `http://localhost:3000/orders`:

| Area | Current State | Target State |
|------|--------------|--------------|
| Orders list — Actions column | Shows "View \| Edit \| Delete" per row | Add "Print" link that opens delivery order in a new tab |
| Delivery Order page | Does not exist | New standalone page at `GET /orders/:id/delivery_order` using `print` layout (no sidebar, no main nav) |
| Barcode | Not present anywhere | Code128 barcode of `order_number` rendered as SVG via JsBarcode, text below the barcode |
| Paper size | N/A | User chooses A4 (default, ≥ 16 lines/page) or A5 before printing |
| Order lines columns | Current show page: Product, Unit, Qty, Unit Price, Discount, Line Total, Actions | Delivery Order: NO., จำนวน, หน่วย, รายละเอียด, ราคาต่อหน่วย, รวม, free write column |
| Internal note | Shown in `orders/show` to users with `update?` permission | **Explicitly excluded** from the Delivery Order |
| Signature | Not present | "ลงชื่อ............ผู้รับของ" signature line at the bottom of the document |

**Relevant routes observed:**

| Route helper | HTTP verb | Path | Purpose |
|---|---|---|---|
| `orders_path` | GET | `/orders` | Orders list |
| `order_path(order)` | GET | `/orders/:id` | Order detail (show) |
| `export_order_path(order)` | GET | `/orders/:id/export` | Excel invoice export (existing) |
| *(new)* `delivery_order_order_path(order)` | GET | `/orders/:id/delivery_order` | Delivery Order print page |

**Existing Pundit policy methods in `OrderPolicy`:** `export?`, `export_token?`, `download?`, `combine_bills?`, `bulk_update_status?`, `dashboard?` — all mapping to `permission?("view_orders")` or `permission?("change_orders")`.

---

## Stories

---

### STORY-12-01 — Delivery Order Route, Controller Action, Policy & Print Layout

**Status:** 🟢 Completed

**Description:** Add a new `delivery_order` action to `OrdersController` secured by Pundit, reachable at `GET /orders/:id/delivery_order`, that renders using a dedicated minimal `print` layout (no sidebar, no main navigation). This story covers the back-end plumbing only; the HTML view itself is built in STORY-12-02.

**User Perspective:**
As a logistics operator, I want the Delivery Order to open at its own URL in a new tab using a clean layout free of navigation chrome, so that no application UI appears when I print the document.

**Acceptance Criteria:**

| #     | Given                                                                                     | When                                                                    | Then                                                                                                                                 |
| ----- | ----------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | An authenticated user with the `view_orders` permission                                   | sends `GET /orders/:id/delivery_order` for an existing order            | the server responds with HTTP 200; the response is rendered using the `print` layout (no `<nav>`, no sidebar)                        |
| AC-02 | An unauthenticated request                                                                | `GET /orders/:id/delivery_order`                                        | the server responds 302 redirect to `/login`                                                                                         |
| AC-03 | An authenticated user **without** the `view_orders` permission                            | `GET /orders/:id/delivery_order`                                        | the server responds 403 Forbidden                                                                                                    |
| AC-04 | Any authenticated request                                                                 | `GET /orders/999999/delivery_order` (non-existent order)                | the server responds 404 Not Found                                                                                                    |
| AC-05 | The `print` layout is rendered                                                            | the page loads                                                          | the HTML document contains no `<nav>`, no `<aside>` sidebar, no `.rb_header` element; only the yielded view content is present       |
| AC-06 | The `delivery_order?` policy method is evaluated                                          | the user has `view_orders` in their permission array                    | `delivery_order?` returns `true`                                                                                                     |
| AC-07 | The `delivery_order?` policy method is evaluated                                          | the user does **not** have `view_orders` in their permission array      | `delivery_order?` returns `false`                                                                                                    |

**Edge Cases:**

- Order where `order.order_lines` is empty: the controller still succeeds with HTTP 200; the view renders an empty lines table.
- Policy inherits from `ApplicationPolicy`; it does not override `Scope` — no additional scope restriction is needed.

| #          | Task                                                                                                                                                                                     | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-12-01-01 | In `config/routes.rb`, add `get :delivery_order` as a member route inside `resources :orders` (alongside the existing `get :export` member route)                                       | `[x]`  |
| T-12-01-02 | In `OrdersController`, add `:delivery_order` to the `before_action :set_order, only:` array                                                                                             | `[x]`  |
| T-12-01-03 | Add `def delivery_order` action to `OrdersController`: call `authorize @order`; assign `@order_lines = @order.order_lines.includes(:product).order(:idx)`; render with `layout: "print"` | `[x]`  |
| T-12-01-04 | Add `def delivery_order?` to `app/policies/order_policy.rb` returning `permission?("view_orders")` (consistent with `export?`)                                                          | `[x]`  |
| T-12-01-05 | Create `app/views/layouts/print.html.erb`: minimal HTML5 shell (`<!DOCTYPE html>`, `<html>`, `<head>`, `<body class="bg-white">`); include `stylesheet_link_tag "application"`, `javascript_importmap_tags`; include JsBarcode via unpkg CDN (`<script src="https://unpkg.com/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"></script>`); yield directly in body with no sidebar or header wrapper | `[x]`  |
| T-12-01-06 | Write RSpec request spec `spec/requests/orders/delivery_order_spec.rb` covering: HTTP 200 with `view_orders` permission; 302 without authentication; 403 without `view_orders` permission; 404 for a non-existent order ID | `[x]`  |
| T-12-01-07 | Write RSpec policy spec for `delivery_order?` in `spec/policies/order_policy_spec.rb`: assert `true` when user has `view_orders`; assert `false` when user lacks it                      | `[x]`  |

---

### STORY-12-02 — Delivery Order HTML View (บิลขนส่ง Document)

**Status:** 🟢 Completed

**Description:** Create the full HTML view `app/views/orders/delivery_order.html.erb` that renders the formatted Delivery Order document with a barcode, order details (excluding `internal_note`), a 7-column order-lines table in Thai column headers, a grand total summary, and a manual signature line.  A Stimulus controller handles paper size switching (A4/A5) and Print button. `@media print` CSS hides all on-screen controls during printing and applies the correct `@page` size directive.

**User Perspective:**
As a logistics operator, I want to see a well-formatted, printable Delivery Order with a barcode, all relevant order details, and a signature space, so that I can hand the printed document to the delivery person.

**Acceptance Criteria:**

| #     | Given                                                                         | When                                                                         | Then                                                                                                                                                                                                 |
| ----- | ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | The delivery order page loads for any valid order                             | the page renders                                                             | the page title (`<title>`) is "บิลขนส่ง – [order_number]"                                                                                                                                           |
| AC-02 | The delivery order page loads                                                 | the page renders                                                             | a large, bold, centred heading reads "บิลขนส่ง"                                                                                                                                                     |
| AC-03 | The delivery order page loads                                                 | the page renders                                                             | a Code128 barcode SVG is visible; the `order_number` string (e.g. `20260415001`) appears as text directly below the barcode                                                                          |
| AC-04 | The delivery order page loads                                                 | the page renders                                                             | the following fields are present: Order Number, Date (`running_date` formatted `DD/MM/YYYY`), Customer full name, Telephone, Address, Logistic Company name, Remark                                   |
| AC-05 | The delivery order page loads                                                 | the page renders                                                             | the field `internal_note` does NOT appear anywhere in the rendered HTML                                                                                                                              |
| AC-06 | The delivery order page loads                                                 | the page renders                                                             | the order lines table has exactly 7 columns with headers: **NO.**, **จำนวน**, **หน่วย**, **รายละเอียด**, **ราคาต่อหน่วย**, **รวม**, and one blank/unlabelled column                                 |
| AC-07 | An order with `n` order lines                                                 | the page renders                                                             | each row shows: row sequence (1-based from `idx` or array position), `quantity`, `unit` (display label from `UNIT_LABELS`), product name (`order_line.product.name`), `unit_price`, `total_price`, and a blank free-write cell |
| AC-08 | The delivery order page loads                                                 | the page renders                                                             | a totals section below the lines table shows at minimum: Subtotal (`total_price`) and Grand Total (`grand_total`); VAT line appears only when `order.has_vat?` is true; Discount line appears only when discount is non-zero; Withholding Tax line appears only when `order.is_withholding_tax?` is true and withholding tax amount is non-zero |
| AC-09 | The delivery order page loads                                                 | the page renders                                                             | a signature section appears BELOW the totals with the exact text **"ลงชื่อ............ผู้รับของ"** with sufficient white space above the line for a handwritten signature                             |
| AC-10 | The page loads with A4 selected (the default)                                 | the user clicks the **Print** button                                         | `window.print()` is called; `@media print` applies `@page { size: A4; margin: 10mm; }`; the print controls div (paper size selector + Print button) is hidden via `display: none`                   |
| AC-11 | The page is set to A4 and contains exactly 16 order lines                    | the user triggers print preview                                              | all 16 order lines appear on a single A4 page without overflow (verified by visual inspection or automated screenshot regression)                                                                    |
| AC-12 | The user clicks the **A5** radio button                                       | then clicks Print                                                            | `@media print` applies `@page { size: A5; margin: 8mm; }`; the barcode, order details, lines, totals, and signature are all visible on the A5 page                                                  |
| AC-13 | The `order.telephone` is `nil`                                                | the page renders                                                             | the Telephone field displays "—" (em dash)                                                                                                                                                           |
| AC-14 | The `order.address` is `nil`                                                  | the page renders                                                             | the Address field displays "—" (em dash)                                                                                                                                                             |
| AC-15 | The `order.logistic_company` is `nil`                                         | the page renders                                                             | the Logistic Company field displays "—" (em dash)                                                                                                                                                    |
| AC-16 | The order has zero order lines                                                | the page renders                                                             | the lines table body is empty; the totals section still renders showing ฿0.00 values; the signature section still renders                                                                            |

**Edge Cases:**

- A product name that exceeds column width wraps within the รายละเอียด cell; it does not overflow horizontally or push adjacent columns.
- When order has > 16 lines (A4), subsequent lines flow to the next print page; there is no hard cut-off at line 16.
- `order_line.idx` may not always start from 1 or be sequential after line deletions; the NO. column must use the 1-based position of the line in `@order_lines` (not `idx` value).
- `order_line.unit` stores codes (`Dz`, `Pc`, `Pa`, `Se`, `Ct`); the หน่วย column must display the corresponding human-readable label (e.g. "Dz" → "โหล", "Pc" → "ชิ้น", "Pa" → "คู่", "Se" → "ชุด", "Ct" → "กล่อง") — use a view helper or a constant hash.

| #          | Task                                                                                                                                                                                                                                                      | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-12-02-01 | Create `app/javascript/controllers/delivery_order_controller.js` Stimulus controller with: `connect()` initialising JsBarcode on `<svg data-delivery-order-target="barcode">` using `window.JsBarcode`; `selectSize(event)` action that injects a `<style id="paper-size-style">` tag into `document.head` with `@page { size: <A4\|A5>; margin: <10mm\|8mm>; }`; `printPage()` action that calls `window.print()` | `[x]`  |
| T-12-02-02 | Create `app/views/orders/delivery_order.html.erb` — full view structure: `<style>` block for print CSS; print-controls div (`.no-print`); paper container `div#print-container` with `data-controller="delivery-order"` | `[x]`  |
| T-12-02-03 | Implement the **document header** section inside `#print-container`: centred "บิลขนส่ง" heading (≥ 22pt on screen, `text-3xl font-bold` Tailwind class); two-column grid — left: order metadata fields (Order #, Date, Customer, Telephone, Address, Logistic Company, Remark); right: barcode SVG `<svg data-delivery-order-target="barcode">` with `data-order-number` attribute; order number text below the SVG | `[x]`  |
| T-12-02-04 | Implement the **order lines table** section: `<table>` with `<thead>` row showing 7 columns (NO., จำนวน, หน่วย, รายละเอียด, ราคาต่อหน่วย, รวม, blank); `<tbody>` iterating `@order_lines` with 1-based row index; unit code translated via `UNIT_DISPLAY_LABELS` constant or view helper; numeric columns (`quantity`, `unit_price`, `total_price`) formatted with `number_with_precision(value, precision: 2, delimiter: ",")`; blank right-most `<td>` with fixed width `w-16` or `min-w-[4rem]` for free writing | `[x]`  |
| T-12-02-05 | Implement the **totals section** below the lines table: single-column right-aligned summary rows mirroring `_grand_total.html.erb` logic (Subtotal; optional Discount; optional Excl. VAT + VAT 7%; optional Withholding Tax; Grand Total bold); use `GrandTotalCalculator.new(@order).call` result | `[x]`  |
| T-12-02-06 | Implement the **signature section** below totals: a `<div class="mt-8 flex justify-end">` containing the Thai text `"ลงชื่อ............ผู้รับของ"` with sufficient top padding (`pt-8`) for handwritten signature space | `[x]`  |
| T-12-02-07 | Implement the **print-controls bar** (`.no-print`): A4/A5 radio buttons (`data-action="change->delivery-order#selectSize"`); a "พิมพ์" / Print button (`data-action="click->delivery-order#printPage"`) styled visibly on screen; A4 selected by default on page load; default `@page { size: A4; margin: 10mm; }` injected in the Stimulus `connect()` hook | `[x]`  |
| T-12-02-08 | Write the `@media print` CSS block inside the view `<style>` tag: `.no-print { display: none !important; }` to hide controls; `body { font-size: 11pt; }` minimum readable size; A4 table row `line-height` and `padding` calibrated so 16 rows + header row + totals + signature fit within a single A4 page content area (~237mm at 10mm margins) | `[x]`  |
| T-12-02-09 | Add a `UNIT_DISPLAY_LABELS` constant (or extend `OrderLine::UNITS`) mapping unit codes to Thai display strings: `"Dz" → "โหล"`, `"Pc" → "ชิ้น"`, `"Pa" → "คู่"`, `"Se" → "ชุด"`, `"Ct" → "กล่อง"` — placed in `app/models/order_line.rb` or a dedicated view helper method in `app/helpers/orders_helper.rb` | `[x]`  |
| T-12-02-10 | Write RSpec request spec asserting the rendered HTML of `GET /orders/:id/delivery_order`: contains "บิลขนส่ง"; contains the order number string; does NOT contain `internal_note` content; contains "ลงชื่อ"; contains column header "รายละเอียด" | `[x]`  |

---

### STORY-12-03 — Print Button on Orders Index Page

**Status:** 🟢 Completed

**Description:** Add a "Print" action link to each row in the orders list table that opens the delivery order page in a new browser tab. The link is only rendered when the logged-in user's `OrderPolicy#delivery_order?` returns true.

**User Perspective:**
As a logistics operator, I want a one-click "Print" link on each order row in the list, so that I can quickly open the delivery order for any order without navigating to the order detail page first.

**Acceptance Criteria:**

| #     | Given                                                                                                     | When                                                             | Then                                                                                                                              |
| ----- | --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | An authenticated user with `view_orders` permission visits `GET /orders`                                  | the page renders                                                 | each order row in the Actions column contains a "Print" link rendered as `<a target="_blank">` pointing to `/orders/:id/delivery_order` |
| AC-02 | The user clicks "Print" on a specific order row                                                           | the link is clicked                                              | a new browser tab opens at `GET /orders/:id/delivery_order` for that specific order                                               |
| AC-03 | An authenticated user **without** `view_orders` permission visits `GET /orders`                           | the page renders                                                 | no "Print" link appears in any row's Actions column                                                                               |
| AC-04 | The "Print" link is present in the Actions column                                                         | the page renders                                                 | the link appears **after** the existing "View" link and **before** "Edit" in the Actions column (order: View → Print → Edit → Delete) |

**Edge Cases:**

- When `bulk_update_status?` is false (no checkbox column), the table has 7 columns total; the Print link must still appear in the correct Actions `<td>`.
- When `policy(order).edit?` is false, the Edit link is absent but Print remains visible (they are independent policy checks).

| #          | Task                                                                                                                                                                                                                                    | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-12-03-01 | In `app/views/orders/index.html.erb`, inside the `<div class="flex items-center justify-end gap-2">` actions container for each order row, add `<% if policy(order).delivery_order? %> <%= link_to "Print", delivery_order_order_path(order), target: "_blank", class: "text-purple-600 hover:underline text-xs" %> <% end %>` immediately after the "View" link | `[x]`  |
| T-12-03-02 | Write RSpec request spec for `GET /orders` asserting: "Print" link is present in the response body when user has `view_orders` permission; "Print" link is absent when user lacks `view_orders` permission                             | `[x]`  |
