# EPIC-11 — Order Form UX Redesign (Modern, iPad-first)

**Phase:** 11
**Status:** 🟡 In Progress
**Goal:** Replace the current single-column `orders/new` and `orders/edit` form with a modern three-section layout (Header / Body / Footer) that is fully usable on iPad (≥ 768 px), supports keyboard-only order-line entry, real-time total computation in the browser, smart customer/product autofill, and human-readable display values for all code fields.

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

## Background & Observed Current State

From browser inspection of `http://localhost:3000/orders/new` the following problems were identified:

| Area | Current State | Target State |
|------|--------------|--------------|
| Layout | Single narrow column card (~760 px), not iPad-optimised | Full-width three-section layout: Header / Body / Footer |
| Customer select | Basic `<select>` via Tom Select, no autofill | Typeahead search → auto-fills telephone, address, logistic company |
| Logistic status | Displays raw codes: `WTS`, `ST`, `HP`, `TWH` | Displays human labels: "Wait to Send", "Sent", "Handpick", "To Warehouse" |
| Product select | Basic `<select>`, no SKU search, no price autofill | Typeahead by SKU or name → autofills unit + last selling price; shows default price below field |
| Order line total | Static, calculated server-side only on submit | Computed in real-time (Stimulus) on qty / unit-price change |
| Keyboard entry | Mouse required to add new lines | Tab from discount field creates new line |
| Order summary | Only shown on edit (right col), not on new | Sticky summary card always visible with real-time JS calculation |
| VAT / WHT / Discount toggles | All fields always visible | Conditional: VAT Included hidden when VAT unchecked; WHT % hidden when WHT unchecked; Discount shows either % or amount depending on toggle |
| Remark / Internal note | Placed inside "Order Information" card above pricing | Moved to footer section below order summary |
| Order images | Not on new form | Image upload section in footer |
| Numeric format | Raw numbers (`10000.0`) | Comma-formatted locale display (`10,000.00`) |

---

## API Endpoints Available

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v1/customers?q[first_name_or_last_name_cont]=<term>` | Customer typeahead search |
| `POST /api/v1/customers/filter` | Customer filter returning `{ id, first_name, last_name, telephone, address, logistic_company_id }` |
| `POST /api/v1/logistic_companies/filter` | Logistic company details |
| `GET /api/v1/catalogs/products?q[name_or_sku_cont]=<term>` | Product typeahead search by name or SKU |
| `GET /api/v1/catalogs/products/:id/last_price/:customer_id` | Last selling price for product+customer pair |

---

## Stories

---

### STORY-11-01 — Three-Section Page Layout (iPad-first)

**Status:** 🟢 Completed

**User Perspective:**
As a sales operator, I want a well-structured order form that fits my iPad screen without horizontal scrolling, so that I can create orders quickly on the floor.

**Acceptance Criteria:**

| #     | Given | When | Then |
| ----- | ----- | ---- | ---- |
| AC-01 | I open `/orders/new` on a viewport of 768 px width | the page loads | no horizontal scroll occurs; all three sections (Header / Body / Footer) are visible without overflow |
| AC-02 | I open `/orders/new` on a viewport ≥ 1024 px | the page loads | the Footer summary card is sticky (`position: sticky; top: 1rem`) within the footer section |
| AC-03 | I am on `/orders/new` | the page renders | page title is "New Order" with a "← Back to Orders" link at top-right |
| AC-04 | I submit the form with validation errors | the server responds with 422 | inline error messages appear directly below each offending field |
| AC-05 | I open `/orders/:id/edit` | the page loads | all existing order data (header fields, lines, summary) is pre-populated correctly |

| #           | Task | Status |
| ----------- | ---- | ------ |
| T-11-01-01 | Rename current `app/views/orders/_form.html.erb` to `_form_legacy.html.erb` (keep for reference during migration) | `[x]` |
| T-11-01-02 | Create new `app/views/orders/_form.html.erb` with three `<section>` regions: `#order-header`, `#order-body`, `#order-footer`; wire `form_with model: order` around all three | `[x]` |
| T-11-01-03 | Apply responsive grid: single column on < 768 px; two-column (`md:grid-cols-2`) on ≥ 768 px for footer section (summary card right, pricing/notes left) | `[x]` |
| T-11-01-04 | Set `data-controller="order-form"` on the `<form>` element; create `app/javascript/controllers/order_form_controller.js` as the master Stimulus controller for this epic | `[x]` |
| T-11-01-05 | Update `app/views/orders/new.html.erb` and `edit.html.erb` to use full-width layout (removed `max-w-5xl`) | `[x]` |
| T-11-01-06 | Write RSpec request spec: `GET /orders/new` returns 200; `GET /orders/:id/edit` returns 200 | `[ ]` |

