# EPIC-10 — Tom Select Typeahead Dropdowns Across All Forms

**Phase:** 10
**Status:** 🟢 Completed
**Goal:** Every `<select>` element in the PSK ERP web UI is replaced with a Tom Select typeahead dropdown, enabling keyboard-driven search and selection for all reference-data fields (products, customers, vendors, countries, logistics companies, statuses, units).

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

### STORY-10-01 — Tom Select Infrastructure Setup
**Status:** 🟢 Completed
**Description:** Tom Select v2.4.3 is wired into the Rails importmap and Tailwind CSS pipeline so that any `<select>` can be enhanced by the `tom-select` Stimulus controller without a Node.js build step.

**User Perspective:**
As a developer, I want Tom Select available as a zero-build CDN asset, so that I can progressively enhance any `<select>` element without modifying the asset compilation pipeline.

**Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| AC-01 | The application layout is rendered | When the browser loads any page | The Tom Select CSS (`tom-select.default.min.css` from jsdelivr CDN) is included in the `<head>` |
| AC-02 | The importmap is evaluated | When `import TomSelect from "tom-select"` is executed in a Stimulus controller | The module resolves from `https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/esm/tom-select.complete.min.js` without a 404 or CORS error |
| AC-03 | The Tailwind CSS layer is compiled | When `bin/rails tailwindcss:build` runs | All `.ts-wrapper`, `.ts-control`, `.ts-dropdown` overrides are present in the compiled stylesheet |
| AC-04 | The `tom_select_controller.js` file exists | When Stimulus initialises | The controller is registered under the identifier `tom-select` and no JS console errors appear |
| AC-05 | A `<select>` has `data-controller="tom-select"` | When the DOM node is connected | `TomSelect.connect()` is called and `this.element.tomselect` is truthy |
| AC-06 | Turbo restores a cached page | When `connect()` is called a second time on the same element | The guard `if (this.element.tomselect) return` prevents double-initialisation |
| AC-07 | A page containing a Tom Select is navigated away from | When Stimulus calls `disconnect()` | `this.ts.destroy()` is called, preventing memory leaks |

**Edge Cases:**
- A `<select multiple>` must have `allowEmptyOption: false` and `closeAfterSelect: false` to remain usable.
- If no blank `<option value="">` exists, `#defaultPlaceholder()` returns `""` gracefully.

| # | Task | Status |
|---|---|---|
| T-10-01-01 | Pin `tom-select@2.4.3` from `esm.sh` CDN in `config/importmap.rb` with `preload: false` — use `esm.sh` (not jsdelivr ESM) to avoid bare specifier resolution failures for transitive deps (`@orchidjs/sifter`) | `[x]` |
| T-10-01-02 | Add Tom Select default CSS CDN `<link>` tag to `app/views/layouts/application.html.erb` | `[x]` |
| T-10-01-03 | Add Tom Select CSS overrides inside `@layer components` in `app/assets/tailwind/application.css` — covers `.ts-wrapper`, `.ts-control`, `.ts-dropdown`, `.ts-dropdown-content`, `.option`, focus states, caret arrow | `[x]` |
| T-10-01-04 | Create `app/javascript/controllers/tom_select_controller.js` — Stimulus controller using Values API (`placeholder`, `create`), `connect()`/`disconnect()` lifecycle, double-init guard, `#defaultPlaceholder()` private method | `[x]` |
| T-10-01-05 | Verify controller is auto-registered as `tom-select` via `pin_all_from "app/javascript/controllers"` in importmap | `[x]` |
| T-10-01-06 | Run `bin/rails tailwindcss:build` to compile Tom Select overrides into the production stylesheet | `[x]` |

---

### STORY-10-02 — Products Form — Tom Select Integration
**Status:** 🟢 Completed
**Description:** All four `<select>` fields on the product create/edit form (`product_type`, `vendor_id`, `brand_id`, `product_class_id`) use Tom Select typeahead so users can search reference data by typing.

**User Perspective:**
As a warehouse manager, I want to type the first few letters of a vendor or brand name when creating a product, so that I can find and select the correct option quickly without scrolling a long list.

**Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| AC-01 | The user navigates to `/products/new` | When the page loads | All four select fields render as Tom Select widgets (`.ts-wrapper` present in DOM) instead of native `<select>` elements |
| AC-02 | The user types "par" in the Product Type field | When at least one matching option exists | The dropdown narrows to options whose text contains "par" (case-insensitive) |
| AC-03 | The user selects a vendor and submits the form | When the product is valid | The product is persisted with the correct `vendor_id` and the user is redirected with a 302 |
| AC-04 | The form has a validation error | When the page re-renders with errors | Tom Select re-initialises on the re-rendered select elements and the previously selected values are preserved |
| AC-05 | The user navigates to `/products/:id/edit` | When the page loads | Each Tom Select widget shows the currently saved value as the selected item |

**Edge Cases:**
- `product_type` has only 3 options (Standalone / Parent / Child); Tom Select must not hide the dropdown when fewer than 6 options are present.
- Removing `focus:ring-*` Tailwind classes from the raw `<select>` prevents double-ring artefacts.

| # | Task | Status |
|---|---|---|
| T-10-02-01 | Add `data: { controller: "tom-select" }` to `:product_type` select in `app/views/products/_form.html.erb` | `[x]` |
| T-10-02-02 | Add `data: { controller: "tom-select" }` to `:vendor_id` collection_select in `app/views/products/_form.html.erb` | `[x]` |
| T-10-02-03 | Add `data: { controller: "tom-select" }` to `:brand_id` collection_select in `app/views/products/_form.html.erb` | `[x]` |
| T-10-02-04 | Add `data: { controller: "tom-select" }` to `:product_class_id` collection_select in `app/views/products/_form.html.erb` | `[x]` |
| T-10-02-05 | Remove `focus:outline-none focus:ring-2 focus:ring-blue-500` from all four selects (Tom Select handles focus styling) | `[x]` |

---

### STORY-10-03 — Orders Form — Tom Select Integration
**Status:** 🟢 Completed
**Description:** The four select fields on the order create/edit form (`customer_id`, `status`, `logistic_company_id`, `logistic_status`) use Tom Select so staff can quickly locate a customer or status from potentially long lists.

**User Perspective:**
As a sales operator, I want to search for a customer by name when creating an order, so that I can select the correct customer without scrolling through hundreds of records.

**Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| AC-01 | The user navigates to `/orders/new` | When the page loads | All four select fields render as Tom Select widgets |
| AC-02 | The customers list has > 50 entries | When the user types a customer name fragment | The dropdown filters in real-time showing only matching customers |
| AC-03 | The user selects a non-blank status | When the order form is submitted with valid data | The order is saved with the selected status; response is 302 |
| AC-04 | The user navigates to `/orders/:id/edit` | When the page loads | All four Tom Select widgets display the currently saved values |
| AC-05 | No logistic company is assigned | When the logistic_company_id select renders | Tom Select shows the blank placeholder ("— Select Logistic Company —") without error |

**Edge Cases:**
- `status` and `logistic_status` are enum-backed and have 4 options each; Tom Select minimum results threshold must not suppress the dropdown.

| # | Task | Status |
|---|---|---|
| T-10-03-01 | Add `data: { controller: "tom-select" }` to `:customer_id` collection_select in `app/views/orders/_form.html.erb` | `[x]` |
| T-10-03-02 | Add `data: { controller: "tom-select" }` to `:status` select in `app/views/orders/_form.html.erb` | `[x]` |
| T-10-03-03 | Add `data: { controller: "tom-select" }` to `:logistic_company_id` collection_select in `app/views/orders/_form.html.erb` | `[x]` |
| T-10-03-04 | Add `data: { controller: "tom-select" }` to `:logistic_status` select in `app/views/orders/_form.html.erb` | `[x]` |
| T-10-03-05 | Remove `focus:outline-none focus:ring-2 focus:ring-blue-500` from all four selects | `[x]` |

---

### STORY-10-04 — Customers Form — Tom Select Integration
**Status:** 🟢 Completed
**Description:** The two select fields on the customer create/edit form (`country_id` with 249 ISO countries, `logistic_company_id`) use Tom Select typeahead — the country picker is the most critical use-case given the volume of options.

**User Perspective:**
As a sales operator, I want to type a country name and select it instantly when creating a customer, so that I do not have to scroll through a 249-entry native dropdown.

**Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| AC-01 | The user navigates to `/customers/new` | When the page loads | Both select fields render as Tom Select widgets |
| AC-02 | The country list has 249 entries | When the user types "tha" | The dropdown instantly narrows to options containing "tha" (e.g. "Thailand") |
| AC-03 | The user selects Thailand (`TH`) and submits a valid form | When the form is submitted | The customer record is created with `country_id = "TH"` and the user is redirected with 302 |
| AC-04 | The user navigates to `/customers/:id/edit` | When the page loads | The country Tom Select shows the saved country name; the logistic company Tom Select shows the saved company |
| AC-05 | A customer has no logistic company | When the form renders | Tom Select shows "— Select logistic company —" placeholder without error |
| AC-06 | The form is submitted with no country selected | When the model validates | A 422 response renders the form with Tom Select re-initialised and the validation error visible |

**Edge Cases:**
- `country_id` stores the ISO 3166-1 alpha-2 code (e.g. `"TH"`), not a database integer ID. Tom Select value must reflect this.
- Countries are seeded from the `countries` gem and rendered via `options_for_select`; Tom Select must not re-sort them.

| # | Task | Status |
|---|---|---|
| T-10-04-01 | Add `data: { controller: "tom-select" }` to `:country_id` select in `app/views/customers/_form.html.erb` | `[x]` |
| T-10-04-02 | Add `data: { controller: "tom-select" }` to `:logistic_company_id` select in `app/views/customers/_form.html.erb` | `[x]` |
| T-10-04-03 | Remove `focus:outline-none focus:ring-2 focus:ring-blue-500` from both selects | `[x]` |

---

### STORY-10-05 — Order Line Fields — Tom Select Integration (Dynamic Rows)
**Status:** 🟢 Completed
**Description:** The product and unit selects inside the nested order line partial (`_order_line_fields.html.erb`) use Tom Select. Because rows are dynamically appended via Turbo Stream, the Stimulus `connect()` lifecycle ensures Tom Select initialises on every newly inserted row without extra JavaScript.

**User Perspective:**
As a sales operator, I want to search for a product by name when adding a line item to an order, so that I can quickly find the correct product from the full catalogue without scrolling.

**Acceptance Criteria:**

| # | Given | When | Then |
|---|---|---|---|
| AC-01 | The user is on `/orders/new` with an existing line row | When the page loads | The product and unit selects in the first row render as Tom Select widgets |
| AC-02 | The user clicks "Add Line Item" (Turbo Stream appends a new row) | When the new row's `<select data-controller="tom-select">` is inserted into the DOM | Stimulus detects the new node and calls `connect()`, initialising Tom Select on the new row without a page reload |
| AC-03 | The product list has > 100 entries | When the user types a product name fragment in a new line row | The dropdown filters in real-time |
| AC-04 | The user removes a line item (Turbo Stream removes the row) | When the row's DOM node is removed | Stimulus calls `disconnect()`, Tom Select calls `destroy()`, and there are no JS errors in the console |
| AC-05 | The order form is submitted | When product_id and unit are selected for each line | The order lines are persisted with the correct `product_id` and `unit` values |
| AC-06 | A line row is submitted with no product selected | When the model validates | A 422 response re-renders the form; Tom Select re-initialises on each line row |

**Edge Cases:**
- `product_id` is a `collection_select` calling `Product.order(:name)` — the query fires per row render; this is acceptable for the current scale.
- Tom Select must not conflict with the nested-form `:child_index` substitution used by the "Add Line Item" Turbo Stream mechanism.
- `sortField: { field: "$order", direction: "asc" }` preserves the server-side order (alphabetical by product name) and must not re-sort.

| # | Task | Status |
|---|---|---|
| T-10-05-01 | Add `data: { controller: "tom-select" }` to `:product_id` collection_select in `app/views/orders/_order_line_fields.html.erb` | `[x]` |
| T-10-05-02 | Add `data: { controller: "tom-select" }` to `:unit` select in `app/views/orders/_order_line_fields.html.erb` | `[x]` |
| T-10-05-03 | Remove `focus:outline-none focus:ring-1 focus:ring-blue-500` from both selects | `[x]` |
| T-10-05-04 | Verify Stimulus auto-connects on Turbo Stream DOM insertion by navigating to `/orders/new`, clicking "Add Line Item", and confirming Tom Select renders on the new row | `[x]` |
