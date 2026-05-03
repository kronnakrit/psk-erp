# TC-11 — Invoices
**Module:** Invoices, Invoice Orders, Invoice Images  
**Based on:** EPIC-20, EPIC-21

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-11-01 — Invoice CRUD

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-11-01-01 | Create invoice | Admin; orders exist | 1. Navigate to `/invoices/new`<br>2. Enter invoice number, date<br>3. Link orders<br>4. Submit | Invoice created and appears in list | ⏳ |
| TC-11-01-02 | Invoice number unique | Invoice exists | 1. Create with duplicate number | 422; "Invoice number has already been taken" | ⏳ |
| TC-11-01-03 | Edit invoice | Invoice exists | 1. Edit date/notes<br>2. Submit | Invoice updated | ⏳ |
| TC-11-01-04 | Delete invoice | Invoice with no payments | 1. Delete invoice | Removed from list | ⏳ |
| TC-11-01-05 | Invoice list paginated | Many invoices | 1. Navigate to `/invoices` | Pagination controls present | ⏳ |

---

## TC-11-02 — Invoice Orders (Linking Orders to Invoice)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-11-02-01 | Link multiple orders to invoice | Invoice exists; Paid orders available | 1. Create/edit invoice<br>2. Add order links<br>3. Submit | `InvoiceOrder` join records created | ⏳ |
| TC-11-02-02 | Invoice total = sum of linked orders | Invoice with 2 linked orders | 1. View invoice | Invoice total = sum of `grand_total` from linked orders | ⏳ |
| TC-11-02-03 | Remove order from invoice | Invoice with linked order | 1. Remove order link | `InvoiceOrder` record destroyed; total recalculates | ⏳ |
| TC-11-02-04 | Same order cannot be linked twice | — | 1. Try to add same order to same invoice twice | 422; duplicate validation error | ⏳ |

---

## TC-11-03 — Invoice Images (Receipts)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-11-03-01 | Upload invoice image | Invoice exists | 1. Navigate to invoice detail<br>2. Upload image file | Image attached; thumbnail generated | ⏳ |
| TC-11-03-02 | Multiple images per invoice | — | 1. Upload 3 images | All 3 attached and displayed | ⏳ |
| TC-11-03-03 | Delete invoice image | Image attached | 1. Click delete on image | Image removed from Active Storage | ⏳ |
| TC-11-03-04 | Non-image file rejected | — | 1. Upload `.pdf` as invoice image | 422; "must be an image" | ⏳ |