---

### STORY-11-02 — Header Section: Order Date, Customer Typeahead & Auto-fill

**Status:** 🟢 Completed

**User Perspective:**
As a sales operator, I want to type a customer name or phone number and have all their details instantly filled in, so that I don't have to manually copy address and logistic info.

**Acceptance Criteria:**

| #     | Given | When | Then |
| ----- | ----- | ---- | ---- |
| AC-01 | I open `/orders/new` | the page loads | the Order Date field is pre-filled with today's date |
| AC-02 | I type at least 2 characters into the Customer search | debounce fires (300 ms) | a dropdown of matching customers is shown (name + telephone) |
| AC-03 | I select a customer from the dropdown | the selection is confirmed | the hidden `order[customer_id]` field is set; Telephone, Address fields are auto-filled |
| AC-04 | The selected customer has a `logistic_company_id` | after customer selection | the Logistic Company field is set automatically |
| AC-05 | The selected customer has no `logistic_company_id` | after customer selection | the Logistic Company field is cleared |
| AC-06 | I open `/orders/:id/edit` | page loads | the Customer field shows the existing customer's name; all autofilled fields show their saved values |

| #           | Task | Status |
| ----------- | ---- | ------ |
| T-11-02-01 | Add `GET /api/v1/customers/search` route: accepts `q` param, returns JSON array (max 20 results) | `[x]` |
| T-11-02-02 | Add `search` action to `Api::V1::CustomersController` | `[x]` |
| T-11-02-03 | Build header section HTML in `_form.html.erb`: Customer typeahead input + hidden field + telephone + address + Order Date + Status | `[x]` |
| T-11-02-04 | Create `customer-search` Stimulus controller: debounced fetch, render dropdown, dispatch `customer:selected` event | `[x]` |
| T-11-02-05 | In `order_form_controller.js`, listen to `customer:selected`: set `customerId`, `telephone`, `address`, trigger logistic autofill | `[x]` |
| T-11-02-06 | Write RSpec request spec for `GET /api/v1/customers/search?q=<term>` | `[x]` |

---

### STORY-11-03 — Header Section: Logistic Company & Human-Readable Logistic Status

**Status:** 🟢 Completed

**User Perspective:**
As a sales operator, I want the logistic status to read "Wait to Send" not "WTS", so that I can understand and communicate the status without needing to memorise codes.

**Acceptance Criteria:**

| #     | Given | When | Then |
| ----- | ----- | ---- | ---- |
| AC-01 | I open the order form | the logistic status dropdown renders | options display: "Wait to Send", "Sent", "Handpick", "To Warehouse" |
| AC-02 | I submit the form selecting "Wait to Send" | server processes params | `order.logistic_status` is stored as `"WTS"` |
| AC-03 | I open an existing order with `logistic_status: "HP"` | edit page loads | the dropdown shows "Handpick" selected |
| AC-04 | A customer is selected with `logistic_company_id` set | customer selection event fires | the Logistic Company select is updated automatically |
| AC-05 | I manually change the Logistic Company after autofill | I submit | the manually-chosen logistic company is saved |

| #           | Task | Status |
| ----------- | ---- | ------ |
| T-11-03-01 | Add `LOGISTIC_STATUS_LABELS` constant to `Order` model | `[x]` |
| T-11-03-02 | Update logistic status `<select>` in `_form.html.erb` to use `Order::LOGISTIC_STATUS_LABELS` as options | `[x]` |
| T-11-03-03 | Add `logistic_status_label` helper to `OrdersHelper`; use in `show.html.erb` and index table | `[x]` |
| T-11-03-04 | Add `autofillLogistic(logisticCompanyId)` method in `order_form_controller.js` with manual-change guard flag | `[x]` |
| T-11-03-05 | Update `app/views/orders/index.html.erb` and `show.html.erb` to display label instead of raw code | `[x]` |
| T-11-03-06 | Write RSpec model spec: `Order::LOGISTIC_STATUS_LABELS` maps all codes to human labels | `[x]` |

---

