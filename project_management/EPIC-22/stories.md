# EPIC-22 — Production-Ready UI Consistency

**Phase:** 22
**Status:** 🟡 In Progress
**Goal:** Every core-module page (Orders, Invoices, Products, Customers, Purchase Orders, Users, Dashboard) follows a single, documented design token system — consistent headings, button colours, row-action colours, back navigation, and secondary button styles — and the entire application supports both English (EN) and Thai (TH) via Rails i18n with a per-user language preference switcher covering page titles, table header columns, status badges, form field labels, form section headings, show/detail page field labels, placeholder text, and empty-state messages — so the application is fully bilingual and production-quality before user rollout.

---

## Legend

| Symbol           | Meaning                  |
| ---------------- | ------------------------ |
| 🔴 Not Started   | Work has not begun       |
| 🟡 In Progress   | Actively being worked on |
| 🟢 Completed     | Done and verified        |
| `[ ]`            | Task not started         |
| `[~]`            | Task in progress         |
| `[x]`            | Task completed           |

---

## Design Token Reference (source of truth for all stories below)

The following component classes will be defined in `app/assets/tailwind/application.css` under `@layer components` and used across all core views.

| Class              | @apply value                                                                                                  | Usage                                      |
| ------------------ | ------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| `.btn-primary`     | `inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 transition-colors` | Primary CTA — "New X", "Save", "Confirm"  |
| `.btn-secondary`   | `inline-flex items-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 text-sm font-medium rounded-md hover:bg-gray-200 transition-colors` | Utility — "Duplicate", "View Lots", "Print" |
| `.btn-danger`      | `inline-flex items-center gap-2 px-4 py-2 bg-red-600 text-white text-sm font-medium rounded-md hover:bg-red-700 transition-colors` | Destructive — "Cancel Invoice", "Delete"  |
| `.btn-outline`     | `inline-flex items-center gap-2 px-4 py-2 border border-gray-300 text-gray-700 text-sm font-medium rounded-md hover:bg-gray-50 transition-colors` | Form cancel, "Edit Remark"                |
| `.btn-sm-primary`  | `inline-flex items-center gap-1 px-3 py-1.5 bg-blue-600 text-white text-sm font-medium rounded-md hover:bg-blue-700 transition-colors` | Small primary — bulk action bar           |
| `.btn-sm-secondary`| `inline-flex items-center gap-1 px-3 py-1.5 bg-gray-100 text-gray-700 text-sm font-medium rounded-md hover:bg-gray-200 transition-colors` | Small secondary — bulk action bar         |
| `.page-heading`    | `text-2xl font-bold text-gray-900`                                                                            | `<h1>` on every show page                 |
| `.section-heading` | `text-sm font-semibold text-gray-700`                                                                         | `<h2>` section titles inside cards        |
| `.back-link`       | `inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 transition-colors`                 | "← Back" navigation on show/edit pages   |
| `.row-action-primary` | `text-blue-600 hover:underline text-xs`                                                                    | Row "View", "Edit", "Detail"              |
| `.row-action-muted`   | `text-gray-500 hover:underline text-xs`                                                                    | Row "Print", "Images", secondary row link |
| `.row-action-danger`  | `text-red-600 hover:underline text-xs bg-transparent border-none cursor-pointer p-0`                      | Row "Delete"                              |

---

## Stories

### STORY-22-01 — Design Token Component CSS Classes

**Status:** 🟢 Completed
**Description:** Define all shared component classes in the Tailwind application CSS file so that every subsequent story can reference them by name rather than repeating long utility strings.

**User Perspective:**
As a developer, I want a single source-of-truth CSS component class file, so that changing a button style requires editing one definition instead of hunting across 20 templates.

**Acceptance Criteria:**

| #     | Given                                                                      | When                                                         | Then                                                                                                                                          |
| ----- | -------------------------------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | All token classes are defined in `app/assets/tailwind/application.css`    | `bin/rails tailwindcss:build` runs                           | The command exits 0 and `app/assets/builds/app.css` contains the string `.btn-primary`                                                       |
| AC-02 | The Tailwind CSS build has been run                                        | A request spec sends `GET /assets/app.css`                   | The response is HTTP 200 and the body includes `.btn-primary`                                                                                 |
| AC-03 | A page renders a button with `class="btn-primary"`                         | A request spec fetches that page                             | The response body includes the string `class="btn-primary"` (HTML attribute presence check, not computed style)                              |
| AC-04 | A page renders an element with `class="row-action-danger"`                | A request spec fetches that page                             | The response body includes the string `class="row-action-danger"` (HTML attribute presence check, not computed style)                        |
| AC-05 | An `@apply` directive references a non-existent Tailwind utility class     | `bin/rails tailwindcss:build` runs                           | The build exits with a non-zero exit code and logs an error message referencing the unknown utility                                           |

**Edge Cases:**

- Adding a new `@layer components` block must not break the existing pagination and Tom Select `@layer components` rules already present in the file.
- The `@apply` chain for each token must only reference utility classes that Tailwind CSS generates from the current config; no unknown utilities.

| #          | Task                                                                                                                                                                                                                        | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-01-01 | Add `.btn-primary`, `.btn-secondary`, `.btn-danger`, `.btn-outline`, `.btn-sm-primary`, `.btn-sm-secondary` to `@layer components` in `app/assets/tailwind/application.css` using `@apply`                                  | `[x]`  |
| T-22-01-02 | Add `.page-heading`, `.section-heading`, `.back-link` to the same `@layer components` block                                                                                                                                 | `[x]`  |
| T-22-01-03 | Add `.row-action-primary`, `.row-action-muted`, `.row-action-danger` to the same `@layer components` block                                                                                                                  | `[x]`  |
| T-22-01-04 | Run `bin/rails tailwindcss:build` and confirm exit 0; verify `.btn-primary` appears in `app/assets/builds/app.css`                                                                                                          | `[x]`  |
| T-22-01-05 | Write RSpec request spec `spec/requests/assets/button_tokens_spec.rb`: `GET /assets/app.css` returns 200 and body includes `.btn-primary`, `.btn-secondary`, `.btn-danger`, `.btn-outline`, `.btn-sm-primary`, `.btn-sm-secondary` | `[x]`  |
| T-22-01-06 | Write RSpec request spec `spec/requests/assets/typography_tokens_spec.rb`: `GET /assets/app.css` returns 200 and body includes `.page-heading`, `.section-heading`, `.back-link`                                            | `[x]`  |
| T-22-01-07 | Write RSpec request spec `spec/requests/assets/row_action_tokens_spec.rb`: `GET /assets/app.css` returns 200 and body includes `.row-action-primary`, `.row-action-muted`, `.row-action-danger`                             | `[x]`  |

---

### STORY-22-02 — Standardize Index Page Row Actions and CTA Labels

**Status:** 🟢 Completed
**Description:** All index pages in the core modules use the same row-action colour conventions (View/Edit=blue, Print=gray, Delete=red) and the primary CTA button follows the "New X" naming pattern.

**User Perspective:**
As a user, I want every list page to have the same link colours and button labels, so that I can reliably know that blue means "go to" and red means "delete" without re-learning each page.

**Acceptance Criteria:**

| #     | Given                                                                | When                          | Then                                                                                                                              |
| ----- | -------------------------------------------------------------------- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | An authenticated user with `view_orders` visits `GET /orders`       | The page renders              | The "Edit" row action has class `row-action-primary` and the "Print" row action has class `row-action-muted` in the response body |
| AC-02 | An authenticated user with `view_invoices` visits `GET /invoices`   | The page renders              | The CTA button label is "New Invoice" (not "Create Invoice") and has class `btn-primary` in the response body                    |
| AC-03 | An authenticated user with `view_products` visits `GET /products`   | The page renders              | The "Stock" row action has class `row-action-primary` and "Images" has class `row-action-muted` in the response body             |
| AC-04 | An authenticated user with `view_orders` visits `GET /orders`       | The page renders              | Every "Delete" row action in the response body has class `row-action-danger`                                                     |
| AC-05 | An authenticated user with `view_orders` visits `GET /orders`       | The page renders              | The "New Order" button has class `btn-primary` in the response body                                                              |
| AC-06 | An unauthenticated request is made to `GET /orders`                 | The request is processed      | The response is HTTP 302 redirect to the login page                                                                               |

**Edge Cases:**

- The orders index bulk action bar contains `.btn-sm-primary` and `.btn-sm-secondary` variants (smaller padding); these must not be changed to full-size `.btn-primary`.
- The "Clear" filter link must remain as a plain text-only link (`text-sm text-gray-500 hover:underline`), not a button component class.

| #          | Task                                                                                                                                                                                                                              | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-02-01 | `app/views/orders/index.html.erb`: change "Edit" row class to `row-action-primary`; change "Print" row class to `row-action-muted`; apply `btn-primary` to "New Order" button                                                    | `[x]`  |
| T-22-02-02 | Write RSpec request spec `spec/requests/orders/index_ui_spec.rb`: body includes `btn-primary` on New Order, `row-action-primary` on Edit, `row-action-muted` on Print, `row-action-danger` on Delete                            | `[x]`  |
| T-22-02-03 | `app/views/invoices/index.html.erb`: rename CTA label "Create Invoice" → "New Invoice"; apply `btn-primary` to that button                                                                                                       | `[x]`  |
| T-22-02-04 | Write RSpec request spec `spec/requests/invoices/index_ui_spec.rb`: body includes "New Invoice", `btn-primary`, `row-action-danger` on Delete                                                                                   | `[x]`  |
| T-22-02-05 | `app/views/products/index.html.erb`: change "Stock" row class to `row-action-primary`; change "Images" row class to `row-action-muted`; apply `btn-primary` to "New Product"                                                     | `[x]`  |
| T-22-02-06 | Write RSpec request spec `spec/requests/products/index_ui_spec.rb`: body includes `btn-primary` on New Product, `row-action-primary` on Stock, `row-action-muted` on Images, `row-action-danger` on Delete                      | `[x]`  |
| T-22-02-07 | `app/views/customers/index.html.erb`: apply `btn-primary` to "New Customer"; ensure "Delete" rows use `row-action-danger`                                                                                                        | `[x]`  |
| T-22-02-08 | Write RSpec request spec `spec/requests/customers/index_ui_spec.rb`: body includes `btn-primary`, `row-action-danger`                                                                                                            | `[x]`  |
| T-22-02-09 | `app/views/users/index.html.erb`: apply `btn-primary` to "New User"; ensure "Delete" rows use `row-action-danger`                                                                                                                | `[x]`  |
| T-22-02-10 | Write RSpec request spec `spec/requests/users/index_ui_spec.rb`: body includes `btn-primary`, `row-action-danger`                                                                                                                | `[x]`  |
| T-22-02-11 | `app/views/purchase_orders/index.html.erb`: apply `btn-primary` to "New Purchase Order"; ensure "Delete" rows use `row-action-danger`                                                                                            | `[x]`  |
| T-22-02-12 | Write RSpec request spec `spec/requests/purchase_orders/index_ui_spec.rb`: body includes `btn-primary`, `row-action-danger`                                                                                                      | `[x]`  |

---

### STORY-22-03 — Standardize Show Page Headings and Back Navigation

