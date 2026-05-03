# TC-13 — Stock Locations
**Module:** Stock Locations  
**Based on:** EPIC-19

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-13-01 — Stock Location CRUD

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-13-01-01 | Create stock location | Admin logged in | 1. Navigate to `/stock_locations/new`<br>2. Enter name (e.g. "Warehouse A – Row 3")<br>3. Submit | Stock location created; appears in list | ⏳ |
| TC-13-01-02 | Edit stock location | Location exists | 1. Edit name<br>2. Submit | Location updated | ⏳ |
| TC-13-01-03 | Delete stock location | Location not assigned to any stock | 1. Delete location | Removed from list | ⏳ |
| TC-13-01-04 | Cannot delete location assigned to product stocks | Location used | 1. Attempt delete | 409 error; location preserved | ⏳ |
| TC-13-01-05 | Stock locations list paginated | Many locations | 1. Navigate to `/stock_locations` | Pagination controls present | ⏳ |

---

## TC-13-02 — Stock Location Assignment

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-13-02-01 | Assign single location to product stock | Stock + location exist | 1. Navigate to `/stocks/:id`<br>2. Select location<br>3. Submit | `ProductStockLocation` record created | ⏳ |
| TC-13-02-02 | Assign multiple locations | Multiple locations exist | 1. Select 3 locations<br>2. Submit | 3 `ProductStockLocation` records created | ⏳ |
| TC-13-02-03 | Remove one location from product stock | 3 locations assigned | 1. Deselect one location<br>2. Submit | Only that join record removed; others preserved | ⏳ |
| TC-13-02-04 | Tom Select used for location multi-select | Stock show page | 1. Inspect DOM | Tom Select library active on `stock_location_ids` input | ⏳ |
| TC-13-02-05 | Assigned locations shown on stock detail | Locations assigned | 1. Navigate to `/stocks/:id` | Assigned location names displayed | ⏳ |
