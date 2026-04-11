# EPIC-07 — Excel Export & Reporting Module

**Phase:** 7  
**Status:** 🔴 Not Started  
**Goal:** Secure order invoice export (auth required), combined billing statement for multiple orders, customer summary and sales summary Excel downloads, and a monthly sales graph on the dashboard.

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

### STORY-07-01 — Order Invoice Excel Export (Secured)
**Status:** 🔴 Not Started  
**Description:** Export a single order as a formatted Excel invoice. The endpoint requires authentication (fixed from original). Alternatively, a signed time-limited URL (10 minutes) can be used for direct download links.

| # | Task | Status |
|---|---|---|
| T-07-01-01 | Implement `OrderExcelService#build(order)` using `caxlsx`: produce the invoice with header (Date, Order Number, Customer Name, Telephone, Address, Remark), body (Row #, Qty, Unit, Description, Unit Price, Line Total), and summary (Total, Discount, VAT 7%, Grand Total) | `[ ]` |
| T-07-01-02 | Apply number formatting: 2 decimal places for all monetary cells | `[ ]` |
| T-07-01-03 | Add `GET /orders/:id/export` requiring `authenticate_user!`; streams the `.xlsx` file with `Content-Disposition: attachment; filename="order-{order_number}.xlsx"` | `[ ]` |
| T-07-01-04 | Implement signed URL flow: `GET /orders/:id/export_token` returns `{ token, expires_at }` where token is `Rails.application.message_verifier(:export).generate({ order_id: id }, expires_in: 10.minutes)` | `[ ]` |
| T-07-01-05 | Implement `GET /orders/download?token=...` which verifies the signed token and streams the file | `[ ]` |
| T-07-01-06 | Return `403 Forbidden` if token is expired or tampered | `[ ]` |
| T-07-01-07 | Add "Export Invoice" button on Order detail view (generates and downloads without full page reload using Turbo Stream) | `[ ]` |
| T-07-01-08 | Write RSpec service spec for `OrderExcelService`: verify sheet name, row count, cell values | `[ ]` |
| T-07-01-09 | Write RSpec request specs: authenticated export succeeds; unauthenticated returns 401; expired token returns 403 | `[ ]` |

---

### STORY-07-02 — Combined Bills Export
**Status:** 🔴 Not Started  
**Description:** Multiple orders belonging to the same customer can be combined into one billing statement Excel file.

| # | Task | Status |
|---|---|---|
| T-07-02-01 | Implement `CombinedBillsService#build(order_ids:, prepared_by:)` using `caxlsx`: header (Date=today, Customer Name, Due Date=blank), body (Row #, Bill Number, Billing Date, Amount), summary (Total, Prepared by, Received by blank) | `[ ]` |
| T-07-02-02 | Validate all orders in `order_ids` belong to the same customer; return `422` if not | `[ ]` |
| T-07-02-03 | Implement `POST /orders/combine_bills` accepting `{ ids: [...] }` body; streams `.xlsx` with filename `ใบรวมบิล-{customer_name}.xlsx` | `[ ]` |
| T-07-02-04 | Set correct `Content-Type` and `Content-Disposition` headers with UTF-8 encoded filename | `[ ]` |
| T-07-02-05 | Add "Combine Bills" multi-select action on the Order list view | `[ ]` |
| T-07-02-06 | Write RSpec service spec for `CombinedBillsService`: correct row structure, total calculation | `[ ]` |
| T-07-02-07 | Write RSpec request spec: valid multi-order combine, cross-customer rejection | `[ ]` |

---

### STORY-07-03 — Customer & Sales Summary Reports
**Status:** 🔴 Not Started  
**Description:** Two Excel reports covering completed orders. Customer report breaks down by customer; sales report breaks down by staff member. Both require `see_sale_graph` permission.

| # | Task | Status |
|---|---|---|
| T-07-03-01 | Implement `CustomerReportService#build(start_date:, end_date:)`: queries completed orders in range, groups by customer, sums `grand_total`, counts bills; sorts descending by total | `[ ]` |
| T-07-03-02 | Generate `CustomerReportService` Excel: columns No., Customer Name, Total Purchase Amount, Number of Bills | `[ ]` |
| T-07-03-03 | Implement `POST /api/v1/orders/customer_report` streaming file `customer_report{start_date}-{end_date}.xlsx` | `[ ]` |
| T-07-03-04 | Implement `SalesReportService#build(start_date:, end_date:)`: same logic but grouped by `created_by` (staff name) | `[ ]` |
| T-07-03-05 | Generate `SalesReportService` Excel: columns No., Staff Name, Total Sales Amount, Number of Bills | `[ ]` |
| T-07-03-06 | Implement `POST /api/v1/orders/sales_report` streaming file `sales_report{start_date}-{end_date}.xlsx` | `[ ]` |
| T-07-03-07 | Gate both endpoints behind `authorize :order, :report?` (Pundit `see_sale_graph` check) | `[ ]` |
| T-07-03-08 | Build reporting UI section on the dashboard: date range picker + two Download buttons | `[ ]` |
| T-07-03-09 | Write RSpec service specs for both services: correct grouping, sorting, date filtering | `[ ]` |
| T-07-03-10 | Write RSpec request specs: `see_sale_graph` user succeeds; user without permission gets 403 | `[ ]` |

---

### STORY-07-04 — Sales Graph
**Status:** 🔴 Not Started  
**Description:** JSON endpoint returning monthly order aggregates per status for a date range. Dashboard renders these as an interactive bar chart using Chartkick + Groupdate.

| # | Task | Status |
|---|---|---|
| T-07-04-01 | Implement `SalesGraphService#call(start_date:, end_date:)`: uses Groupdate to group orders by year+month for each status (`Dr`, `Pd`, `Cp`, `Cc`), summing `grand_total` | `[ ]` |
| T-07-04-02 | Implement `POST /api/v1/orders/report_order` accepting `{ start_date, end_date }`; returns JSON with keys `draft`, `paid`, `completed`, `cancelled`, each an array of `{ year, month, grand_total__sum }` | `[ ]` |
| T-07-04-03 | Gate behind `see_sale_graph` Pundit policy | `[ ]` |
| T-07-04-04 | Add Chartkick bar chart to Dashboard view displaying monthly revenue for completed orders | `[ ]` |
| T-07-04-05 | Add groupdate configuration ensuring empty months return zero totals | `[ ]` |
| T-07-04-06 | Write RSpec service spec: correct aggregation, empty range returns empty arrays | `[ ]` |
| T-07-04-07 | Write RSpec request spec: response structure, permission gate | `[ ]` |