**Status:** 🟢 Completed
**Description:** All show pages use `page-heading` (text-2xl font-bold) for the `<h1>` element and a labelled "← Back" link instead of an icon-only back arrow.

**User Perspective:**
As a user, I want every detail page to have the same heading size and a visible back link, so that I know where I am and can navigate up without hunting for an icon.

**Acceptance Criteria:**

| #     | Given                                         | When                           | Then                                                                                                                  |
| ----- | --------------------------------------------- | ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| AC-01 | I visit `GET /orders/:id`                     | The page renders               | The `<h1>` element has class `page-heading` and the text is the order number                                         |
| AC-02 | I visit `GET /invoices/:id`                   | The page renders               | The `<h1>` element has class `page-heading`                                                                           |
| AC-03 | I visit `GET /products/:id`                   | The page renders               | The `<h1>` element has class `page-heading` (already `text-2xl font-bold`; replace with token class)                |
| AC-04 | I visit `GET /purchase_orders/:id`            | The page renders               | The `<h1>` element has class `page-heading`                                                                           |
| AC-05 | I visit any of the four show pages above      | The page renders               | The back navigation link contains the text "← Back" and has class `back-link`; there is no icon-only back arrow      |
| AC-06 | I visit `GET /orders/:id` for a non-existent order | The request is made       | The response is HTTP 404                                                                                              |

**Edge Cases:**

- `orders/show` currently uses `p-4 md:p-6` for the outer wrapper while others use `p-6`; standardize to `p-6` as part of this story.
- The back link destination for each page: orders/show → `orders_path`; invoices/show → `invoices_path`; products/show → `products_path`; purchase_orders/show → `purchase_orders_path`.
- Section sub-headings (`<h2>`) should use `.section-heading` instead of inline `text-sm font-semibold text-gray-700`.

| #          | Task                                                                                                                                                           | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-03-01 | `app/views/orders/show.html.erb`: replace `<h1 class="text-xl font-semibold text-gray-900">` with `class="page-heading"`; replace icon-only back with `<%= link_to "← Back", orders_path, class: "back-link" %>`; change outer `p-4 md:p-6` to `p-6` | `[x]`  |
| T-22-03-02 | `app/views/invoices/show.html.erb`: replace h1 class with `page-heading`; replace icon-only back with `<%= link_to "← Back", invoices_path, class: "back-link" %>` | `[x]`  |
| T-22-03-03 | `app/views/products/show.html.erb`: replace h1 inline classes with `page-heading`; replace icon-only back with `<%= link_to "← Back", products_path, class: "back-link" %>` | `[x]`  |
| T-22-03-04 | `app/views/purchase_orders/show.html.erb`: replace h1 class with `page-heading`; replace icon-only back with `<%= link_to "← Back", purchase_orders_path, class: "back-link" %>`; standardize section heading `<h2>` to `section-heading` | `[x]`  |
| T-22-03-05 | Write RSpec request spec `spec/requests/orders/show_heading_spec.rb`: body includes `page-heading`, "← Back", `back-link`                                    | `[x]`  |
| T-22-03-06 | Write RSpec request spec `spec/requests/invoices/show_heading_spec.rb`: body includes `page-heading`, "← Back", `back-link`                                  | `[x]`  |
| T-22-03-07 | Write RSpec request spec `spec/requests/products/show_heading_spec.rb`: body includes `page-heading`, "← Back", `back-link`                                  | `[x]`  |
| T-22-03-08 | Write RSpec request spec `spec/requests/purchase_orders/show_heading_spec.rb`: body includes `page-heading`, "← Back", `back-link`                           | `[x]`  |
| T-22-03-09 | Replace all inline `text-sm font-semibold text-gray-700` section heading classes in the four show pages with the `section-heading` token class               | `[x]`  |
| T-22-03-10 | Write RSpec request spec `spec/requests/ui/section_heading_spec.rb`: each of the four show pages includes the string `section-heading` in the response body  | `[x]`  |

---

### STORY-22-04 — Standardize Secondary and Utility Buttons on Show Pages

**Status:** 🟢 Completed
**Description:** Utility/secondary buttons on show pages (non-destructive, non-primary actions such as "Duplicate", "Print Invoice", "View Lots", "Edit Remark") consistently use `.btn-secondary` (gray filled) or `.btn-outline` (for form-level cancel/edit within inline forms). Destructive actions ("Cancel Invoice", "Delete") use `.btn-danger`.

**User Perspective:**
As a user, I want to instantly distinguish between primary actions (blue), utility actions (gray), and dangerous actions (red) on a detail page, so that I don't accidentally click a destructive button.

**Acceptance Criteria:**

| #     | Given                                                           | When                        | Then                                                                                                                             |
| ----- | --------------------------------------------------------------- | --------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | I visit `GET /orders/:id`                                       | The page renders            | "Duplicate" button has class `btn-secondary`; "Edit Order" has class `btn-primary`                                               |
| AC-02 | I visit `GET /invoices/:id`                                     | The page renders            | "Print Invoice" has class `btn-secondary`; "Cancel Invoice" has class `btn-danger`; "Mark as Paid" has class `btn-primary`      |
| AC-03 | I visit `GET /products/:id`                                     | The page renders            | "View Lots" and "Duplicate" buttons have class `btn-secondary`; "Edit" has class `btn-primary`                                  |
| AC-04 | I visit `GET /purchase_orders/:id`                              | The page renders            | "Edit" button has class `btn-outline`; "Confirm PO" has class `btn-primary`; "Delete" has class `btn-danger`                   |
| AC-05 | I visit `GET /invoices/:id` where invoice status is `cancelled` | The page renders            | The "Cancel Invoice" button is not rendered (no regression on conditional rendering)                                             |
| AC-06 | I visit `GET /orders/:id` without permission                    | The request is made         | The response is HTTP 302 (no regression)                                                                                         |

**Edge Cases:**

- `invoices/show` has a "Reopen to Draft" button (indigo-600) — this is a state-change action; classify as `.btn-secondary` since it's a recovery flow rather than a primary creation action.
- `invoices/show` "Edit Remark" opens an inline Turbo Frame form; the button must stay as `.btn-outline` to visually signal it edits inline rather than navigating away.
- Small-size upload buttons (`px-3 py-1.5`) should use `.btn-sm-primary` or `.btn-sm-secondary` appropriately, not full-size `.btn-primary`.

| #          | Task                                                                                                                                                                               | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-04-01 | `app/views/orders/show.html.erb`: apply `btn-primary` to "Edit Order"; apply `btn-secondary` to "Duplicate"; apply `btn-sm-primary` to "Upload" image button                      | `[x]`  |
| T-22-04-02 | `app/views/invoices/show.html.erb`: apply `btn-secondary` to "Print Invoice" and "Reopen to Draft"; apply `btn-primary` to "Mark as Paid"; apply `btn-danger` to "Cancel Invoice"; apply `btn-outline` to "Edit Remark"; apply `btn-sm-primary` to "Add Orders" and "Upload" | `[x]`  |
| T-22-04-03 | `app/views/products/show.html.erb`: apply `btn-primary` to "Edit"; apply `btn-secondary` to "View Lots" and "Duplicate"; apply `btn-sm-primary` to "Upload Image"                 | `[x]`  |
| T-22-04-04 | `app/views/purchase_orders/show.html.erb`: apply `btn-primary` to "Confirm PO"; apply `btn-outline` to "Edit"; apply `btn-danger` to "Delete"                                    | `[x]`  |
| T-22-04-05 | Write RSpec request spec `spec/requests/orders/show_buttons_spec.rb`: body includes `btn-primary` (Edit Order), `btn-secondary` (Duplicate), `btn-sm-primary` (Upload)                                              | `[x]`  |
| T-22-04-06 | Write RSpec request spec `spec/requests/invoices/show_buttons_spec.rb`: body includes `btn-primary` (Mark as Paid), `btn-secondary` (Print Invoice, Reopen to Draft), `btn-danger` (Cancel Invoice), `btn-outline` (Edit Remark) | `[x]`  |
| T-22-04-07 | Write RSpec request spec `spec/requests/products/show_buttons_spec.rb`: body includes `btn-primary` (Edit), `btn-secondary` (View Lots, Duplicate)                                                                  | `[x]`  |
| T-22-04-08 | Write RSpec request spec `spec/requests/purchase_orders/show_buttons_spec.rb`: body includes `btn-primary` (Confirm PO), `btn-outline` (Edit), `btn-danger` (Delete)                                                | `[x]`  |

---

### STORY-22-05 — Dashboard Button Palette and CSS Rebuild Verification

**Status:** 🟢 Completed
**Description:** The Dashboard page's admin quick-link buttons and report buttons are aligned to the shared design token system, removing the one-off purple palette and soft blue variants. A final CSS rebuild is run and smoke-tested across all five core index pages.

**User Perspective:**
As a user, I want the Dashboard to use the same button colours as every other page, so that the app looks unified from the very first screen.

**Acceptance Criteria:**

| #     | Given                              | When                  | Then                                                                                                                                      |
| ----- | ---------------------------------- | --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | I visit `GET /`                    | The page renders      | "Customer Report" and "Sales Report" buttons have class `btn-primary` (blue, no purple)                                                   |
| AC-02 | I visit `GET /`                    | The page renders      | "Manage Users", "Manage Roles", and "My Profile" quick-link buttons have class `btn-secondary` (gray filled)                             |
| AC-03 | I visit `GET /`                    | The page renders      | No element on the page has a Tailwind colour class in the `purple-*` family (e.g. `bg-purple-600`, `bg-purple-50`, `text-purple-700`)    |
| AC-04 | `bin/rails tailwindcss:build` is run after STORY-22-05 changes | The command completes | The command exits 0 with no CSS compilation errors                                                                                        |
| AC-05 | An authenticated user with appropriate permissions visits each of the five core index pages | Each page renders | HTTP 200 for each; response bodies for `GET /orders`, `/invoices`, `/products`, `/purchase_orders`, and `/users` do not include `bg-purple-600`, `bg-purple-50`, or `text-purple-700` |
| AC-06 | I visit `GET /` unauthenticated    | The request is made   | The response is HTTP 302 redirect to login (no regression)                                                                                |

**Edge Cases:**

- Status badges (e.g. `bg-green-100 text-green-800`) use green/yellow/red semantic colours — these are intentional status semantics and must NOT be changed to the button palette.
- The dashboard page uses an inline `<script>` for Chart.js; this story does not touch JS, only button classes.
- After the Tailwind rebuild, confirm the delivery order print page (`/orders/:id/delivery_order`) is not affected (it uses a `<style>` block, not Tailwind build output).

| #          | Task                                                                                                                                                                             | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-05-01 | `app/views/dashboard/index.html.erb`: apply `btn-secondary` to "Manage Users", "Manage Roles", "My Profile"; apply `btn-primary` to "Customer Report" and "Sales Report"        | `[x]`  |
| T-22-05-02 | Run `bin/rails tailwindcss:build` and confirm exit 0                                                                                                                             | `[x]`  |
| T-22-05-03 | Write RSpec request spec `spec/requests/dashboard/ui_consistency_spec.rb`: (a) `GET /` returns 200, (b) body includes `btn-primary` and `btn-secondary`, (c) body does NOT include `bg-purple-600` or `text-purple-700`   | `[x]`  |
| T-22-05-04 | Write RSpec request spec `spec/requests/ui/no_purple_spec.rb`: authenticated requests to `GET /orders`, `/invoices`, `/products`, `/purchase_orders`, `/users` each return 200 and none of the response bodies include `bg-purple-600` | `[x]`  |
| T-22-05-05 | Write RSpec request spec `spec/requests/assets/css_rebuild_spec.rb`: `GET /assets/app.css` returns 200 and body includes `btn-primary` (confirms post-rebuild asset is served)                                              | `[x]`  |
| T-22-05-06 | Manual smoke-test: visit Orders, Invoices, Products, Purchase Orders, Users, Dashboard in browser after rebuild; confirm no visual regressions                                                                               | `[ ]`  |

