# PSK ERP — Epics

> All epics are derived from `new_requirement.md`. Each epic maps to one implementation phase. Stories and tasks live inside each epic's own folder.

---

## Legend

| Symbol | Meaning |
|---|---|
| 🔴 | Not Started |
| 🟡 | In Progress |
| 🟢 | Completed |

---

## Epics Overview

| Code | Title | Phase | Status | Stories |
|---|---|---|---|---|
| [EPIC-01](./EPIC-01/stories.md) | Project Bootstrap & Infrastructure | Phase 1 | 🔴 Not Started | 4 |
| [EPIC-02](./EPIC-02/stories.md) | Authentication & User Management | Phase 2 | 🔴 Not Started | 4 |
| [EPIC-03](./EPIC-03/stories.md) | Country, Logistic Company & Customer | Phase 3 | 🔴 Not Started | 3 |
| [EPIC-04](./EPIC-04/stories.md) | Product Catalog Module | Phase 4 | 🔴 Not Started | 5 |
| [EPIC-05](./EPIC-05/stories.md) | Stock Management Module | Phase 5 | 🔴 Not Started | 3 |
| [EPIC-06](./EPIC-06/stories.md) | Order Module (Core) | Phase 6 | 🔴 Not Started | 6 |
| [EPIC-07](./EPIC-07/stories.md) | Excel Export & Reporting Module | Phase 7 | 🔴 Not Started | 4 |
| [EPIC-08](./EPIC-08/stories.md) | Bulk Product Import Module | Phase 8 | 🔴 Not Started | 3 |
| [EPIC-09](./EPIC-09/stories.md) | Polish, API Docs & Deployment Prep | Phase 9 | � Completed | 3 |
| [EPIC-10](./EPIC-10/stories.md) | Tom Select Typeahead Dropdowns Across All Forms | Phase 10 | 🟢 Completed | 5 |
| [EPIC-11](./EPIC-11/stories.md) | Order Form UX Redesign (Modern, iPad-first) | Phase 11 | 🔴 Not Started | 7 |
| [EPIC-12](./EPIC-12/stories.md) | Delivery Order Print (บิลขนส่ง) | Phase 12 | 🔴 Not Started | 3 |
| [EPIC-13](./EPIC-13/stories.md) | Product Stock Enhancements | Phase 13 | 🔴 Not Started | 4 |
| [EPIC-14](./EPIC-14/stories.md) | Order Intelligence: Price Monitor, Audit Trail & Duplicate Detection | Phase 14 | 🔴 Not Started | 3 |
| [EPIC-22](./EPIC-22/stories.md) | Production-Ready UI Consistency & Full i18n (EN/TH) | Phase 22 | 🟡 In Progress | 12 |

---

## Epic Descriptions

### EPIC-01 — Project Bootstrap & Infrastructure
**Goal:** A working Rails 8 application skeleton with all gem dependencies installed, PostgreSQL connected, Active Storage configured, Tailwind + Railsblocks rendering, base sidebar/header layout in place, and the RSpec/RuboCop toolchain ready.

**Acceptance criteria:** `rails server` starts; the layout renders with the full sidebar; no errors. RSpec runs green on an empty test suite.

---

### EPIC-02 — Authentication & User Management
**Goal:** Users can log in via Devise + JWT; admins can create, update, deactivate, and manage users; roles with permission arrays can be created and assigned to user profiles; Pundit authorization enforced across all controllers.

**Acceptance criteria:** Admin logs in, creates a user with a role, assigns permissions; sidebar menu items are hidden/shown per role; RSpec auth specs pass.

---

### EPIC-03 — Country, Logistic Company & Customer
**Goal:** ISO 3166-1 country reference data seeded and publicly accessible; logistic companies manageable via full CRUD; customers managed with soft delete so deleted customers are hidden from default list but preserved in storage.

**Acceptance criteria:** Soft delete hides customers; country list requires no auth; logistic filter endpoint returns correct results.

---

### EPIC-04 — Product Catalog Module
**Goal:** Complete product catalogue including vendor (with SKU prefix auto-generation), brand, product class, product category, custom attributes, and products with parent/child hierarchy. Cost field hidden for unauthorised users.

**Acceptance criteria:** Full CRUD for all catalogue entities works; SKU/barcode auto-generated; duplicate name rejection works; child products are nested under parents; cost excluded from response when user lacks permission.

---

### EPIC-05 — Stock Management Module
**Goal:** Inventory tracking per branch: deposit and withdraw stock, maintain holding amounts, record an immutable transaction ledger, and support checkpoint recalculation to reconcile discrepancies.

**Acceptance criteria:** Deposit/withdraw update stock amounts; transactions are logged; checkpoint recalculation produces correct totals; stock auto-created on first access.

---

### EPIC-06 — Order Module (Core)
**Goal:** Full order lifecycle (Draft → Paid → Completed / Cancelled) with collision-safe order number generation, nested order lines, server-side grand total calculation covering all VAT/discount/withholding tax combinations, and automatic stock movements on every line change.

**Acceptance criteria:** Orders created with correct order numbers; grand total matches formula for all tax combinations; stock withdraws/deposits fire on line create/update/delete; bulk status update works.

---

### EPIC-07 — Excel Export & Reporting Module
**Goal:** Secure order invoice export (auth required), combined billing statement for multiple orders, customer summary and sales summary Excel downloads, and a monthly sales graph on the dashboard.

**Acceptance criteria:** All files download with correct content; export endpoint rejects unauthenticated requests; signed URL expires after 10 minutes; report data matches completed-orders-only filter.

---

### EPIC-08 — Bulk Product Import Module
**Goal:** Staff can upload an `.xlsx` file; a Sidekiq background job parses each sheet and upserts products and related entities; the user is notified of the result via Turbo Stream.

**Acceptance criteria:** Valid Excel file triggers job and creates/updates products; invalid file returns a structured error; import result notification appears without page reload.

---

### EPIC-09 — Polish, API Docs & Deployment Prep
**Goal:** rswag OpenAPI docs generated from RSpec specs; full test suite achieves ≥ 90% coverage; RuboCop passes; database indexes audited; production configuration complete; seeds cover all bootstrap data.

**Acceptance criteria:** `/api-docs` renders Swagger UI; `bundle exec rspec` passes with ≥ 90% coverage; `bundle exec rubocop` exits cleanly; `rails db:seed` on a fresh DB produces a working system.

---

### EPIC-12 — Delivery Order Print (บิลขนส่ง)
**Goal:** Users can click a "Print DO" link on any order row in the Orders list to open a standalone printable Delivery Order (บิลขนส่ง) HTML page in a new tab; the page shows a Code128 barcode of the order number, all order details (excluding `internal_note`), a 7-column Thai-labelled order-lines table, grand total summary, and manual signature space — formatted for A4 (≥ 16 lines/page) or A5 — with a Print button triggering the browser's native print dialog.

---

### EPIC-10 — Tom Select Typeahead Dropdowns Across All Forms
**Goal:** Every `<select>` in the PSK ERP web UI is enhanced with Tom Select v2.4.3 typeahead via a shared Stimulus controller, enabling keyboard-driven search and selection for products (4 selects), orders (4 selects + 2 in order line rows), and customers (2 selects).

**Acceptance criteria:** All 12 select fields across `products/_form`, `orders/_form`, `customers/_form`, and `orders/_order_line_fields` render Tom Select widgets; typeahead filtering works on all fields; dynamically appended order line rows auto-initialise Tom Select via Stimulus `connect()`; no double-init on Turbo cache restore.
