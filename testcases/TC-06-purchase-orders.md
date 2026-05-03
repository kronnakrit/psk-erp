# TC-06 — Purchase Orders
**Module:** Purchase Orders, Supplier Invoices, Stock Receipt  
**Based on:** EPIC-16

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-06-01 — Purchase Order CRUD

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-06-01-01 | Create purchase order | Admin; supplier exists | 1. Navigate to `/purchase_orders/new`<br>2. Select supplier<br>3. Add lines with product + qty + cost<br>4. Submit | PO created with unique PO number; status=`Draft` | ⏳ |
| TC-06-01-02 | PO number auto-generated | New PO | 1. Create PO | PO number generated (e.g., `PO-YYYYMMDD-001`) | ⏳ |
| TC-06-01-03 | Edit PO in Draft status | Draft PO | 1. Edit line quantities<br>2. Submit | PO updated | ⏳ |
| TC-06-01-04 | Cannot edit Received PO | PO with status=Received | 1. Attempt to edit PO | 403 or redirect; edit not allowed | ⏳ |
| TC-06-01-05 | Cancel Draft PO | Draft PO | 1. Cancel PO | Status set to Cancelled | ⏳ |

---

## TC-06-02 — Purchase Order Lines

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-06-02-01 | Add product line to PO | PO exists; product exists | 1. Add line with product, qty, unit_cost | Line saved with correct total cost | ⏳ |
| TC-06-02-02 | Line total = qty × unit_cost | Line data | 1. Enter qty=5, cost=200 | Line total = 1000 | ⏳ |
| TC-06-02-03 | PO grand total sums all lines | PO with multiple lines | 1. View PO | Grand total = sum of all line totals | ⏳ |
| TC-06-02-04 | Remove PO line | PO with lines | 1. Delete a line | Line removed; grand total recalculates | ⏳ |
| TC-06-02-05 | Select unit definition per line | Product with unit group | 1. Select product<br>2. Choose unit definition | `unit_definition_id` saved on PO line | ⏳ |

---

## TC-06-03 — Stock Receipt on PO Receive

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-06-03-01 | Receive PO increments stock | PO with lines; products stock-enabled | 1. Mark PO as Received | Product stock amounts increase by PO line quantities | ⏳ |
| TC-06-03-02 | Receive PO creates new stock lots | Products stock-enabled | 1. Receive PO | New `StockLot` per PO line created with `purchase_order_line_id` reference | ⏳ |
| TC-06-03-03 | PO status changes to Received | Draft PO | 1. Receive PO | Status = `Received` | ⏳ |
| TC-06-03-04 | Partial receive not allowed | — | 1. Attempt partial receive via UI | No partial receive option; all lines received at once | ⏳ |

---

## TC-06-04 — Purchase Order Reports

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-06-04-01 | Filter POs by supplier | Multiple POs from different suppliers | 1. Apply supplier filter | Only POs from selected supplier shown | ⏳ |
| TC-06-04-02 | Filter POs by date range | — | 1. Set from/to dates | Only POs in range shown | ⏳ |
| TC-06-04-03 | Filter POs by status | Mixed statuses | 1. Filter by Draft | Only Draft POs shown | ⏳ |