---

### STORY-22-06 — i18n Infrastructure: Rails Config, Locale Files Skeleton, and Locale Switcher

**Status:** 🟢 Completed
**Description:** Set up the complete Rails i18n foundation: configure the app to support `:en` and `:th` locales with `:th` as default, store the user's preferred locale on their `Profile` record, resolve locale from user preference on every request, and expose a language toggle button (EN / TH) in the application header.

**User Perspective:**
As a user, I want to click a language toggle in the header and have the entire application immediately switch between English and Thai, so that I can use the system in my preferred language without changing any browser settings.

**Acceptance Criteria:**

| #     | Given                                                                       | When                                                                   | Then                                                                                                                                                   |
| ----- | --------------------------------------------------------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | `config/application.rb` is updated                                          | The Rails app boots                                                    | `I18n.available_locales` returns `[:th, :en]` and `I18n.default_locale` returns `:th`                                                                 |
| AC-02 | A user is logged in with no saved locale preference                         | Any page is requested                                                  | `I18n.locale` is `:th` (default)                                                                                                                       |
| AC-03 | A logged-in user's `Profile#preferred_locale` is `"en"`                    | Any page is requested                                                  | `I18n.locale` is `:en` for the duration of that request                                                                                                |
| AC-04 | A logged-in user with `preferred_locale = "th"` clicks the "EN" toggle in the header | A `PATCH /locale` request is sent with `{ locale: "en" }` | `Profile#preferred_locale` is updated to `"en"` in the database; the response is HTTP 302 redirect back to the referring page; a follow-up `GET` request to any page by the same user returns a response body that includes an English-translated string (e.g. "Orders" in the navigation) |
| AC-05 | A logged-in user clicks the "TH" toggle button                             | A `PATCH /locale` request is sent with `{ locale: "th" }`             | `Profile#preferred_locale` is updated to `"th"`; the locale changes back to `:th`                                                                     |
| AC-06 | An unauthenticated request arrives                                          | Any page is requested                                                  | `I18n.locale` falls back to `:th` (default); no error is raised                                                                                       |
| AC-07 | `{ locale: "fr" }` (unsupported locale) is submitted to `PATCH /locale`   | The request is processed                                               | The locale is rejected; `Profile#preferred_locale` is NOT updated; the response is HTTP 422                                                            |

**Edge Cases:**

- The `preferred_locale` column must have a DB-level check constraint to only allow `"en"` and `"th"`.
- The locale must be set in `ApplicationController` as a `before_action` that runs before all other actions, including Devise flows.
- Unauthenticated users (Devise sign-in, sign-up pages) must still render correctly using the `:th` default.
- The language toggle must not render on the print layout (`layouts/print.html.erb`).

| #          | Task                                                                                                                                                                                               | Status |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-06-01 | Write migration `add_preferred_locale_to_profiles`: add column `preferred_locale string default "th" not null` with a check constraint `IN ('th', 'en')` to the `profiles` table                 | `[x]`  |
| T-22-06-02 | Run `rails db:migrate` and verify schema                                                                                                                                                           | `[x]`  |
| T-22-06-03 | In `config/application.rb`, set `config.i18n.available_locales = %i[th en]` and `config.i18n.default_locale = :th`                                                                               | `[x]`  |
| T-22-06-04 | Add `before_action :set_locale` to `ApplicationController`; implement `set_locale` to read `current_user&.profile&.preferred_locale` and call `I18n.locale = locale`; fall back to `:th`         | `[x]`  |
| T-22-06-05 | Add `validates :preferred_locale, inclusion: { in: %w[th en] }` to `Profile` model                                                                                                               | `[x]`  |
| T-22-06-06 | Create `LocalesController` with a single `update` action: route `PATCH /locale`, params `{ locale: String }`, on success updates `current_user.profile.preferred_locale` and responds HTTP 302 redirect to `request.referer || root_path`; on invalid locale responds HTTP 422 with an HTML flash alert | `[x]`  |
| T-22-06-07 | Add `patch "/locale", to: "locales#update", as: :locale` to `config/routes.rb`                                                                                                                   | `[x]`  |
| T-22-06-08 | Add language toggle to `app/views/layouts/_header.html.erb`: two small buttons "TH" and "EN" with active state highlighted (blue text / underline); each submits a form to `PATCH /locale`       | `[x]`  |
| T-22-06-09 | Write RSpec model spec `spec/models/profile_spec.rb`: validates `preferred_locale` inclusion in `%w[th en]`; confirms `"fr"` is rejected with a validation error                                  | `[x]`  |
| T-22-06-10 | Write RSpec request spec `spec/requests/locales_spec.rb`: (a) `PATCH /locale` with `{ locale: "en" }` updates `Profile#preferred_locale` to `"en"` and responds HTTP 302; (b) `PATCH /locale` with `{ locale: "fr" }` responds HTTP 422 and does not update profile; (c) unauthenticated `PATCH /locale` responds HTTP 302 redirect to login | `[x]`  |
| T-22-06-11 | Write RSpec request spec asserting locale resolution: a `GET /` request from a user with `preferred_locale = "en"` returns 200 and the response body includes "Orders" (English nav label, not "ออเดอร์") | `[x]`  |
| T-22-06-12 | Write RSpec request spec `spec/requests/layouts/header_locale_toggle_spec.rb`: authenticated `GET /` response body includes both the text "TH" and the text "EN" within the header markup        | `[x]`  |
| T-22-06-13 | Write RSpec model spec asserting `Profile` has a `preferred_locale` database column defaulting to `"th"`: create a profile without specifying `preferred_locale` and assert `profile.preferred_locale == "th"` | `[x]`  |

---

### STORY-22-07 — Thai and English Locale Files for Shared Layout and Navigation

**Status:** 🟢 Completed
**Description:** Create `config/locales/th.yml` and populate `config/locales/en.yml` with all translation keys for the shared layout (header, sidebar navigation labels, flash message strings, and common UI chrome). Replace all hardcoded strings in these partials with `t()` calls.

**User Perspective:**
As a user, when I switch to Thai, all navigation labels, section group names, and common UI text appear in Thai; when I switch to English, they all appear in English — without any mixed-language text.

**Acceptance Criteria:**

| #     | Given                                                                    | When                                                     | Then                                                                                                                                    |
| ----- | ------------------------------------------------------------------------ | -------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A user with `preferred_locale = "th"` is signed in                      | They visit any page                                      | The sidebar navigation labels render in Thai (e.g. "แดชบอร์ด", "ออเดอร์", "ใบแจ้งหนี้", "ใบสั่งซื้อ", "สินค้า")                     |
| AC-02 | A user with `preferred_locale = "en"` is signed in                      | They visit any page                                      | The sidebar navigation labels render in English (e.g. "Dashboard", "Orders", "Invoices", "Purchase Orders", "Products")                |
| AC-03 | A user with `preferred_locale = "en"` triggers a not-authorized redirect | The redirect fires with `alert:`                        | The flash alert text is in English: "You are not authorized to perform this action."                                                    |
| AC-04 | A user with `preferred_locale = "th"` triggers a not-authorized redirect | The redirect fires with `alert:`                        | The flash alert text is in Thai: "คุณไม่มีสิทธิ์ดำเนินการนี้"                                                                        |
| AC-05 | Both locale YAML files exist and a user with `preferred_locale = "th"` is signed in | They visit any page | The response body includes "ออเดอร์" in the sidebar navigation section                                                                  |
| AC-06 | Both locale YAML files exist and a user with `preferred_locale = "en"` is signed in | They visit any page | The response body includes "Orders" in the sidebar navigation section                                                                    |

**Edge Cases:**

- Catalog group sub-links (Products, Brands, Product Classes, etc.) and Settings group sub-links (Users, Roles, Branches, etc.) must all have translations in both locales.
- The Devise layout (`layouts/devise.html.erb`) does not use the sidebar; its login/sign-in form label translations are managed separately by the `config/locales/devise.en.yml` — do NOT override Devise keys in this story.
- The delivery order print layout (`layouts/print.html.erb`) must NOT have `t()` calls added — that document is always Thai by design.

**Translation key structure (both locales must define all keys under these namespaces):**

```yaml
nav:
  dashboard, orders, invoices, purchase_orders, catalog, products, brands,
  product_classes, product_categories, attributes, vendors, unit_groups,
  stock_locations, settings, users, roles, branches, company_settings, countries,
  logistic_companies, customers, stocks, suppliers
common:
  new, edit, delete, save, cancel, back, search, clear, confirm, print, upload,
  view, detail, duplicate, yes, no
flash:
  not_authorized, record_referenced, saved, deleted, updated
```

| #          | Task                                                                                                                                                                                          | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-07-01 | Create `config/locales/th.yml` with all keys under the `nav:` namespace (Thai values for all 23 nav items listed in the key structure above)                                                  | `[x]`  |
| T-22-07-02 | Add all keys under `common:` and `flash:` namespaces to `config/locales/th.yml` (Thai values)                                                                                                 | `[x]`  |
| T-22-07-03 | Populate `config/locales/en.yml` with all keys under `nav:`, `common:`, and `flash:` namespaces (English values) — replacing the placeholder `hello: "Hello world"`                          | `[x]`  |
| T-22-07-04 | Replace all hardcoded nav label strings in `app/views/layouts/_sidebar.html.erb` with `t("nav.KEY")` calls                                                                                    | `[x]`  |
| T-22-07-05 | Replace the hardcoded `"You are not authorized."` string in `ApplicationController#user_not_authorized` with `t("flash.not_authorized")`                                                      | `[x]`  |
| T-22-07-06 | Replace hardcoded `"record referenced by other"` flash string in `ApplicationController#record_referenced_by_other` with `t("flash.record_referenced")`                                      | `[x]`  |
| T-22-07-07 | Write RSpec request spec `spec/requests/i18n/sidebar_i18n_spec.rb`: (a) TH user — response body includes "ออเดอร์"; (b) EN user — response body includes "Orders"                            | `[x]`  |
| T-22-07-08 | Write RSpec request spec `spec/requests/i18n/flash_not_authorized_spec.rb`: EN user triggers not-authorized → flash alert includes "not authorized"; TH user → flash alert includes "ไม่มีสิทธิ์" | `[x]`  |
| T-22-07-09 | Write RSpec request spec `spec/requests/i18n/flash_record_referenced_spec.rb`: EN user triggers record-referenced error → flash alert is in English; TH user → flash alert is in Thai       | `[x]`  |

---

### STORY-22-08 — Thai and English Translations for Core Module Pages

