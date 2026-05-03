# TC-12 — Delivery Order Print
**Module:** Delivery Order Print Layout  
**Based on:** EPIC-12

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-12-01 — Access Control

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-12-01-01 | Delivery order requires authentication | No session | 1. GET `/orders/:id/delivery_order` | Redirect to `/login` | ⏳ |
| TC-12-01-02 | Delivery order requires `view_orders` | User without permission | 1. GET delivery order URL | 403 Forbidden | ⏳ |
| TC-12-01-03 | Non-existent order 404 | — | 1. GET `/orders/999999/delivery_order` | 404 Not Found | ⏳ |

---

## TC-12-02 — Layout Content

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-12-02-01 | Page title contains order number | Order exists | 1. Load delivery order page | `<title>` = "บิลขนส่ง – [order_number]" | ⏳ |
| TC-12-02-02 | Code128 barcode rendered | Order exists | 1. Load page | Barcode SVG present with order number encoded | ⏳ |
| TC-12-02-03 | Order number displayed below barcode | Order exists | 1. Load page | Order number text visible beneath barcode | ⏳ |
| TC-12-02-04 | Customer name and address displayed | Order with customer | 1. Load page | Customer name and delivery address present | ⏳ |
| TC-12-02-05 | Order date displayed | Order exists | 1. Load page | Order date visible in Thai locale format | ⏳ |
| TC-12-02-06 | Table has 7 columns with Thai headers | Order with lines | 1. Load page | Headers: NO., จำนวน, หน่วย, รายละเอียด, ราคาต่อหน่วย, รวม, (blank 7th) | ⏳ |
| TC-12-02-07 | Each order line rendered as table row | Order with 3 lines | 1. Load page | 3 rows in table body | ⏳ |
| TC-12-02-08 | internal_note excluded | Order with `internal_note` set | 1. Load page; inspect source | `internal_note` value NOT present anywhere in HTML | ⏳ |
| TC-12-02-09 | `remark` (public note) included | Order with `remark` set | 1. Load page | Remark text visible | ⏳ |
| TC-12-02-10 | Grand total section present | Order with total | 1. Load page | Total, VAT, discount rows visible in summary section | ⏳ |
| TC-12-02-11 | Signature section present | Any order | 1. Load page | "ลงชื่อ............ผู้รับของ" text present | ⏳ |
| TC-12-02-12 | No sidebar or navigation | — | 1. Load page | `<nav>` / sidebar elements absent from HTML | ⏳ |

---

## TC-12-03 — Print Settings

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-12-03-01 | Default print size A4 | — | 1. Load page | `@page { size: A4; }` in print stylesheet | ⏳ |
| TC-12-03-02 | Select A5 print size | — | 1. Click A5 radio button | `@page { size: A5; }` applied dynamically | ⏳ |
| TC-12-03-03 | Print button triggers browser print | — | 1. Click "พิมพ์" | `window.print()` called | ⏳ |
| TC-12-03-04 | Print controls hidden in print view | — | 1. Inspect @media print styles | Size toggle and Print button have `display: none` in print media | ⏳ |
