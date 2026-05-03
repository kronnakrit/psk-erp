# TC-07 — Unit Groups & Unit Definitions
**Module:** Unit Groups, Unit Definitions  
**Based on:** EPIC-15

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-07-01 — Unit Group CRUD

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-07-01-01 | Create unit group | Admin logged in | 1. Navigate to `/unit_groups/new`<br>2. Enter name (e.g. "Weight")<br>3. Submit | Unit group created | ⏳ |
| TC-07-01-02 | Edit unit group | Unit group exists | 1. Navigate to edit<br>2. Change name<br>3. Submit | Unit group updated | ⏳ |
| TC-07-01-03 | Delete unit group | Unit group not used by products | 1. Delete group | Group removed | ⏳ |
| TC-07-01-04 | Cannot delete unit group assigned to products | Unit group used by product | 1. Attempt delete | 409 conflict; group preserved | ⏳ |
| TC-07-01-05 | Unit groups list sorted alphabetically | Multiple groups | 1. Navigate to `/unit_groups` | Groups displayed in alphabetical order | ⏳ |

---

## TC-07-02 — Unit Definition CRUD

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-07-02-01 | Add unit definition to group | Unit group exists | 1. Navigate to unit group detail<br>2. Add definition with name="กก.", ratio=1<br>3. Submit | Definition saved under unit group | ⏳ |
| TC-07-02-02 | Add second unit definition with higher ratio | Unit group with base definition | 1. Add "ตัน", ratio=1000 | Definition saved; ratio stored correctly | ⏳ |
| TC-07-02-03 | Ratio must be positive | — | 1. Enter ratio=0 or negative | 422; validation error | ⏳ |
| TC-07-02-04 | Edit unit definition | Definition exists | 1. Edit name or ratio<br>2. Submit | Definition updated | ⏳ |
| TC-07-02-05 | Delete unit definition not used by order lines | Definition unused | 1. Delete definition | Removed from group | ⏳ |
| TC-07-02-06 | Cannot delete definition used in order lines | Definition used | 1. Attempt delete | 409 error; definition preserved | ⏳ |

---

## TC-07-03 — Unit Group in Order Lines

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-07-03-01 | Definitions sorted by ratio descending in dropdown | Product with unit group containing 3 definitions | 1. Add order line and select that product | Unit dropdown shows definitions sorted from largest ratio to smallest | ⏳ |
| TC-07-03-02 | Price auto-recalculates on unit change | Order line with product selected | 1. Change unit definition | `unit_price` = `old_price × (new_ratio / old_ratio)` | ⏳ |
| TC-07-03-03 | Quantity in smallest unit calculated | Order line with non-base unit | 1. Enter qty=2 with ratio=1000 | `quantity_in_base_unit = 2000` (ratio applied) | ⏳ |
| TC-07-03-04 | Base unit (ratio=1) price not multiplied | Ratio=1 unit | 1. Select ratio=1 definition | `unit_price` unchanged | ⏳ |