### STORY-11-04 — Body Section: Product Typeahead, Autofill & Real-Time Line Total

**Status:** 🟢 Completed

**User Perspective:**
As a sales operator, I want to type a product SKU or name, see it auto-fill the price and unit, and be able to add lines using only the keyboard, so that I can enter an order in under a minute without reaching for the mouse.

**Acceptance Criteria:**

| #     | Given | When | Then |
| ----- | ----- | ---- | ---- |
| AC-01 | I type at least 2 characters into a product search input | debounce fires (200 ms) | a dropdown of matching products (SKU + name) is shown |
| AC-02 | I select a product | selection is confirmed | hidden `product_id` set; `unit` autofilled; `unit_price` set to last selling price; `quantity` set to `1` |
| AC-03 | A product has never been sold to this customer | product is selected | `unit_price` falls back to `product.price` |
| AC-04 | A product is selected | the row renders | "Default: ฿X,XXX.XX" hint shows below Unit Price |
| AC-05 | I change qty or unit_price | any change fires | row total is recomputed without page reload |
| AC-06 | I press Tab from the Discount input of the **last** row | Tab key fires | a new blank order line row is appended |
| AC-07 | I click the remove ✕ button on a line row | click fires | row is hidden, `_destroy` set to `1`, summary recalculates |

| #           | Task | Status |
| ----------- | ---- | ------ |
| T-11-04-01 | Update `app/views/orders/_order_line_fields.html.erb`: text search input + hidden `product_id`; `data-controller="order-line-search"` | `[x]` |
| T-11-04-02 | Add default price hint display below unit price input | `[x]` |
| T-11-04-03 | Create `app/javascript/controllers/order_line_search_controller.js`: debounced fetch, dropdown, dispatch `order-line-search:selected` event | `[x]` |
| T-11-04-04 | In `order_form_controller.js`, handle `order-line-search:selected`: fetch last_price, fill unit_price, show default price hint | `[x]` |
| T-11-04-05 | Add `computeLineTotal(row)` to `order_form_controller.js` | `[x]` |
| T-11-04-06 | Wire `input` events on qty/price/discount → `computeLineTotal` + `computeOrderSummary` | `[x]` |
| T-11-04-07 | Implement Tab-to-add-line via `onDiscountKeydown` in `order_form_controller.js` | `[x]` |
| T-11-04-08 | Implement `addLine()` and `removeLine()` in `order_form_controller.js` | `[x]` |
| T-11-04-09 | Verify `GET /api/v1/catalogs/products` supports `q[name_or_sku_cont]` Ransack predicate | `[x]` |
| T-11-04-10 | Create `app/javascript/utils/currency.js` with `formatCurrency` and `parseCurrency` | `[x]` |

---

### STORY-11-05 — Footer Section: Real-Time Order Summary

**Status:** 🟢 Completed

**User Perspective:**
As a sales operator, I want to see the order grand total update instantly as I enter quantities and prices, including VAT and WHT, so that I can confirm the total before saving.

**Acceptance Criteria:**

| #     | Given | When | Then |
| ----- | ----- | ---- | ---- |
| AC-01 | I change any order line qty or price | value changes | the Subtotal row in the summary card updates without server round-trip |
| AC-02 | `has_vat` is unchecked | VAT checkbox state | the "VAT Included" checkbox row is hidden |
| AC-03 | `has_vat` is checked | VAT checkbox state | the "VAT Included" row becomes visible; VAT (7%) row appears in summary |
| AC-04 | `is_withholding_tax` is unchecked | WHT checkbox state | the WHT % input row is hidden; WHT row removed from summary |
| AC-05 | `is_discount_percentage` is checked | discount toggle | Discount % input visible; Discount Amount input hidden |
| AC-06 | `is_discount_percentage` is unchecked | discount toggle | Discount Amount input visible; Discount % input hidden |
| AC-07 | Grand total is computed | any input change | summary shows: Subtotal, Discount, After Discount, Excl. VAT, VAT 7%, WHT, Grand Total — all comma-formatted |

