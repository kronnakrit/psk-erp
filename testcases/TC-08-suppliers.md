# TC-08 — Suppliers
**Module:** Suppliers  
**Based on:** EPIC-16

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-08-01 — Supplier CRUD

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-08-01-01 | Create supplier | Admin logged in | 1. Navigate to `/suppliers/new`<br>2. Enter name, telephone, address, tax_id<br>3. Submit | Supplier created; appears in list | ⏳ |
| TC-08-01-02 | Duplicate supplier name rejected | Supplier with same name exists | 1. Submit with duplicate name | 422; validation error on name | ⏳ |
| TC-08-01-03 | Edit supplier | Supplier exists | 1. Edit telephone/address<br>2. Submit | Supplier updated | ⏳ |
| TC-08-01-04 | Delete supplier not used in POs | Supplier with no POs | 1. Delete supplier | Supplier removed | ⏳ |
| TC-08-01-05 | Cannot delete supplier linked to POs | Supplier used in PO | 1. Attempt delete | 409 error; supplier preserved | ⏳ |
| TC-08-01-06 | Supplier appears in PO form typeahead | Supplier exists | 1. Open `/purchase_orders/new`<br>2. Type supplier name | Supplier appears in Tom Select dropdown | ⏳ |
| TC-08-01-07 | Search suppliers by name | Multiple suppliers | 1. Use search bar with partial name | Matching suppliers returned | ⏳ |
