# TC-03 — Order Module
**Module:** Orders, Order Lines, Order Status, Grand Total Calculation, Stock Integration, FIFO Allocation, Delivery Order, Salesperson, Order Intelligence  
**Based on:** EPIC-06, EPIC-11, EPIC-12, EPIC-14, EPIC-17, EPIC-18, EPIC-19

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-03-01 — Order Creation & Order Number

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-01-01 | Create new order | Admin logged in; customer exists | 1. Navigate to `/orders/new`<br>2. Select customer<br>3. Fill order date<br>4. Add at least 1 order line<br>5. Submit | Order created with status `Dr` (Draft); order number format `YYYYMMDDnnn` | ⏳ |
| TC-03-01-02 | Order number resets daily | Orders from previous day exist | 1. Create first order on a new calendar day | Order number starts at `001` for that day | ⏳ |
| TC-03-01-03 | Order number increments within same day | Multiple orders same day | 1. Create 3 orders on same day | Numbers are `20260430001`, `20260430002`, `20260430003` | ⏳ |
| TC-03-01-04 | Concurrent order creation collision safety | Rapid concurrent creates | 1. Simulate two simultaneous creates | Each gets a unique number; no duplicate order numbers | ⏳ |
| TC-03-01-05 | Order date defaults to today | New order form | 1. Open `/orders/new` | Date field pre-filled with today's date | ⏳ |
| TC-03-01-06 | Customer autofill (telephone, address) | Customer with telephone + address exists | 1. Select customer in order form | Telephone and Address fields auto-populated | ⏳ |
| TC-03-01-07 | Logistic company autofill from customer | Customer with `logistic_company_id` set | 1. Select that customer | Logistic Company field auto-filled | ⏳ |
| TC-03-01-08 | Create order without customer | — | 1. Submit order form without selecting customer | 422; validation error on customer | ⏳ |

---

## TC-03-02 — Order Status Lifecycle

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-02-01 | New order defaults to Draft | Order created | 1. Create order | Status shown as `Dr` / "Draft" | ⏳ |
| TC-03-02-02 | Transition Draft → Paid | Draft order | 1. Edit order<br>2. Change status to Paid<br>3. Submit | Order status updated to `Pd` | ⏳ |
| TC-03-02-03 | Transition Paid → Completed | Paid order | 1. Change status to Completed | Order status `Cp` | ⏳ |
| TC-03-02-04 | Transition Draft → Cancelled | Draft order | 1. Change status to Cancelled | Order status `Cc` | ⏳ |
| TC-03-02-05 | Status tab filter — Draft tab | Multiple orders with mixed statuses | 1. Click "Draft" tab on orders list | Only Draft orders shown | ⏳ |
| TC-03-02-06 | Status tab filter — Completed tab | — | 1. Click "Completed" tab | Only Completed orders shown | ⏳ |
| TC-03-02-07 | Bulk status update by IDs | Multiple orders selected | 1. Select 3 orders<br>2. Choose "Paid" status<br>3. Click Apply | All 3 orders updated to Paid; 302 redirect | ⏳ |
| TC-03-02-08 | Bulk status update all | — | 1. POST with `is_selected_all: true` + status | All orders updated | ⏳ |
| TC-03-02-09 | Bulk update: IDs + is_selected_all mutual exclusivity | — | 1. POST with both `ids` and `is_selected_all` | 400 Bad Request | ⏳ |
| TC-03-02-10 | Active orders filter (EPIC-19) | Orders with mixed statuses | 1. View orders list default view | Only non-cancelled, non-completed orders shown by default | ⏳ |

---

## TC-03-03 — Grand Total Calculation (7-Step Formula)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-03-01 | No VAT, no discount, no WHT | Order with lines | 1. Create order with `has_vat=false`, no discount, no WHT | `grand_total = total_price` | ⏳ |
| TC-03-03-02 | VAT included in price (`has_vat=true`, `is_included_vat=true`) | Order with `has_vat=true`, `is_included_vat=true` | 1. Set lines; confirm grand total | `price_excl_vat = price_with_discount ÷ 1.07`; `vat_price = price_with_discount - price_excl_vat`; `grand_total = price_excl_vat + vat_price` | ⏳ |
| TC-03-03-03 | VAT added on top (`has_vat=true`, `is_included_vat=false`) | — | 1. Create with VAT not included | `vat_price = price_with_discount × 0.07`; `grand_total = price_with_discount + vat_price` | ⏳ |
| TC-03-03-04 | Percentage discount | `is_discount_percentage=true`, `discount=10` | 1. Set 10% discount | `discount_amount = total_price × 0.10` | ⏳ |
| TC-03-03-05 | Absolute discount | `is_discount_percentage=false`, `discount=500` | 1. Set flat 500 discount | `discount_amount = 500` | ⏳ |
| TC-03-03-06 | Withholding tax applied | `is_withholding_tax=true`, `withholding_tax=3` | 1. Enable WHT at 3% | `withholding_tax_amount = price_excl_vat × 0.03`; deducted from grand total | ⏳ |
| TC-03-03-07 | All tax combinations: VAT included + WHT + % discount | All flags enabled | 1. Create complex order | Grand total = `price_excl_vat + vat_price - withholding_tax_amount` with correct rounding to 2dp | ⏳ |
| TC-03-03-08 | Grand total recalculates on line add | Order with existing lines | 1. Add new order line | Grand total panel updates without page reload | ⏳ |
| TC-03-03-09 | Grand total recalculates on line quantity change | Order with lines | 1. Edit quantity on a line | Summary card updates immediately | ⏳ |
| TC-03-03-10 | Grand total recalculates on line delete | Order with lines | 1. Remove a line | Grand total decreases correctly | ⏳ |
| TC-03-03-11 | Line total = qty × unit_price − discount_price | Order line | 1. Set qty=3, unit_price=100, discount_price=50 | Line total = `3 × 100 - 50 = 250` | ⏳ |

