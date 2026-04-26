# EPIC-21 — Order Excel Export & Delivery Order Header Compaction

**Phase:** 21
**Status:** 🟢 Completed
**Goal:** Users with the `export_orders_excel` permission can select one or more orders on the Orders index page and download a multi-sheet Excel file (one sheet per order, styled like the reference sample); and the delivery order print page header is redesigned to be as compact as possible, giving maximum vertical space to the order lines table.

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

## Stories

### STORY-21-01 — Export Excel Bulk Action on Orders Index

**Status:** 🟢 Completed
**Description:** A new "Export Excel" button appears in the bulk action bar when one or more orders are selected. Clicking it POSTs the selected order IDs to `POST /orders/export_excel` and triggers a direct download of a multi-sheet `.xlsx` file — one worksheet per selected order — matching the structure of the reference sample file.

**User Perspective:**
As a user with the `export_orders_excel` permission, I want to select orders on the Orders index page and click "Export Excel" so that I can download a formatted Excel workbook with one sheet per order for offline record-keeping or sharing.

---

**Acceptance Criteria:**

| #     | Given                                                                                                 | When                                                                    | Then                                                                                                                                                                                              |
| ----- | ----------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A user with `export_orders_excel` permission has selected 1 or more orders on the Orders index page  | The user clicks the "Export Excel" button                               | The browser receives HTTP 200 with `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` and `Content-Disposition: attachment; filename="orders_export_YYYYMMDD.xlsx"` |
| AC-02 | N orders are selected (N ≥ 1)                                                                        | The Excel file is downloaded                                            | The workbook contains exactly N worksheets; each sheet name is `"{order_number} - {customer_fullname}"` truncated to 31 characters (Excel limit)                                                  |
| AC-03 | Any selected order with at least one order line                                                       | The corresponding sheet is opened                                       | The sheet contains: a 6-row header section (Date, No., Customer, Tel., Address, Remark), a styled column header row (NO / Quantity / Unit / Description / Price per Unit / Total), one data row per order line, and a footer section |
| AC-04 | An order line's `product.description` is present                                                      | The Description cell for that line is written                           | The cell value is `"{product.name} {product.description}"` (single space separator)                                                                                                               |
| AC-05 | An order line's `product.description` is blank or nil                                                 | The Description cell for that line is written                           | The cell value is `product.name` only (no trailing space)                                                                                                                                         |
| AC-06 | An order has `has_vat = false` and `is_withholding_tax = false` (or withholding tax amount is zero)  | The footer section is generated                                         | The footer contains rows: "Total" (subtotal), "Discount" (only when `discount_amount > 0`), "Grand Total" — no VAT or WHT rows are present                                                       |
| AC-07 | An order has `has_vat = true`                                                                         | The footer section is generated                                         | The footer contains rows: "Total", "Discount" (if > 0), "Price excl. VAT", "VAT 7%", and "Grand Total"                                                                                           |
| AC-08 | An order has `is_withholding_tax = true` and the calculated `withholding_tax_amount > 0`             | The footer section is generated                                         | The footer contains a "WHT {rate}%" row showing the deduction amount as a negative value, positioned after VAT rows (if any) and before "Grand Total"                                             |
| AC-09 | A user with `export_orders_excel` permission submits 0 order IDs (`ids[]` empty or absent)           | `POST /orders/export_excel`                                             | The server responds with HTTP 302 redirect to `orders_path` and sets a flash alert "No orders selected."                                                                                          |
| AC-10 | A user **without** `export_orders_excel` permission                                                  | `POST /orders/export_excel`                                             | Pundit raises `NotAuthorizedError`; the application responds with HTTP 403                                                                                                                        |
| AC-11 | An unauthenticated request                                                                            | `POST /orders/export_excel`                                             | The application responds with HTTP 302 redirect to the login page                                                                                                                                 |
| AC-12 | A user without `export_orders_excel` permission                                                      | The Orders index page renders with orders selected in the bulk bar      | The "Export Excel" button is **not rendered** in the bulk action bar                                                                                                                              |

---

**Edge Cases:**