**Status:** 🟢 Completed
**Description:** All visible UI text on core module index and show pages (page headings, table column headers, form field labels, button labels, empty state messages, status badge text) is extracted into `t()` calls and translated in both `th.yml` and `en.yml`. Modules in scope: Orders, Invoices, Products, Customers, Purchase Orders, Users, Dashboard.

**User Perspective:**
As a user, when I switch to Thai, every page title, table header, button, and form label in the Orders, Invoices, Products, Customers, Purchase Orders, Users, and Dashboard modules appears in Thai; when I switch to English, they all appear in English.

**Acceptance Criteria:**

| #     | Given                                                                     | When                                         | Then                                                                                                                                                  |
| ----- | ------------------------------------------------------------------------- | -------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A user with `preferred_locale = "th"` visits `GET /orders`               | The page renders                             | The `<h1>` text is "ออเดอร์", the "New Order" button reads "สร้างออเดอร์", the table header "Status" reads "สถานะ"                                  |
| AC-02 | A user with `preferred_locale = "en"` visits `GET /orders`               | The page renders                             | The `<h1>` text is "Orders", the button reads "New Order", the table header reads "Status"                                                            |
| AC-03 | A user with `preferred_locale = "th"` visits `GET /invoices`             | The page renders                             | The `<h1>` text is "ใบแจ้งหนี้", the CTA button reads "สร้างใบแจ้งหนี้"                                                                             |
| AC-04 | A user with `preferred_locale = "th"` visits `GET /products`             | The page renders                             | The `<h1>` text is "สินค้า", the "New Product" button reads "เพิ่มสินค้า"                                                                           |
| AC-05 | A user with `preferred_locale = "th"` visits `GET /customers`            | The page renders                             | The `<h1>` text is "ลูกค้า", the "New Customer" button reads "เพิ่มลูกค้า"                                                                          |
| AC-06 | A user with `preferred_locale = "th"` visits `GET /purchase_orders`      | The page renders                             | The `<h1>` text is "ใบสั่งซื้อ"                                                                                                                     |
| AC-07 | A user with `preferred_locale = "th"` visits `GET /users`                | The page renders                             | The `<h1>` text is "ผู้ใช้งาน", the "New User" button reads "เพิ่มผู้ใช้งาน"                                                                       |
| AC-08 | A user with `preferred_locale = "th"` visits the Dashboard               | The page renders                             | The `<h1>` text is "แดชบอร์ด"                                                                                                                       |
| AC-09 | A user with `preferred_locale = "en"` visits `GET /orders/:id`           | The page renders                             | The back navigation link reads "← Back" and the Order Lines section heading reads "Order Lines"                                       |
| AC-10 | A user with `preferred_locale = "th"` visits `GET /orders/:id`           | The page renders                             | The back navigation link reads "← กลับ" and the Order Lines section heading renders in Thai                                          |
| AC-11 | A user with `preferred_locale = "en"` visits `GET /orders`               | The page renders                             | The response body does not contain the string `[missing "en` (the Rails missing-translation marker)                                  |

**Edge Cases:**

- Status badge values (e.g. "Draft", "Confirmed", "Paid", "Cancelled") must be translated. Define them under `orders.status.*` and `invoices.status.*` in both locale files.
- Order form section labels (some already in Thai, e.g. หมายเหตุ) must be normalised through `t()` — do not hardcode Thai directly in ERB after this story.
- The delivery order print view (`orders/delivery_order.html.erb`) is **explicitly excluded** — it is an always-Thai physical document.
- Form error messages (generated by ActiveRecord validations) are handled by the Rails built-in `activerecord:` i18n namespace — add `activerecord.errors` keys to both locale files for common errors (blank, too_long, taken, invalid).
- Pagination "Next / Previous" labels are controlled by the Pagy `@layer components` CSS — add `pagy:` keys to both locale files if Pagy's built-in i18n support is not already wired.

**Locale key structure for module pages (both locales must define all keys):**

```yaml
orders:
  title, new, status: { draft, confirmed, cancelled, ... }
  table: { no, quantity, unit, description, unit_price, total, status, customer, date, actions }
  show: { order_lines, summary, images, signatures }
invoices:
  title, new, table: { no, order_no, customer, total, status, date, actions }
  status: { draft, sent, paid, cancelled }
products:
  title, new, table: { sku, name, brand, category, cost, actions }
customers:
  title, new, table: { name, phone, address, actions }
purchase_orders:
  title, new, table: { no, supplier, date, lines, status, actions }
users:
  title, new, table: { name, email, role, status, actions }
dashboard:
  title, welcome
common:
  (already defined in STORY-22-07)
```

| #          | Task                                                                                                                                                                                                                      | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-08-01 | Extend `config/locales/th.yml` with all keys under `orders:`, `invoices:`, `products:`, `customers:`, `purchase_orders:`, `users:`, `dashboard:`, `activerecord.errors:` namespaces and status sub-keys (Thai values) | `[x]`  |
| T-22-08-02 | Extend `config/locales/en.yml` with the same key structure (English values)                                                                                                                              | `[x]`  |
| T-22-08-03 | Replace hardcoded strings in `app/views/orders/index.html.erb` and `app/views/orders/show.html.erb` with `t()` calls                                                                                     | `[x]`  |
| T-22-08-04 | Write RSpec request spec `spec/requests/i18n/orders_i18n_spec.rb`: TH user `GET /orders` body includes "ออเดอร์"; EN user body includes "Orders"                                                       | `[x]`  |
| T-22-08-05 | Replace hardcoded strings in `app/views/invoices/index.html.erb` and `app/views/invoices/show.html.erb` with `t()` calls                                                                                 | `[x]`  |
| T-22-08-06 | Write RSpec request spec `spec/requests/i18n/invoices_i18n_spec.rb`: TH user `GET /invoices` body includes "ใบแจ้งหนี้"; EN user body includes "Invoices"                                              | `[x]`  |
| T-22-08-07 | Replace hardcoded strings in `app/views/products/index.html.erb` and `app/views/products/show.html.erb` with `t()` calls                                                                                 | `[x]`  |
| T-22-08-08 | Write RSpec request spec `spec/requests/i18n/products_i18n_spec.rb`: TH user `GET /products` body includes "สินค้า"; EN user body includes "Products"                                                  | `[x]`  |
| T-22-08-09 | Replace hardcoded strings in `app/views/customers/index.html.erb` with `t()` calls                                                                                                                      | `[x]`  |
| T-22-08-10 | Write RSpec request spec `spec/requests/i18n/customers_i18n_spec.rb`: TH user `GET /customers` body includes "ลูกค้า"; EN user body includes "Customers"                                               | `[x]`  |
| T-22-08-11 | Replace hardcoded strings in `app/views/purchase_orders/index.html.erb` and `app/views/purchase_orders/show.html.erb` with `t()` calls                                                                   | `[x]`  |
| T-22-08-12 | Write RSpec request spec `spec/requests/i18n/purchase_orders_i18n_spec.rb`: TH user `GET /purchase_orders` body includes "ใบสั่งซื้อ"; EN user body includes "Purchase Orders"                        | `[x]`  |
| T-22-08-13 | Replace hardcoded strings in `app/views/users/index.html.erb` with `t()` calls                                                                                                                          | `[x]`  |
| T-22-08-14 | Write RSpec request spec `spec/requests/i18n/users_i18n_spec.rb`: TH user `GET /users` body includes "ผู้ใช้งาน"; EN user body includes "Users"                                                       | `[x]`  |
| T-22-08-15 | Replace hardcoded strings in `app/views/dashboard/index.html.erb` with `t()` calls                                                                                                                      | `[x]`  |
| T-22-08-16 | Write RSpec request spec `spec/requests/i18n/dashboard_i18n_spec.rb`: TH user `GET /` body includes "แดชบอร์ด"; EN user body includes "Dashboard"                                                     | `[x]`  |
| T-22-08-17 | Replace hardcoded strings in `app/views/orders/_form.html.erb` and `app/views/customers/_form.html.erb` with `t()` calls                                                                                 | `[x]`  |
| T-22-08-18 | Write RSpec request spec `spec/requests/i18n/no_missing_translations_spec.rb`: EN user requests to each of the 7 core module index pages — none of the response bodies include the string `[missing "en` | `[x]`  |

---

### STORY-22-09 — Table Header Column i18n for All Index and Show-Page Tables

**Status:** 🟢 Completed
**Description:** Every `<th>` element in every index listing table and every nested show-page table (Order Lines, Associated Orders, PO Lines) uses `t()` calls instead of hardcoded English strings. Locale files are extended with all missing table-header keys for both EN and TH.

**User Perspective:**
As a user, I want every table column header to appear in my chosen language, so that when I switch to Thai, the column labels are also in Thai rather than a mix of Thai titles and English headers.

**Acceptance Criteria:**

| #     | Given                                                                        | When                                  | Then                                                                                                                                             |
| ----- | ---------------------------------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| AC-01 | A user with `preferred_locale = "th"` visits `GET /orders`                  | The page renders                      | The table headers render in Thai: "เลขที่", "วันที่", "ลูกค้า", "พนักงานขาย", "สถานะ", "ยอดรวมสุทธิ", "การดำเนินการ"                          |
| AC-02 | A user with `preferred_locale = "en"` visits `GET /orders`                  | The page renders                      | The table headers render in English: "Order #", "Date", "Customer", "Salesperson", "Status", "Grand Total", "Actions"                            |
| AC-03 | A user with `preferred_locale = "th"` visits `GET /invoices`                | The page renders                      | The table headers render in Thai: "เลขที่", "วันที่", "ลูกค้า", "สถานะ", "ยอดเรียกเก็บ", "การดำเนินการ"                                       |
| AC-04 | A user with `preferred_locale = "th"` visits `GET /products`                | The page renders                      | The table headers render in Thai: "รหัสสินค้า", "ชื่อสินค้า", "ประเภท", "ราคา", "ต้นทุน", "หน่วย", "สต็อก", "การดำเนินการ"                   |
| AC-05 | A user with `preferred_locale = "th"` visits `GET /customers`               | The page renders                      | The table headers render in Thai: "ชื่อ", "เบอร์โทรศัพท์", "ประเทศ", "บริษัทขนส่ง", "สถานะ", "การดำเนินการ"                                  |
| AC-06 | A user with `preferred_locale = "th"` visits `GET /purchase_orders`         | The page renders                      | The table headers render in Thai: "เลขที่ใบสั่งซื้อ", "ซัพพลายเออร์", "วันที่", "สถานะ", "จำนวนรายการ", "การดำเนินการ"                       |
| AC-07 | A user with `preferred_locale = "th"` visits `GET /users`                   | The page renders                      | The table headers render in Thai: "ชื่อผู้ใช้", "อีเมล", "ชื่อ", "บทบาท", "สถานะ", "การดำเนินการ"                                            |
| AC-08 | A user with `preferred_locale = "th"` visits `GET /orders/:id`              | The page renders                      | The Order Lines sub-table headers render in Thai: "สินค้า", "รายละเอียด", "หน่วย", "จำนวน", "ราคาต่อหน่วย", "ส่วนลด", "รวมบรรทัด"            |
| AC-09 | A user with `preferred_locale = "th"` visits `GET /invoices/:id`            | The page renders                      | The Associated Orders sub-table headers include "เลขที่", "วันที่", "ลูกค้า", "สถานะ", "ยอดรวมสุทธิ"; the per-order lines headers include "ส่วนลด" and "รวมบรรทัด" |
| AC-10 | A user with `preferred_locale = "en"` visits any of the above pages         | The page renders                      | The response body does NOT include the string `[missing "en`                                                                                     |
| AC-11 | An unauthenticated request is made to `GET /orders`                         | The request is processed              | The response is HTTP 302 redirect to the login page                                                                                              |