---

## TC-03-04 — Order Lines Management

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-04-01 | Add order line via product typeahead | Product exists | 1. Type 2+ chars in product search<br>2. Select from dropdown | `product_id` set; `unit_definition_id` populated; `unit_price` autofilled with last price | ⏳ |
| TC-03-04-02 | Unit price autofills from last order | Product sold to this customer before | 1. Select same product for same customer | `unit_price` shows previous selling price | ⏳ |
| TC-03-04-03 | Unit price falls back to product.price | No prior order for this product/customer | 1. Select product never sold to customer | `unit_price` = `product.price` | ⏳ |
| TC-03-04-04 | Unit definition dropdown populated on product select | Product with unit group | 1. Select product | Unit definition dropdown fills with unit options sorted by ratio desc | ⏳ |
| TC-03-04-05 | Price recalculates when unit changes (EPIC-18) | Product with unit group having multiple definitions | 1. Select product<br>2. Change unit definition | `unit_price` recalculates: `new_price = current_price × (new_ratio ÷ old_ratio)` | ⏳ |
| TC-03-04-06 | Add line via Tab from last row | At least 1 line in form | 1. Press Tab from discount field of last row | New blank order line row appended | ⏳ |
| TC-03-04-07 | Remove order line | Order with lines | 1. Click ✕ on a line row | Row hidden; `_destroy=1`; total recalculates | ⏳ |
| TC-03-04-08 | Order line saved with unit_definition_id | Line submitted | 1. Submit order with line having unit_definition selected | Order line saved with `unit_definition_id` set | ⏳ |
| TC-03-04-09 | Order line requires unit_definition_id | Line without unit | 1. Submit line with no unit selected | Validation error: unit_definition can't be blank | ⏳ |
| TC-03-04-10 | "Default: ฿X" hint shown below unit price | Product selected | 1. Select product | "Default: ฿X,XXX.XX" hint text appears below unit_price field | ⏳ |

---

## TC-03-05 — FIFO Automatic Lot Allocation (EPIC-17)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-05-01 | Creating order line auto-allocates from oldest lot | Product with multiple lots (FIFO order) | 1. Create order line for stock-enabled product | `order_line_lot_allocations` created; oldest lot(s) consumed first | ⏳ |
| TC-03-05-02 | Allocation spans multiple lots when first lot insufficient | First lot qty < ordered qty | 1. Create line with qty > first lot remaining | Allocation spreads across lot 1 (exhausted) then lot 2 | ⏳ |
| TC-03-05-03 | Lot allocation removed on line delete | Order line with allocations | 1. Delete order line | `order_line_lot_allocations` removed; lot remaining quantities restored | ⏳ |
| TC-03-05-04 | Lot allocation updated on quantity increase | Order line with allocation | 1. Increase line quantity | Additional allocation pulled from next available lot | ⏳ |
| TC-03-05-05 | Lot allocation updated on quantity decrease | Order line with allocation | 1. Decrease line quantity | Excess allocation returned to lot; remaining quantities restored | ⏳ |
| TC-03-05-06 | No manual lot selection UI | Order form | 1. Inspect order line form | No lot selector input present (FIFO is automatic) | ⏳ |

---

## TC-03-06 — Order Stock Integration (EPIC-06)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-06-01 | Stock decrements on order line create | Stock-enabled product; stock=10 | 1. Create order line with qty=3 | Product stock amount = 7 | ⏳ |
| TC-03-06-02 | Stock re-adjusts on line quantity update | Line exists; stock=7 | 1. Change line qty from 3 to 5 | Stock deposits 3 (reversal) then withdraws 5; final stock=5 | ⏳ |
| TC-03-06-03 | Stock restored on line delete | Line exists; stock was decremented | 1. Delete order line with qty=3 | Stock amount increases by 3 | ⏳ |
| TC-03-06-04 | Non-stock product does not affect stock | Product with `enable_stock=false` | 1. Add line for non-stock product | No ProductStock record created/modified | ⏳ |

---