| #           | Task | Status |
| ----------- | ---- | ------ |
| T-11-05-01 | Build footer section HTML: left (pricing toggles + notes); right (sticky summary card with all `summaryXxx` targets) | `[x]` |
| T-11-05-02 | Add `data-order-form-target` attributes to all checkboxes and inputs | `[x]` |
| T-11-05-03 | Implement `toggleVat()` in `order_form_controller.js` | `[x]` |
| T-11-05-04 | Implement `toggleWht()` | `[x]` |
| T-11-05-05 | Implement `toggleDiscountMode()` | `[x]` |
| T-11-05-06 | Implement `computeOrderSummary()` with 7-step formula matching `GrandTotalCalculator` | `[x]` |
| T-11-05-07 | Wire `change` + `input` events on toggles and numeric inputs → their handlers | `[x]` |
| T-11-05-08 | On `connect()`, call `computeOrderSummary()` to initialise display | `[x]` |

---

### STORY-11-06 — Footer Section: Order Images Upload

**Status:** 🟢 Completed

**User Perspective:**
As a sales operator, I want to attach photos to an order, so that I can reference them later without paper records.

**Acceptance Criteria:**

| #     | Given | When | Then |
| ----- | ----- | ---- | ---- |
| AC-01 | I open `/orders/:id/edit` | page loads | existing order images are shown as thumbnails |
| AC-02 | I open `/orders/new` | page loads | Images section shows "Images can be attached after saving the order." |

| #           | Task | Status |
| ----------- | ---- | ------ |
| T-11-06-01 | Create `app/views/orders/_order_images.html.erb` with turbo_frame `order_images_panel`; show thumbnails + upload; note on new | `[x]` |
| T-11-06-02 | Render `_order_images.html.erb` in footer of `_form.html.erb` | `[x]` |

---

### STORY-11-07 — Numeric Formatting: Comma Display Across the Form

**Status:** 🟢 Completed

**User Perspective:**
As a sales operator working with orders in the tens-of-thousands Baht range, I want numbers formatted with commas so that I can read them at a glance without counting digits.

**Acceptance Criteria:**

| #     | Given | When | Then |
| ----- | ----- | ---- | ---- |
| AC-01 | An order line has `unit_price = 10000` | row renders | Unit Price shows `10,000.00`; Total shows comma-formatted via JS |
| AC-02 | Summary card shows `grand_total = 21400` | summary renders | Grand Total shows `฿21,400.00` |
| AC-03 | I type `15000` into the Unit Price field | I tab out | the field displays `15,000.00` |
| AC-04 | The order index table renders price columns | page loads | grand_total shows comma format |

| #           | Task | Status |
| ----------- | ---- | ------ |
| T-11-07-01 | Create `app/javascript/utils/currency.js` exporting `formatCurrency` and `parseCurrency` | `[x]` |
| T-11-07-02 | Import and use `formatCurrency`/`parseCurrency` in all Stimulus controllers | `[x]` |
| T-11-07-03 | Add `onNumericFocus`/`onNumericBlur` to `order_form_controller.js` for input formatting | `[x]` |
| T-11-07-04 | Update `app/views/orders/index.html.erb` grand total column to use `number_with_precision` | `[x]` |
| T-11-07-05 | Update `app/views/orders/show.html.erb` logistic status to use `logistic_status_label` helper | `[x]` |

---

## Summary

| Metric | Count |
|--------|-------|
| Stories | 7 |
| Total Tasks | 46 |
| Completed Tasks | 43 |
| Remaining | 3 (RSpec write-ups, low priority) |

---

## Dependencies on Existing Infrastructure

| Dependency | Status | Notes |
|------------|--------|-------|
| `Product.last_price_for(product_id:, customer_id:)` | ✅ Exists | `app/models/product.rb` |
| `GET /api/v1/catalogs/products/:id/last_price/:customer_id` | ✅ Exists | `config/routes.rb` |
| `GrandTotalCalculator` service | ✅ Exists | Used in `_grand_total.html.erb` |
| `POST /api/v1/customers/filter` | ✅ Exists | Returns customer list |
| `GET /api/v1/customers/search` | ✅ Added | EPIC-11 T-11-02-01/02 |
| `Order::LOGISTIC_STATUS_LABELS` constant | ✅ Added | EPIC-11 T-11-03-01 |
| `app/javascript/utils/currency.js` | ✅ Added | EPIC-11 T-11-07-01 |
| `app/javascript/controllers/order_form_controller.js` | ✅ Added | EPIC-11 master controller |
| `app/javascript/controllers/customer_search_controller.js` | ✅ Added | EPIC-11 T-11-02-04 |
| `app/javascript/controllers/order_line_search_controller.js` | ✅ Added | EPIC-11 T-11-04-03 |