**Edge Cases:**

- The `orders.table.no` key ("Order #") is already defined and used for order line numbering in the orders form table; ensure the index page and the show page both reuse the same key rather than defining a duplicate.
- The products table has a conditional `<th>` for "Cost" (shown only to users with `can_view_cost?` permission); the `t()` call must be inside that conditional block, not removed.
- The purchase_orders form table has the same column headers as the PO index; share the same `purchase_orders.table.*` keys for both.

**New locale keys required (add to both `en.yml` and `th.yml`):**

```
orders.table.salesperson        EN: "Salesperson"          TH: "พนักงานขาย"
orders.table.grand_total        EN: "Grand Total"          TH: "ยอดรวมสุทธิ"
orders.table.product            EN: "Product"              TH: "สินค้า"
orders.table.line_total         EN: "Line Total"           TH: "รวมบรรทัด"
orders.table.discount           EN: "Discount"             TH: "ส่วนลด"
invoices.table.total_bill       EN: "Total Bill"           TH: "ยอดเรียกเก็บ"
invoices.table.line_total       EN: "Line Total"           TH: "รวมบรรทัด"
invoices.table.grand_total      EN: "Grand Total"          TH: "ยอดรวมสุทธิ"
invoices.table.discount         EN: "Discount"             TH: "ส่วนลด"
products.table.type             EN: "Type"                 TH: "ประเภท"
products.table.price            EN: "Price"                TH: "ราคา"
products.table.unit             EN: "Unit"                 TH: "หน่วย"
products.table.stock            EN: "Stock"                TH: "สต็อก"
customers.table.telephone       EN: "Telephone"            TH: "เบอร์โทรศัพท์"
customers.table.country         EN: "Country"              TH: "ประเทศ"
customers.table.logistic_company EN: "Logistic Co."        TH: "บริษัทขนส่ง"
customers.table.status          EN: "Status"               TH: "สถานะ"
purchase_orders.table.lines     EN: "Lines"                TH: "จำนวนรายการ"
purchase_orders.table.unit      EN: "Unit"                 TH: "หน่วย"
purchase_orders.table.quantity  EN: "Qty"                  TH: "จำนวน"
purchase_orders.table.unit_cost EN: "Unit Cost"            TH: "ราคาต้นทุน"
```

| #          | Task                                                                                                                                                                                                              | Status |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-09-01 | Add all missing `orders.table.*`, `invoices.table.*`, `products.table.*`, `customers.table.*`, `purchase_orders.table.*` keys listed above to `config/locales/en.yml`                                             | `[x]`  |
| T-22-09-02 | Add the same keys with Thai values to `config/locales/th.yml`                                                                                                                                                     | `[x]`  |
| T-22-09-03 | `app/views/orders/index.html.erb`: replace all 7 `<th>` hardcoded strings with `t("orders.table.KEY")` calls                                                                                                      | `[x]`  |
| T-22-09-04 | `app/views/orders/show.html.erb`: replace all 7–8 `<th>` hardcoded strings in the Order Lines sub-table with `t("orders.table.KEY")` calls                                                                        | `[x]`  |
| T-22-09-05 | `app/views/invoices/index.html.erb`: replace all 6 `<th>` hardcoded strings with `t("invoices.table.KEY")` calls                                                                                                   | `[x]`  |
| T-22-09-06 | `app/views/invoices/show.html.erb`: replace the `<th>` strings in the Associated Orders table and the per-order order-lines sub-table with `t()` calls using `orders.table.*` and `invoices.table.*` keys         | `[x]`  |
| T-22-09-07 | `app/views/products/index.html.erb`: replace all 8 `<th>` hardcoded strings with `t("products.table.KEY")` calls                                                                                                  | `[x]`  |
| T-22-09-08 | `app/views/customers/index.html.erb`: replace all 6 `<th>` hardcoded strings with `t("customers.table.KEY")` calls                                                                                                | `[x]`  |
| T-22-09-09 | `app/views/users/index.html.erb`: replace all 6 `<th>` hardcoded strings with `t("users.table.KEY")` calls                                                                                                        | `[x]`  |
| T-22-09-10 | `app/views/purchase_orders/index.html.erb`: replace all 6 `<th>` hardcoded strings with `t("purchase_orders.table.KEY")` calls                                                                                    | `[x]`  |
| T-22-09-11 | `app/views/purchase_orders/show.html.erb` and `app/views/purchase_orders/_form.html.erb`: replace the PO lines sub-table `<th>` strings with `t("purchase_orders.table.KEY")` calls                              | `[x]`  |
| T-22-09-12 | `app/views/orders/_form.html.erb`: replace the order lines form table `<th>` strings with `t("orders.table.KEY")` calls                                                                                           | `[x]`  |
| T-22-09-13 | Write RSpec request spec `spec/requests/i18n/table_headers_i18n_spec.rb`: (a) TH user `GET /orders` body includes "พนักงานขาย" and "ยอดรวมสุทธิ"; (b) EN user body includes "Salesperson" and "Grand Total"; (c) TH user `GET /products` body includes "ประเภท"; (d) TH user `GET /customers` body includes "เบอร์โทรศัพท์"; (e) TH user `GET /purchase_orders` body includes "จำนวนรายการ" | `[x]`  |
| T-22-09-14 | Write RSpec request spec confirming no `[missing "en` or `[missing "th` string appears in any of the 6 index pages for either locale after the changes                                                            | `[x]`  |
| T-22-09-15 | Write RSpec request spec for `app/views/orders/show.html.erb` Order Lines `<th>`: TH user `GET /orders/:id` body includes "สินค้า", "รายละเอียด", "หน่วย", "จำนวน", "ราคาต่อหน่วย", "ส่วนลด", "รวมบรรทัด"      | `[x]`  |
| T-22-09-16 | Write RSpec request spec for `app/views/invoices/show.html.erb` nested tables `<th>`: TH user `GET /invoices/:id` body includes "เลขที่", "ยอดรวมสุทธิ", "ส่วนลด", "รวมบรรทัด"                                  | `[x]`  |
| T-22-09-17 | Write RSpec request spec for `app/views/purchase_orders/show.html.erb` and `app/views/purchase_orders/_form.html.erb` PO lines `<th>`: TH user `GET /purchase_orders/:id` body includes "จำนวน" and "ราคาต้นทุน" | `[x]`  |
| T-22-09-18 | Write RSpec request spec for `app/views/orders/_form.html.erb` order lines form `<th>`: TH user `GET /orders/new` body includes "สินค้า" and "รายละเอียด" in the order lines table                               | `[x]`  |

---

### STORY-22-10 — Status Badge and Status Select Option i18n

**Status:** 🟢 Completed
**Description:** Every status badge (inline spans and partial renders) and every status `<select>` option across Orders, Invoices, Purchase Orders, Users, and Customers uses `t()` rather than a hardcoded English label. Invoice and Order status filter tab labels also use `t()`. All missing `*.status.*` locale keys are added to both locale files.

**User Perspective:**
As a user, I want status badges and status filter tabs to appear in my chosen language, so that "ร่าง" appears instead of "Draft" when I am using Thai.

**Acceptance Criteria:**

| #     | Given                                                                              | When                              | Then                                                                                                                                    |
| ----- | ---------------------------------------------------------------------------------- | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A TH user visits `GET /orders` with a Draft order in the list                     | The page renders                  | The status badge reads "ร่าง" and the "Draft" filter tab reads "ร่าง"                                                                   |
| AC-02 | An EN user visits `GET /orders` with a Completed order in the list                | The page renders                  | The status badge reads "Completed" (not the raw code "Cp")                                                                              |
| AC-03 | A TH user visits `GET /invoices`                                                   | The page renders                  | The status filter tabs read "ร่าง", "ชำระแล้ว", "ยกเลิก" and status badges use t()                                                     |
| AC-04 | A TH user visits `GET /purchase_orders` with a Draft PO                           | The page renders                  | The inline status badge reads "ร่าง"                                                                                                    |
| AC-05 | A TH user visits `GET /users` with an active user                                 | The page renders                  | The status badge reads "ใช้งาน"                                                                                                         |
| AC-06 | A TH user visits `GET /customers`                                                  | The page renders                  | The status column shows "ใช้งาน" or "ไม่ได้ใช้งาน" depending on the customer's active state                                           |
| AC-07 | A TH user visits `GET /orders/new`                                                 | The form renders                  | The status `<select>` options read "ร่าง", "ชำระแล้ว", "เสร็จสิ้น", "ยกเลิก"                                                          |
| AC-08 | An EN user visits any of the above pages                                           | The page renders                  | No `[missing "en` string appears in the status badge or select option area                                                              |
| AC-09 | A TH user visits `GET /purchase_orders/:id` with a Draft PO                        | The page renders                  | The inline status badge in the show page header reads "ร่าง"                                                                            |
| AC-10 | An unauthenticated request is made to `GET /orders`                                | The request is processed          | The response is HTTP 302 redirect to the login page                                                                                      |

**Edge Cases:**

- `orders._status_badge` uses a `case` on the raw status code ("Dr", "Pd", "Cp", "Cc"); when replacing labels with `t()`, the key mapping must be:  `"Dr" → orders.status.draft`, `"Pd" → orders.status.paid`, `"Cp" → orders.status.completed`, `"Cc" → orders.status.cancelled`.
- `invoices._status_badge` uses "Dr", "Pd", "Cc"; "Sent" state (code "Se" if present) must also be covered.
- The bulk-status `<select>` in the orders index bar uses the same status option labels; they must also be translated.
- The orders filter tabs currently have "Draft", "Paid", "Cancelled" hardcoded tab links — a "Completed" tab may not exist; only translate tabs that actually exist in the view.
- `customers` currently only renders "Active" for `is_active = true` with no "Inactive" label; both states must be rendered via `t()` for completeness.

**New locale keys required (add to both `en.yml` and `th.yml`):**

```
orders.status.completed          EN: "Completed"        TH: "เสร็จสิ้น"
purchase_orders.status.draft     EN: "Draft"            TH: "ร่าง"
purchase_orders.status.confirmed EN: "Confirmed"        TH: "ยืนยัน"
purchase_orders.status.cancelled EN: "Cancelled"        TH: "ยกเลิก"
users.status.active              EN: "Active"           TH: "ใช้งาน"
users.status.inactive            EN: "Inactive"         TH: "ไม่ได้ใช้งาน"
customers.status.active          EN: "Active"           TH: "ใช้งาน"
customers.status.inactive        EN: "Inactive"         TH: "ไม่ได้ใช้งาน"
```

