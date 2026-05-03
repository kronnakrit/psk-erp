# TC-09 — Reports & Excel Export
**Module:** Reports, Excel Export  
**Based on:** EPIC-07

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-09-01 — Order Reports

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-09-01-01 | Export orders to Excel | Orders exist; user has export permission | 1. Navigate to `/orders`<br>2. Click Export Excel button | `.xlsx` file downloaded | ⏳ |
| TC-09-01-02 | Export respects active filters | Date range filter applied | 1. Set date filter<br>2. Export | Excel contains only filtered orders | ⏳ |
| TC-09-01-03 | Export requires permission | User without `export_orders` | 1. Attempt export | 403 Forbidden | ⏳ |
| TC-09-01-04 | Export column headers in Thai | Any export | 1. Open exported .xlsx | Header row uses Thai column names | ⏳ |
| TC-09-01-05 | Export includes grand total column | — | 1. Open exported .xlsx | `grand_total` column present with correct values | ⏳ |

---

## TC-09-02 — Stock Reports

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-09-02-01 | Export stock list to Excel | Stock records exist | 1. Click Export on `/stocks` | `.xlsx` file with current stock amounts downloaded | ⏳ |
| TC-09-02-02 | Export stock transactions | Transactions exist | 1. Click Export on stock transaction list | Excel includes all transactions for the period | ⏳ |
| TC-09-02-03 | Stock report includes product name, SKU, amount | — | 1. Open stock export .xlsx | Columns: ชื่อสินค้า, SKU, จำนวน present | ⏳ |

---

## TC-09-03 — Purchase Order Reports

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-09-03-01 | Export POs to Excel | POs exist | 1. Click Export on `/purchase_orders` | `.xlsx` with PO data downloaded | ⏳ |
| TC-09-03-02 | Export PO lines | PO with lines | 1. Export a single PO detail | Excel includes all PO lines with product, qty, cost | ⏳ |
