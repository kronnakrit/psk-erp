# EPIC-08 — Bulk Product Import Module

**Phase:** 8  
**Status:** � Completed  
**Goal:** Staff can upload an `.xlsx` file; a Sidekiq background job parses each sheet, upserts products and related entities; the user sees the import result via Turbo Stream without page reload.

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

### STORY-08-01 — File Upload Infrastructure
**Status:** 🟢 Completed  
**Description:** Create the `Upload` model, controller, and UI. Validate uploaded files are `.xlsx` only. Store files via Active Storage.

| # | Task | Status |
|---|---|---|
| T-08-01-01 | Generate `Upload` model: Active Storage `has_one_attached :file`, timestamps | `[x]` |
| T-08-01-02 | Add `status:string` column to `Upload` with values: `pending`, `processing`, `completed`, `failed` (default: `pending`) | `[x]` |
| T-08-01-03 | Add `result_summary:jsonb` column to `Upload` to store `{ rows_processed, rows_failed, errors }` | `[x]` |
| T-08-01-04 | Implement `UploadsController#create`: validates MIME type is `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`; returns `422` for invalid type | `[x]` |
| T-08-01-05 | On successful upload, enqueue `BulkProductImportJob` with the upload ID | `[x]` |
| T-08-01-06 | Build Upload UI: file picker button (`.xlsx` only), upload progress indicator | `[x]` |
| T-08-01-07 | Build Upload history list view: shows past uploads with status badge and result summary | `[x]` |
| T-08-01-08 | Add `UploadsController` under the Catalog sidebar section | `[x]` |
| T-08-01-09 | Add `UploadPolicy` with standard Pundit predicates | `[x]` |
| T-08-01-10 | Write RSpec request specs: valid file accepted, invalid MIME type rejected, job enqueued | `[x]` |

---

### STORY-08-02 — Bulk Product Import Job
**Status:** 🟢 Completed  
**Description:** Sidekiq job parses the uploaded Excel file sheet by sheet. Each sheet maps to a ProductClass. Vendor, Brand, Category, and Attribute records are upserted. Products are created or updated. Child products are linked to the most recent parent in the sheet.

| # | Task | Status |
|---|---|---|
| T-08-02-01 | Implement `BulkProductImportJob < ApplicationJob` with `queue_as :imports` | `[x]` |
| T-08-02-02 | In `perform(upload_id)`: update `upload.status = :processing`; wrap entire import in a transaction | `[x]` |
| T-08-02-03 | Open file using `roo`: `Roo::Spreadsheet.open(file_path)` | `[x]` |
| T-08-02-04 | Iterate sheets: each sheet name → `ProductClass.find_or_create_by!(name: sheet_name)` | `[x]` |
| T-08-02-05 | Map columns per row: `vendor`, `sku`, `brand`, `product_categories`, `product_type`, `barcode`, `name`, `unit`, `price`, `cost`, `description_en`, `description_th` | `[x]` |
| T-08-02-06 | For columns prefixed with `attr`, treat as attribute name → value pair and upsert `ProductAttribute` | `[x]` |
| T-08-02-07 | Upsert `Vendor` by name (create if not found; skip `initial_name` auto-gen on seed) | `[x]` |
| T-08-02-08 | Upsert `Brand` by name | `[x]` |
| T-08-02-09 | Upsert `ProductCategory` by name for each comma-separated value in `product_categories` column | `[x]` |
| T-08-02-10 | For Standalone/Parent rows: `Product.find_or_initialize_by(sku: sku)` and assign all fields; save | `[x]` |
| T-08-02-11 | For Child rows: use `index` column to link to the most recently created/found Parent product in the current sheet | `[x]` |
| T-08-02-12 | Default missing numeric values (`price`, `cost`) to `0` | `[x]` |
| T-08-02-13 | Track `rows_processed` and `rows_failed` counters; accumulate row-level errors | `[x]` |
| T-08-02-14 | On completion: update `upload.status = :completed` and save `result_summary` | `[x]` |
| T-08-02-15 | On unhandled exception: update `upload.status = :failed`; do not re-raise (prevent dead job queue) | `[x]` |
| T-08-02-16 | Write RSpec job spec using `Sidekiq::Testing.inline!`; fixture `.xlsx` file with valid and invalid rows | `[x]` |
| T-08-02-17 | Write edge-case specs: empty sheet, unknown product_type value, missing required column | `[x]` |

---

### STORY-08-03 — Import Status Notifications
**Status:** 🟢 Completed  
**Description:** When the Sidekiq job completes, the user who triggered the import receives a real-time notification via Turbo Stream without needing to refresh the page.

| # | Task | Status |
|---|---|---|
| T-08-03-01 | Configure Action Cable with Redis adapter in `config/cable.yml` | `[x]` |
| T-08-03-02 | Create `ImportNotificationsChannel` — subscribes authenticated users to their own import updates | `[x]` |
| T-08-03-03 | At end of `BulkProductImportJob#perform`, broadcast a Turbo Stream update to `"import_status_#{upload.user_id}"` replacing the upload row with updated status and result summary | `[x]` |
| T-08-03-04 | Add `user_id:bigint` FK to `Upload` to track who triggered the import | `[x]` |
| T-08-03-05 | Wire up Action Cable subscription in the Upload history view using Turbo Streams | `[x]` |
| T-08-03-06 | Display a dismissable banner notification when an import completes (success or failure) | `[x]` |
| T-08-03-07 | Write RSpec job spec verifying that a Turbo Stream broadcast is triggered on job completion | `[x]` |