- Sheet name truncation: `"#{order_number} - #{customer_fullname}"` may exceed 31 characters. The service must truncate to exactly 31 characters before adding the worksheet.
- Duplicate sheet names: If two selected orders produce the same truncated name, the service appends a numeric suffix (`" (2)"`, `" (3)"`, etc., trimming earlier characters as needed to stay within 31 chars) to ensure uniqueness.
- An order with zero lines: The sheet still renders the header section and column headers, with no data rows, followed by footer rows showing `฿0.00` totals.
- `order.telephone` or `order.address` is blank: The respective header cell renders an em dash (`—`).
- `order.remark` is blank: The Remark header row is still written (with a blank value cell) to maintain consistent row positioning.

---

**Excel Sheet Layout Reference:**

```
Row 1:  ["Date",     "DD-Mon-YYYY"]
Row 2:  ["No.",      "{order_number}"]
Row 3:  ["Customer", "{customer_fullname}"]
Row 4:  ["Tel.",     "{telephone | —}"]
Row 5:  ["Address",  "{address | —}"]
Row 6:  ["Remark",   "{remark | (blank)}"]
Row 7:  (blank row — separator)
Row 8:  ["NO", "Quantity", "Unit", "Description", "Price per Unit", "Total"]   ← bold header, background fill
Row 9+: [line_index, quantity, unit_definition.name, "product.name product.description".strip, unit_price, total_price]
        ...
Row N:  (blank row — separator)
Row N+1: ["", "", "", "", "Total",          subtotal_value]
Row N+2: ["", "", "", "", "Discount",       discount_value]     ← only when discount_amount > 0
Row N+3: ["", "", "", "", "Price excl. VAT", price_excl_vat]   ← only when has_vat = true
Row N+4: ["", "", "", "", "VAT 7%",          vat_price]         ← only when has_vat = true
Row N+5: ["", "", "", "", "WHT {rate}%",    -wht_amount]        ← only when is_withholding_tax and amount > 0
Row N+6: ["", "", "", "", "Grand Total",    grand_total_value]  ← bold
```

Column widths: [4, 10, 10, 45, 15, 15] (approximate character units)

---

| #          | Task                                                                                                                                                                                                                          | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-21-01-01 | Add `"export_orders_excel"` to the `Permissions::ALL` constant array in `app/models/concerns/permissions.rb`                                                                                                                  | `[x]`  |
| T-21-01-02 | Add `export_excel?` method to `OrderPolicy` (`app/policies/order_policy.rb`) gated on `permission?("export_orders_excel")`                                                                                                   | `[x]`  |
| T-21-01-03 | Add `post :export_excel` to the collection block of `resources :orders` in `config/routes.rb`, generating route helper `export_excel_orders_path`                                                                            | `[x]`  |
| T-21-01-04 | Create `app/services/bulk_order_excel_export_service.rb` (`BulkOrderExcelExportService`): accepts an ActiveRecord::Relation of orders (eager-loaded with `order_lines: [:product, :unit_definition]` and `:customer`); builds a `caxlsx` workbook per the sheet layout reference above; returns the `Axlsx::Package` instance | `[x]`  |
| T-21-01-05 | Implement `export_excel` action in `OrdersController`: authorize with `authorize Order, :export_excel?`; find orders via `policy_scope(Order).where(id: Array(params[:ids])).includes(order_lines: [:product, :unit_definition], :customer)`; redirect with alert if empty; call `BulkOrderExcelExportService`; stream result via `send_data` with `type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"` and `disposition: "attachment"` and filename `"orders_export_#{Date.today.strftime('%Y%m%d')}.xlsx"` | `[x]`  |
| T-21-01-06 | Add "Export Excel" form and button to the bulk action bar in `app/views/orders/index.html.erb`, positioned **before** the "Combine Bills" button: `<form id="export_excel_form" action="<%= export_excel_orders_path %>" method="post" data-turbo="false">` with CSRF token; button `data-action="click->bulk-action#exportExcel"`, `data-testid="export-excel-btn"`, styled with amber/yellow background to visually distinguish from Combine Bills | `[x]`  |
| T-21-01-07 | Add `exportExcel()` and `prepareExportExcelForm()` methods to `app/javascript/controllers/bulk_action_controller.js`; wire the `export_excel_form` submit listener in `connect()`; `prepareExportExcelForm` injects `ids[]` hidden inputs (same pattern as `prepareCombineBillsForm`); `exportExcel()` calls `document.getElementById("export_excel_form").requestSubmit()` | `[x]`  |
| T-21-01-08 | Write RSpec request spec `spec/requests/orders/export_excel_spec.rb` covering: (a) authenticated + authorized user receives 200 xlsx download; (b) user without `export_orders_excel` permission receives 403; (c) unauthenticated request receives 302 to login; (d) empty `ids[]` receives 302 with flash alert | `[x]`  |
| T-21-01-09 | Write RSpec unit spec `spec/services/bulk_order_excel_export_service_spec.rb` covering: correct sheet count; correct sheet names (including truncation at 31 chars); correct header rows; correct data rows (description concatenation); correct footer rows for all VAT/WHT combinations | `[x]`  |