| #          | Task                                                                                                                                                                                                                           | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-22-10-01 | Add `orders.status.completed`, `purchase_orders.status.*`, `users.status.*`, `customers.status.*` to `config/locales/en.yml`                                                                                                   | `[x]`  |
| T-22-10-02 | Add the same keys with Thai values to `config/locales/th.yml`                                                                                                                                                                  | `[x]`  |
| T-22-10-03 | `app/views/orders/_status_badge.html.erb`: replace the `label = case status … end` block with `t("orders.status.#{status_key_map[status]}", default: status)` where `status_key_map` maps "Dr"→"draft", "Pd"→"paid", "Cp"→"completed", "Cc"→"cancelled" | `[x]`  |
| T-22-10-04 | `app/views/invoices/_status_badge.html.erb`: replace the `label = case status … end` block with `t("invoices.status.#{key}", default: status)` using the same pattern                                                         | `[x]`  |
| T-22-10-05 | `app/views/purchase_orders/index.html.erb`: replace inline `"Draft"` and `"Confirmed"` span text with `t("purchase_orders.status.draft")` and `t("purchase_orders.status.confirmed")`                                          | `[x]`  |
| T-22-10-06 | `app/views/purchase_orders/show.html.erb`: replace inline status span text with `t("purchase_orders.status.KEY")` calls                                                                                                        | `[x]`  |
| T-22-10-07 | `app/views/users/index.html.erb`: replace `"Active"` and `"Inactive"` span text with `t("users.status.active")` and `t("users.status.inactive")`                                                                              | `[x]`  |
| T-22-10-08 | `app/views/customers/index.html.erb`: replace hardcoded `"Active"` and any `"Inactive"` span text with `t("customers.status.active")` and `t("customers.status.inactive")`                                                    | `[x]`  |
| T-22-10-09 | `app/views/invoices/index.html.erb`: replace hardcoded filter tab labels `"Draft"`, `"Paid"`, `"Cancelled"` with `t("invoices.status.draft")`, `t("invoices.status.paid")`, `t("invoices.status.cancelled")`                  | `[x]`  |
| T-22-10-10 | `app/views/orders/index.html.erb`: replace hardcoded filter tab labels `"Draft"`, `"Paid"`, `"Cancelled"` with `t("orders.status.draft")`, `t("orders.status.paid")`, `t("orders.status.cancelled")`                          | `[x]`  |
| T-22-10-11 | `app/views/orders/index.html.erb`: replace bulk-status `<select>` option values with `t("orders.status.KEY")` calls                                                                                                            | `[x]`  |
| T-22-10-12 | `app/views/orders/_form.html.erb`: replace status `<select>` option labels `"Draft"`, `"Paid"`, `"Completed"`, `"Cancelled"` with `t("orders.status.KEY")` calls                                                             | `[x]`  |
| T-22-10-13 | Write RSpec request spec `spec/requests/i18n/status_badge_i18n_spec.rb`: (a) TH user `GET /orders` body includes "ร่าง"; (b) EN user `GET /orders` body includes "Draft"; (c) TH user `GET /users` body includes "ใช้งาน"; (d) TH user `GET /purchase_orders` body includes "ร่าง" (PO status) | `[x]`  |
| T-22-10-14 | Write RSpec request spec `spec/requests/i18n/status_select_i18n_spec.rb`: TH user `GET /orders/new` body includes "ร่าง" in a `<select>` option; EN user body includes "Draft" in a `<select>` option                        | `[x]`  |
| T-22-10-15 | Write RSpec request spec `spec/requests/i18n/invoice_status_badge_i18n_spec.rb`: TH user `GET /invoices` body includes "ร่าง" (Draft invoice status badge); EN user body includes "Draft"                                     | `[x]`  |
| T-22-10-16 | Write RSpec request spec: TH user `GET /purchase_orders/:id` (with a Draft PO) body includes "ร่าง" in the show page status badge                                                                              | `[x]`  |
| T-22-10-17 | Write RSpec request spec: TH user `GET /customers` body includes "ใช้งาน" (active customer status badge); EN user body includes "Active"                                                                       | `[x]`  |
| T-22-10-18 | Write RSpec request spec: TH user `GET /invoices` body includes "ร่าง" in the filter tab link label; EN user body includes "Draft" in the filter tab                                                                   | `[x]`  |
| T-22-10-19 | Write RSpec request spec: TH user `GET /orders` body includes "ร่าง" as a `<select>` `<option>` in the bulk-status select bar                                                                                  | `[x]`  |

---

### STORY-22-11 — Form Field Labels via `activerecord.attributes` and Show/Detail Page Label i18n

**Status:** 🟢 Completed
**Description:** All form field labels in create/edit forms (Orders, Invoices, Customers, Products, Users, Purchase Orders) and all `<dt>` / field-label strings in show/detail pages are translated via Rails `activerecord.attributes` and module-namespaced `t()` keys. Form section headings (`<h2>`) inside forms and show pages also use `t()`. Financial summary row labels (Subtotal, Discount, VAT, Grand Total) use a shared `common.summary.*` namespace.

**User Perspective:**
As a user, when I open the New Order form or the Invoice detail page in Thai, every field label — "Customer", "Order Date", "Remark", "Invoice #", "Grand Total" — appears in Thai, not English.

**Acceptance Criteria:**

| #     | Given                                                                         | When                       | Then                                                                                                                                                  |
| ----- | ----------------------------------------------------------------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A TH user visits `GET /orders/new`                                            | The form renders           | The field label for `customer_id` reads "ลูกค้า", `running_date` reads "วันที่ออเดอร์", the section heading reads "ข้อมูลออเดอร์"                    |
| AC-02 | A TH user visits `GET /customers/new`                                         | The form renders           | The field label for `first_name` reads "ชื่อ", `last_name` reads "นามสกุล", `telephone` reads "เบอร์โทรศัพท์"                                       |
| AC-03 | A TH user visits `GET /products/new`                                          | The form renders           | The field label for `name` reads "ชื่อสินค้า", `sku` reads "รหัสสินค้า (สร้างอัตโนมัติหากไม่ระบุ)", section heading reads "ข้อมูลสินค้า"           |
| AC-04 | A TH user visits `GET /users/new`                                             | The form renders           | The section heading reads "ข้อมูลบัญชี", `username` reads "ชื่อผู้ใช้", `email` reads "อีเมล"                                                        |
| AC-05 | A TH user visits `GET /purchase_orders/new`                                   | The form renders           | The section heading reads "ข้อมูลใบสั่งซื้อ", `supplier_id` reads "ซัพพลายเออร์", `po_date` reads "วันที่สั่งซื้อ"                                   |
| AC-06 | A TH user visits `GET /orders/:id`                                            | The show page renders      | The `<dt>` label for Customer reads "ลูกค้า", Status reads "สถานะ", Remark reads "หมายเหตุ", section heading "Order Details" reads "รายละเอียดออเดอร์" |
| AC-07 | A TH user visits `GET /invoices/:id`                                          | The show page renders      | The `<dt>` labels read in Thai: "เลขที่ใบแจ้งหนี้", "วันที่ใบแจ้งหนี้", "ลูกค้า", "สถานะ", "ยอดรวม", "หมายเหตุ"                                    |
| AC-08 | A TH user visits `GET /invoices/:id`                                          | The show page renders      | The financial summary rows read "ยอดรวมก่อนลด", "ส่วนลด", "หลังหักส่วนลด", "ภาษีมูลค่าเพิ่ม (7%)", "ภาษีหัก ณ ที่จ่าย", "ยอดรวมสุทธิ"            |
| AC-09 | A TH user visits `GET /purchase_orders/:id`                                   | The show page renders      | The `<dt>` labels read "ซัพพลายเออร์", "วันที่สั่งซื้อ", "สถานะ", "หมายเหตุ"; the lines section heading reads "รายการสินค้า"                        |
| AC-10 | An EN user visits any of the above pages                                      | The page renders           | No `[missing "en` string appears anywhere on the page                                                                                                 |
| AC-11 | An unauthenticated request is made to `GET /orders/new`                       | The request is processed   | The response is HTTP 302 redirect to the login page                                                                                                   |

**Edge Cases:**

- Rails resolves `f.label :attribute` (without explicit string) by looking up `activerecord.attributes.model_name.attribute` — the hardcoded second-argument strings such as `f.label :customer_id, "Customer"` override this lookup and MUST be removed for the activerecord lookup to take effect.
- `f.label :sku, "SKU (auto-generated if blank)"` is a long descriptive string; add it as a full string to `activerecord.attributes.product.sku` in both locale files rather than splitting into two keys.
- The `users/_form.html.erb` uses nested `f.fields_for :profile do |pf|`; labels on `pf.label :first_name` look up `activerecord.attributes.profile.first_name` — add `profile` model entries in both locale files.
- The financial summary labels (Subtotal, Grand Total, etc.) appear in both `orders/_form.html.erb` (live calculator) and `invoices/show.html.erb`; use a shared `common.summary.*` namespace.
- Show page section headings (`<h2 class="section-heading">`) that currently use hardcoded English text must be replaced with `t()` calls. Section headings already translated in STORY-22-08 (e.g. `t("orders.show.order_lines")`) must not be changed.

**New locale keys required (add to both `en.yml` and `th.yml`):**