## TC-03-07 — Order Form UX (EPIC-11)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-07-01 | iPad-first layout (768px) | — | 1. Open `/orders/new` at 768px width | No horizontal scroll; all sections visible | ⏳ |
| TC-03-07-02 | Footer summary sticky on desktop | Viewport ≥ 1024px | 1. Open `/orders/new` | Summary card is sticky at `top: 1rem` | ⏳ |
| TC-03-07-03 | Customer typeahead debounce | — | 1. Type 2+ characters in customer field | Dropdown appears after 300ms debounce | ⏳ |
| TC-03-07-04 | VAT checkbox shows/hides VAT row | `has_vat` toggled | 1. Uncheck has_vat | VAT row hidden in summary; recheck → row reappears | ⏳ |
| TC-03-07-05 | WHT checkbox shows/hides WHT input | `is_withholding_tax` toggled | 1. Uncheck WHT | WHT percentage input hidden; row removed from summary | ⏳ |
| TC-03-07-06 | Discount % vs absolute toggle | `is_discount_percentage` toggled | 1. Check percentage<br>2. Uncheck | % input visible / absolute input visible per state | ⏳ |
| TC-03-07-07 | Salesperson shown on order (EPIC-19) | Order with `salesperson_id` | 1. View order detail | Salesperson name displayed on order | ⏳ |

---

## TC-03-08 — Delivery Order Print (EPIC-12)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-08-01 | Delivery order accessible via GET | Authenticated user with `view_orders` | 1. GET `/orders/:id/delivery_order` | HTTP 200; print layout (no sidebar) | ⏳ |
| TC-03-08-02 | Delivery order requires auth | Unauthenticated | 1. GET `/orders/:id/delivery_order` | 302 redirect to `/login` | ⏳ |
| TC-03-08-03 | Delivery order requires permission | User without `view_orders` | 1. GET `/orders/:id/delivery_order` | 403 Forbidden | ⏳ |
| TC-03-08-04 | Non-existent order returns 404 | — | 1. GET `/orders/999999/delivery_order` | 404 Not Found | ⏳ |
| TC-03-08-05 | Page title is "บิลขนส่ง – [order_number]" | Order exists | 1. Load delivery order | `<title>` tag contains "บิลขนส่ง – 20260430001" | ⏳ |
| TC-03-08-06 | Barcode rendered for order number | Order exists | 1. Load delivery order | Code128 barcode SVG visible; order number below barcode | ⏳ |
| TC-03-08-07 | internal_note excluded | Order with internal_note | 1. Load delivery order<br>2. Inspect HTML | `internal_note` value not present anywhere in rendered HTML | ⏳ |
| TC-03-08-08 | 7-column table with Thai headers | Order with lines | 1. Load delivery order | Table headers: NO., จำนวน, หน่วย, รายละเอียด, ราคาต่อหน่วย, รวม, (blank) | ⏳ |
| TC-03-08-09 | Signature section present | Any order | 1. Load delivery order | Text "ลงชื่อ............ผู้รับของ" present below totals | ⏳ |
| TC-03-08-10 | A4 print size applied by default | — | 1. Click Print button | `@page { size: A4; margin: 10mm; }` in CSS; print controls hidden | ⏳ |
| TC-03-08-11 | A5 print size on selection | — | 1. Select A5 radio<br>2. Click Print | `@page { size: A5; margin: 8mm; }` applied | ⏳ |

---

## TC-03-09 — Order Intelligence (EPIC-14)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-09-01 | Price monitor alert: unit_price below product.price | Order line with unit_price < product.price | 1. View order detail | Warning indicator shown on that line | ⏳ |
| TC-03-09-02 | Audit trail: order creation recorded | Order created | 1. Create order<br>2. View audit trail | `created_by` and `created_at` recorded | ⏳ |
| TC-03-09-03 | Audit trail: order update recorded | Order updated | 1. Edit order<br>2. View history | `updated_by` and `updated_at` updated | ⏳ |
| TC-03-09-04 | Duplicate order detection | Order with same customer + date + similar lines exists | 1. Create near-duplicate order | Warning displayed suggesting possible duplicate | ⏳ |

---

## TC-03-10 — Order Advanced Search & Dashboard

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-03-10-01 | Search orders by order number | Orders exist | 1. Enter order number in search | Matching order returned | ⏳ |
| TC-03-10-02 | Search by date range | Orders with various dates | 1. Set from_date and to_date filter | Only orders within range returned | ⏳ |
| TC-03-10-03 | Search by customer name | — | 1. Enter customer name fragment | Orders for matching customer shown | ⏳ |
| TC-03-10-04 | Search by status | — | 1. Filter by `status=Pd` | Only Paid orders returned | ⏳ |
| TC-03-10-05 | Dashboard: today's order count | Orders created today | 1. Navigate to dashboard | Today's count correct | ⏳ |
| TC-03-10-06 | Dashboard: completed revenue this month | Completed orders this month | 1. View dashboard | Revenue total matches sum of completed order grand_totals | ⏳ |
| TC-03-10-07 | Dashboard: last 10 orders widget | — | 1. View dashboard | Last 10 orders listed in reverse chronological order | ⏳ |