---

### STORY-21-02 — Delivery Order Header Compaction

**Status:** 🟢 Completed
**Description:** The header section of the delivery order print page (`/orders/:id/delivery_order`) is redesigned to occupy the minimum viable vertical height while keeping all metadata fields readable. The barcode is shrunk. The freed vertical space allows more order line rows to appear above the fold on printed A4/A5 paper.

**User Perspective:**
As a staff member printing a delivery order (บิลขนส่ง), I want the header section to be as compact as possible so that more order line rows fit on the first printed page without needing to scroll or flip a page.

---

**Acceptance Criteria:**

| #     | Given                                                          | When                                               | Then                                                                                                                                                         |
| ----- | -------------------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | Any order's delivery_order page is loaded                      | The page renders                                   | HTTP 200 is returned and the page title remains `"บิลขนส่ง – {order_number}"`                                                                                |
| AC-02 | The page renders                                               | The header section is inspected                    | All six metadata fields (เลขที่ Order, วันที่, ลูกค้า, โทรศัพท์, ที่อยู่, บริษัทขนส่ง) are present in the DOM                                               |
| AC-03 | The page renders                                               | The header layout is observed                      | Metadata fields are arranged in a denser layout (e.g. multiple fields per row) so the header section takes fewer vertical pixels than the previous 2-column grid (left: 6 stacked fields, right: barcode) |
| AC-04 | The barcode is rendered by the Stimulus `delivery-order` controller | The barcode SVG is inspected                  | The JsBarcode `height` option is ≤ 40 (reduced from 60) and `width` option is ≤ 1.5 (reduced from 2)                                                        |
| AC-05 | `@order.remark` is present                                     | The page renders                                   | The remark field is visible in the compact header                                                                                                             |
| AC-06 | `@order.remark` is blank                                       | The page renders                                   | No remark row is rendered (existing conditional behaviour preserved)                                                                                          |
| AC-07 | The page is rendered in print mode (A4)                        | The `@page` CSS is applied                         | The print controls (`no-print`) are hidden and the compact header appears on the printed output                                                               |

---

**Edge Cases:**

- Long customer address (multi-line `break-words` text): The compact layout must still allow address text to wrap without overflowing into other fields.
- Long customer name: Must not truncate; must wrap within its cell.
- Remark present on a compact layout: Must not push the barcode or other fields out of position.

---

| #          | Task                                                                                                                                                                                                                                                                                      | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-21-02-01 | Redesign the header section in `app/views/orders/delivery_order.html.erb`: replace the current 2-column grid (6 stacked metadata fields on left / barcode on right) with a compact layout — e.g. a 3-column flex/grid row that groups short fields (เลขที่ Order, วันที่, บริษัทขนส่ง) on the first row and customer detail fields (ลูกค้า, โทรศัพท์, ที่อยู่) on a second row, with the barcode placed to the far right at reduced size; reduce `mb-3` to `mb-1` on the header wrapper | `[x]`  |
| T-21-02-02 | Update the `<style>` block in `delivery_order.html.erb`: reduce `.meta-label` width from `110px` to `80px`; reduce `#print-container` `padding` from `6mm 8mm 4mm` to `4mm 6mm 2mm`; add a `.header-compact` utility class with `font-size: 10pt` and `line-height: 1.2` for the header area; reduce `margin-bottom` on `.doc-heading` from `6px` to `2px` | `[x]`  |
| T-21-02-03 | Reduce barcode dimensions in `app/javascript/controllers/delivery_order_controller.js`: change JsBarcode options `height` from `60` to `40` and `width` from `2` to `1.5`                                                                                                                | `[x]`  |
| T-21-02-04 | Write RSpec request spec asserting `GET /orders/:id/delivery_order` returns HTTP 200 and renders the `delivery_order` template (smoke test to confirm no regressions from layout changes)                                                                                                 | `[x]`  |