```
# Form section headings
orders.form.order_information    EN: "Order Information"          TH: "ข้อมูลออเดอร์"
orders.form.order_lines          EN: "Order Lines"                TH: "รายการสินค้า"
orders.form.add_line             EN: "+ Add Line"                 TH: "+ เพิ่มรายการ"
orders.form.pricing_options      EN: "Pricing Options"            TH: "ตัวเลือกราคา"
orders.form.notes                EN: "Notes"                      TH: "หมายเหตุ"
orders.form.summary              EN: "Summary"                    TH: "สรุปราคา"
orders.form.errors               EN: "Please fix the following errors:" TH: "กรุณาแก้ไขข้อผิดพลาดต่อไปนี้:"
orders.form.submit_create        EN: "Create Order"               TH: "สร้างออเดอร์"
orders.form.submit_update        EN: "Update Order"               TH: "อัปเดตออเดอร์"
products.form.product_information EN: "Product Information"       TH: "ข้อมูลสินค้า"
products.form.pricing            EN: "Pricing"                    TH: "ราคา"
products.form.details            EN: "Details"                    TH: "รายละเอียด"
products.form.custom_attributes  EN: "Custom Attributes"          TH: "คุณสมบัติเพิ่มเติม"
products.form.errors             EN: "Please fix the following errors:" TH: "กรุณาแก้ไขข้อผิดพลาดต่อไปนี้:"
products.form.submit_create      EN: "Create Product"             TH: "เพิ่มสินค้า"
products.form.submit_update      EN: "Update Product"             TH: "อัปเดตสินค้า"
users.form.account_details       EN: "Account Details"            TH: "ข้อมูลบัญชี"
users.form.profile               EN: "Profile"                    TH: "โปรไฟล์"
users.form.force_password_reset  EN: "Force Password Reset"       TH: "บังคับรีเซ็ตรหัสผ่าน"
users.form.errors                EN: "Please fix the following errors:" TH: "กรุณาแก้ไขข้อผิดพลาดต่อไปนี้:"
users.form.submit_create         EN: "Create User"                TH: "สร้างผู้ใช้"
users.form.submit_update         EN: "Update User"                TH: "อัปเดตผู้ใช้"
purchase_orders.form.po_information EN: "Purchase Order Information" TH: "ข้อมูลใบสั่งซื้อ"
purchase_orders.form.order_lines EN: "Order Lines"                TH: "รายการสินค้า"
purchase_orders.form.add_line    EN: "+ Add Line"                 TH: "+ เพิ่มรายการ"
purchase_orders.form.errors      EN: "Please fix the following errors:" TH: "กรุณาแก้ไขข้อผิดพลาดต่อไปนี้:"
purchase_orders.form.submit_create EN: "Create Purchase Order"    TH: "สร้างใบสั่งซื้อ"
purchase_orders.form.submit_update EN: "Update Purchase Order"    TH: "อัปเดตใบสั่งซื้อ"
customers.form.errors            EN: "Please fix the following errors:" TH: "กรุณาแก้ไขข้อผิดพลาดต่อไปนี้:"
customers.form.submit_create     EN: "Create Customer"            TH: "เพิ่มลูกค้า"
customers.form.submit_update     EN: "Update Customer"            TH: "อัปเดตลูกค้า"

# Show/detail page labels
orders.show.order_details        EN: "Order Details"              TH: "รายละเอียดออเดอร์"
orders.show.status               EN: "Status"                     TH: "สถานะ"
orders.show.customer             EN: "Customer"                   TH: "ลูกค้า"
orders.show.logistic_company     EN: "Logistic Company"           TH: "บริษัทขนส่ง"
orders.show.telephone            EN: "Telephone"                  TH: "เบอร์โทรศัพท์"
orders.show.address              EN: "Address"                    TH: "ที่อยู่"
orders.show.remark               EN: "Remark"                     TH: "หมายเหตุ"
orders.show.internal_note        EN: "Internal Note"              TH: "หมายเหตุภายใน"
orders.show.change_history       EN: "Change History"             TH: "ประวัติการเปลี่ยนแปลง"
invoices.show.invoice_details    EN: "Invoice Details"            TH: "รายละเอียดใบแจ้งหนี้"
invoices.show.invoice_no         EN: "Invoice #"                  TH: "เลขที่ใบแจ้งหนี้"
invoices.show.invoice_date       EN: "Invoice Date"               TH: "วันที่ใบแจ้งหนี้"
invoices.show.customer           EN: "Customer"                   TH: "ลูกค้า"
invoices.show.status             EN: "Status"                     TH: "สถานะ"
invoices.show.total_amount       EN: "Total Amount"               TH: "ยอดรวม"
invoices.show.remark             EN: "Remark"                     TH: "หมายเหตุ"
invoices.show.created_by         EN: "Created by"                 TH: "สร้างโดย"
invoices.show.last_updated_by    EN: "Last updated by"            TH: "อัปเดตล่าสุดโดย"
invoices.show.associated_orders  EN: "Associated Orders"          TH: "ออเดอร์ที่เกี่ยวข้อง"
invoices.show.add_orders         EN: "Add Orders"                 TH: "เพิ่มออเดอร์"
invoices.show.summary            EN: "Summary"                    TH: "สรุป"
invoices.show.images             EN: "Images"                     TH: "รูปภาพ"
invoices.show.change_history     EN: "Change History"             TH: "ประวัติการเปลี่ยนแปลง"
purchase_orders.show.supplier    EN: "Supplier"                   TH: "ซัพพลายเออร์"
purchase_orders.show.po_date     EN: "PO Date"                    TH: "วันที่สั่งซื้อ"
purchase_orders.show.status      EN: "Status"                     TH: "สถานะ"
purchase_orders.show.remark      EN: "Remark"                     TH: "หมายเหตุ"
purchase_orders.show.order_lines EN: "Order Lines"                TH: "รายการสินค้า"

# Shared financial summary row labels
common.summary.subtotal          EN: "Subtotal"                   TH: "ยอดรวมก่อนลด"
common.summary.discount          EN: "Discount"                   TH: "ส่วนลด"
common.summary.after_discount    EN: "After Discount"             TH: "หลังหักส่วนลด"
common.summary.excl_vat          EN: "Excl. VAT"                  TH: "ก่อนภาษี"
common.summary.vat               EN: "VAT (7%)"                   TH: "ภาษีมูลค่าเพิ่ม (7%)"
common.summary.withholding_tax   EN: "Withholding Tax"            TH: "ภาษีหัก ณ ที่จ่าย"
common.summary.grand_total       EN: "Grand Total"                TH: "ยอดรวมสุทธิ"

# activerecord.attributes — all must be added under each model name
activerecord.attributes.order.*           (customer_id, running_date, status, telephone, address,
                                           logistic_company_id, logistic_status, remark, internal_note,
                                           has_vat, is_included_vat, is_withholding_tax, withholding_tax,
                                           is_discount_percentage, discount_percentage, discount_price)
activerecord.attributes.customer.*        (first_name, last_name, telephone, country_id,
                                           logistic_company_id, address, remark)
activerecord.attributes.product.*         (name, product_type, sku, barcode, vendor_id, brand_id,
                                           product_class_id, unit, price, cost,
                                           product_category_ids, description, description_th,
                                           remark, enable_stock)
activerecord.attributes.user.*            (username, email, password, password_confirmation, is_active)
activerecord.attributes.profile.*         (first_name, last_name, role_id, telephone, address, remark)
activerecord.attributes.purchase_order.*  (supplier_id, po_date, remark)
```

| #          | Task                                                                                                                                                                                                                                          | Status |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-22-11-01 | Add all `orders.form.*`, `products.form.*`, `users.form.*`, `purchase_orders.form.*`, `customers.form.*` keys to `config/locales/en.yml` | `[x]`  |
| T-22-11-02 | Add the same keys with Thai values to `config/locales/th.yml`                                                                                                                                                                                 | `[ ]`  |
| T-22-11-03 | Add all `orders.show.*`, `invoices.show.*`, `purchase_orders.show.*` keys to `config/locales/en.yml`                                                                                                                                          | `[ ]`  |
| T-22-11-04 | Add the same keys with Thai values to `config/locales/th.yml`                                                                                                                                                                                 | `[ ]`  |
| T-22-11-05 | Add `common.summary.*` keys to `config/locales/en.yml` and `config/locales/th.yml`                                                                                                                                                            | `[ ]`  |
| T-22-11-06 | Add `activerecord.attributes.order.*`, `activerecord.attributes.customer.*`, `activerecord.attributes.product.*`, `activerecord.attributes.user.*`, `activerecord.attributes.profile.*`, `activerecord.attributes.purchase_order.*` to `config/locales/en.yml` | `[ ]`  |
| T-22-11-07 | Add the same `activerecord.attributes.*` keys with Thai values to `config/locales/th.yml`                                                                                                                                                     | `[ ]`  |
| T-22-11-08 | `app/views/orders/_form.html.erb`: (a) remove hardcoded second-argument strings from all `f.label` calls (e.g. remove `"Customer"` from `f.label :customer_id, "Customer"`); (b) replace all `<h2>` section heading strings with `t("orders.form.KEY")` calls | `[x]`  |
| T-22-11-19 | `app/views/orders/_form.html.erb`: (c) replace submit button labels with `t("orders.form.submit_create")` / `t("orders.form.submit_update")`; (d) replace financial summary `<span>` labels with `t("common.summary.KEY")` calls | `[x]`  |
| T-22-11-09 | `app/views/products/_form.html.erb`: remove hardcoded label strings; replace `<h2>` section headings with `t("products.form.KEY")`; replace submit label with `t("products.form.submit_*")`                                                  | `[x]`  |
| T-22-11-10 | `app/views/users/_form.html.erb`: remove hardcoded label strings (`"Active account"`, `"Role"`, etc.); replace `<h2>` section headings with `t("users.form.KEY")`; replace submit label with `t("users.form.submit_*")`                     | `[x]`  |
| T-22-11-11 | `app/views/purchase_orders/_form.html.erb`: remove hardcoded label strings; replace `<h2>` section headings with `t("purchase_orders.form.KEY")`; replace submit label with `t("purchase_orders.form.submit_*")`                             | `[x]`  |
| T-22-11-12 | `app/views/customers/_form.html.erb`: replace submit label with `t("customers.form.submit_*")`; replace back link "← Back to Customers" with `t("common.back")` pattern                                                                     | `[x]`  |
| T-22-11-13 | `app/views/orders/show.html.erb`: replace all hardcoded `<dt>` label strings and `<h2>` section heading strings with `t("orders.show.KEY")` calls                                                                                            | `[x]`  |
| T-22-11-14 | `app/views/invoices/show.html.erb`: replace all hardcoded `<dt>` label strings, `<h2>` section headings, and financial summary `<span>` labels with `t()` calls using `invoices.show.*` and `common.summary.*` keys                         | `[x]`  |
| T-22-11-15 | `app/views/purchase_orders/show.html.erb`: replace all hardcoded `<dt>` label strings and `<h2>` section heading strings with `t("purchase_orders.show.KEY")` calls                                                                          | `[x]`  |
| T-22-11-16 | Write RSpec request spec `spec/requests/i18n/form_labels_i18n_spec.rb`: (a) TH user `GET /orders/new` body includes "ลูกค้า" (label for customer_id); (b) TH user body includes "ข้อมูลออเดอร์" (section heading); (c) EN user body includes "Customer" and "Order Information" | `[x]`  |
| T-22-11-17 | Write RSpec request spec `spec/requests/i18n/show_labels_i18n_spec.rb`: (a) TH user `GET /orders/:id` body includes "รายละเอียดออเดอร์"; (b) TH user `GET /invoices/:id` body includes "เลขที่ใบแจ้งหนี้" and "ยอดรวมสุทธิ"; (c) TH user `GET /purchase_orders/:id` body includes "ซัพพลายเออร์" | `[x]`  |
| T-22-11-18 | Write RSpec request spec `spec/requests/i18n/no_missing_translations_v2_spec.rb`: EN and TH users each request `GET /orders/new`, `GET /products/new`, `GET /users/new`, `GET /purchase_orders/new`, `GET /customers/new` — none of the response bodies include `[missing "` | `[x]`  |
| T-22-11-20 | Write RSpec request spec: TH user `GET /customers/new` body includes "ชื่อ" (first_name label) and "เบอร์โทรศัพท์" (telephone label); EN user body includes "First Name" and "Telephone"                                        | `[x]`  |
| T-22-11-21 | Write RSpec request spec: TH user `GET /products/new` body includes "ชื่อสินค้า" (name label) and "ข้อมูลสินค้า" (section heading); EN user body includes "Name" and "Product Information"                                     | `[x]`  |
| T-22-11-22 | Write RSpec request spec: TH user `GET /users/new` body includes "ชื่อผู้ใช้" (username label) and "ข้อมูลบัญชี" (section heading); EN user body includes "Username" and "Account Details"                                     | `[x]`  |
| T-22-11-23 | Write RSpec request spec: TH user `GET /purchase_orders/new` body includes "ซัพพลายเออร์" (supplier_id label) and "ข้อมูลใบสั่งซื้อ" (section heading); EN user body includes "Supplier" and "Purchase Order Information"       | `[x]`  |

---

### STORY-22-12 — Placeholder Text and Empty-State Message i18n

**Status:** 🟢 Completed
**Description:** All `placeholder` attributes on search input fields, typeahead fields, and form text inputs are replaced with `t()` calls. All empty-state messages in tables ("No orders found", etc.) are replaced with `t()` calls. A `placeholders.*` namespace and `*.empty_state` keys are added to both locale files.

**User Perspective:**
As a user, I want placeholder hints in search bars and form fields, and empty-table messages, to appear in my chosen language, so there is no English text visible anywhere when I am in Thai mode.

**Acceptance Criteria:**

| #     | Given                                                                          | When                              | Then                                                                                                                                |
| ----- | ------------------------------------------------------------------------------ | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| AC-01 | A TH user visits `GET /orders`                                                 | The page renders                  | The search input's placeholder reads "ค้นหาเลขที่ออเดอร์, ชื่อลูกค้า…" not "Search order number, customer name…"                  |
| AC-02 | A TH user visits `GET /orders/new`                                             | The form renders                  | The customer typeahead placeholder reads "พิมพ์ชื่อหรือเบอร์โทรศัพท์…"; the order-line product search placeholder reads in Thai  |
| AC-03 | A TH user visits `GET /invoices`                                               | The page renders                  | The search input placeholder reads "ค้นหาเลขที่ใบแจ้งหนี้, ชื่อลูกค้า…"                                                           |
| AC-04 | A TH user visits `GET /products`                                               | The page renders                  | The search input placeholder reads "ค้นหาโดยชื่อ, SKU หรือบาร์โค้ด…"                                                             |
| AC-05 | A TH user visits `GET /customers`                                              | The page renders                  | The search input placeholder reads "ค้นหาโดยชื่อ, ที่อยู่, เบอร์โทรศัพท์ หรือบริษัทขนส่ง…"                                       |
| AC-06 | A TH user visits `GET /purchase_orders`                                        | The page renders                  | The search input placeholder reads "ค้นหาโดยเลขที่ใบสั่งซื้อ หรือซัพพลายเออร์…"                                                   |
| AC-07 | A TH user visits `GET /users`                                                   | The page renders                  | The search input placeholder reads "ค้นหาชื่อผู้ใช้, ชื่อ, อีเมล, เบอร์โทรศัพท์…"                                                |
| AC-08 | A TH user visits `GET /orders` with no orders matching the filter              | The empty state renders           | The empty-state message reads "ไม่พบออเดอร์" not "No orders found"                                                                  |
| AC-09 | A TH user visits `GET /products` with no products                              | The empty state renders           | The empty-state message reads "ไม่พบสินค้า"                                                                                         |
| AC-10 | An EN user visits any of the above pages                                       | The page renders                  | No `[missing "en` string appears in placeholders or empty-state areas                                                               |
| AC-11 | An unauthenticated request is made to `GET /orders`                            | The request is processed          | The response is HTTP 302 redirect to the login page                                                                                  |

**Edge Cases:**

- Placeholder text in `_order_line_fields.html.erb` and `_purchase_order_line_fields.html.erb` is rendered inside Stimulus-driven dynamic row templates; the `t()` call must still work because ERB is evaluated on the server when the template partial is rendered into the `<template>` tag — no client-side JS change is required.
- The `orders/scan.html.erb` has a scan-specific placeholder (`"e.g. 20260418001"`); this is a technical hint rather than UI text — it may remain hardcoded unless the user explicitly requests otherwise. Mark it as out-of-scope in a task note.
- Empty-state `<td colspan="…">` messages in tables must use `t("MODULE.empty_state")` rather than `common.empty_state` to allow per-module wording.

**New locale keys required (add to both `en.yml` and `th.yml`):**

```
# Search bar placeholders
placeholders.orders.search            EN: "Search order number, customer name…"   TH: "ค้นหาเลขที่ออเดอร์, ชื่อลูกค้า…"
placeholders.orders.customer_typeahead EN: "Type name or phone…"                  TH: "พิมพ์ชื่อหรือเบอร์โทรศัพท์…"
placeholders.orders.line_product      EN: "Search SKU or name…"                   TH: "ค้นหา SKU หรือชื่อสินค้า…"
placeholders.orders.line_description  EN: "Product description…"                  TH: "รายละเอียดสินค้า…"
placeholders.invoices.search          EN: "Search invoice number, customer name…" TH: "ค้นหาเลขที่ใบแจ้งหนี้, ชื่อลูกค้า…"
placeholders.products.search          EN: "Search by name, SKU, or barcode…"      TH: "ค้นหาโดยชื่อ, SKU หรือบาร์โค้ด…"
placeholders.customers.search         EN: "Search by name, address, telephone or logistic company…" TH: "ค้นหาโดยชื่อ, ที่อยู่, เบอร์โทรศัพท์ หรือบริษัทขนส่ง…"
placeholders.purchase_orders.search   EN: "Search by PO number or supplier…"      TH: "ค้นหาโดยเลขที่ใบสั่งซื้อ หรือซัพพลายเออร์…"
placeholders.purchase_orders.line_product EN: "Search SKU or name…"               TH: "ค้นหา SKU หรือชื่อสินค้า…"
placeholders.users.search             EN: "Search username, name, email, telephone…" TH: "ค้นหาชื่อผู้ใช้, ชื่อ, อีเมล, เบอร์โทรศัพท์…"

# Empty-state messages
orders.empty_state            EN: "No orders found."                TH: "ไม่พบออเดอร์"
invoices.empty_state          EN: "No invoices found."              TH: "ไม่พบใบแจ้งหนี้"
products.empty_state          EN: "No products found."              TH: "ไม่พบสินค้า"
customers.empty_state         EN: "No customers found."             TH: "ไม่พบลูกค้า"
purchase_orders.empty_state   EN: "No purchase orders found."       TH: "ไม่พบใบสั่งซื้อ"
users.empty_state             EN: "No users found."                 TH: "ไม่พบผู้ใช้งาน"
```

| #          | Task                                                                                                                                                                                                                     | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-22-12-01 | Add all `placeholders.*` keys to `config/locales/en.yml`                                                                                                                                                                 | `[x]`  |
| T-22-12-02 | Add the same keys with Thai values to `config/locales/th.yml`                                                                                                                                                            | `[x]`  |
| T-22-12-03 | Add all `*.empty_state` keys to `config/locales/en.yml` and `config/locales/th.yml`                                                                                                                                      | `[x]`  |
| T-22-12-04 | `app/views/orders/index.html.erb`: replace the search input `placeholder:` value with `t("placeholders.orders.search")`                                                                                                  | `[x]`  |
| T-22-12-05 | `app/views/orders/_form.html.erb`: replace the customer typeahead `placeholder=` with `t("placeholders.orders.customer_typeahead")`                                                                                      | `[x]`  |
| T-22-12-06 | `app/views/orders/_order_line_fields.html.erb`: replace the product search `placeholder=` with `t("placeholders.orders.line_product")` and the description `placeholder:` with `t("placeholders.orders.line_description")` | `[x]`  |
| T-22-12-07 | `app/views/invoices/index.html.erb`: replace the search input `placeholder:` with `t("placeholders.invoices.search")`                                                                                                    | `[x]`  |
| T-22-12-08 | `app/views/products/index.html.erb`: replace the search input `placeholder:` with `t("placeholders.products.search")`                                                                                                    | `[x]`  |
| T-22-12-09 | `app/views/customers/index.html.erb`: replace the search input `placeholder:` with `t("placeholders.customers.search")`                                                                                                  | `[x]`  |
| T-22-12-10 | `app/views/purchase_orders/index.html.erb`: replace the search input `placeholder:` with `t("placeholders.purchase_orders.search")`                                                                                      | `[x]`  |
| T-22-12-11 | `app/views/purchase_orders/_purchase_order_line_fields.html.erb` and `app/views/purchase_orders/_add_line_form.html.erb`: replace product search `placeholder=` with `t("placeholders.purchase_orders.line_product")`    | `[x]`  |
| T-22-12-12 | `app/views/users/index.html.erb`: replace the search input `placeholder:` with `t("placeholders.users.search")`                                                                                                          | `[x]`  |
| T-22-12-13 | `app/views/orders/index.html.erb`: replace the empty-state `<td>` text with `t("orders.empty_state")`                                                                                                                      | `[x]`  |
| T-22-12-16 | `app/views/invoices/index.html.erb`: replace the empty-state `<td>` text with `t("invoices.empty_state")`                                                                                                                    | `[x]`  |
| T-22-12-17 | `app/views/products/index.html.erb`: replace the empty-state `<td>` text with `t("products.empty_state")`                                                                                                                    | `[x]`  |
| T-22-12-18 | `app/views/customers/index.html.erb`: replace the empty-state `<td>` text with `t("customers.empty_state")`                                                                                                                  | `[x]`  |
| T-22-12-19 | `app/views/purchase_orders/index.html.erb`: replace the empty-state `<td>` text with `t("purchase_orders.empty_state")`                                                                                                      | `[x]`  |
| T-22-12-20 | `app/views/users/index.html.erb`: replace the empty-state `<td>` text with `t("users.empty_state")`                                                                                                                          | `[x]`  |
| T-22-12-14 | Write RSpec request spec `spec/requests/i18n/placeholders_i18n_spec.rb`: (a) TH user `GET /orders` response body includes "ค้นหาเลขที่ออเดอร์"; (b) TH user `GET /products` body includes "ค้นหาโดยชื่อ, SKU"; (c) EN user `GET /orders` body includes "Search order number" | `[x]`  |
| T-22-12-15 | Write RSpec request spec `spec/requests/i18n/empty_state_i18n_spec.rb`: authenticated TH user with no data in DB requests `GET /orders`, `GET /products`, `GET /customers` — each response body includes the Thai empty-state string | `[x]`  |
| T-22-12-21 | Write RSpec request spec `spec/requests/i18n/empty_state_invoices_po_users_spec.rb`: TH user with no data requests `GET /invoices`, `GET /purchase_orders`, `GET /users` — bodies include "ไม่พบใบแจ้งหนี้", "ไม่พบใบสั่งซื้อ", "ไม่พบผู้ใช้งาน" | `[x]`  |
| T-22-12-22 | Write RSpec request spec: TH user `GET /orders/new` body includes "พิมพ์ชื่อหรือเบอร์โทรศัพท์…" (customer typeahead placeholder); EN user body includes "Type name or phone…"                                              | `[x]`  |
| T-22-12-23 | Write RSpec request spec: TH user `GET /orders/new` body includes "ค้นหา SKU หรือชื่อสินค้า…" (order-line product placeholder) and "รายละเอียดสินค้า…" (description placeholder)                                          | `[x]`  |
| T-22-12-24 | Write RSpec request spec: TH user `GET /invoices` body includes "ค้นหาเลขที่ใบแจ้งหนี้" in the search input `placeholder` attribute                                                                                        | `[x]`  |
| T-22-12-25 | Write RSpec request spec: TH user `GET /customers` body includes "ค้นหาโดยชื่อ, ที่อยู่" in the search input `placeholder` attribute                                                                                       | `[x]`  |
| T-22-12-26 | Write RSpec request spec: TH user `GET /purchase_orders` body includes "ค้นหาโดยเลขที่ใบสั่งซื้อ" in the search input `placeholder` attribute                                                                              | `[x]`  |
| T-22-12-27 | Write RSpec request spec: TH user `GET /purchase_orders/new` body includes "ค้นหา SKU หรือชื่อสินค้า…" in the PO line product search `placeholder` attribute                                                               | `[x]`  |
| T-22-12-28 | Write RSpec request spec: TH user `GET /users` body includes "ค้นหาชื่อผู้ใช้" in the search input `placeholder` attribute                                                                                                  | `[x]`  |
