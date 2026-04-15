# EPIC-09 — Polish, API Documentation & Deployment Prep

**Phase:** 9  
**Status:** 🟢 Completed  
**Goal:** System is production-ready. rswag OpenAPI docs generated from specs; full RSpec suite ≥ 90% coverage; RuboCop passes; database indexes audited; production configuration and seeds complete.

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

### STORY-09-01 — API Documentation (rswag)
**Status:** � In Progress  
**Description:** Every API endpoint has a corresponding rswag request spec that documents parameters, request body, and response schemas. Running `rails rswag:specs:swaggerize` generates a valid OpenAPI 3.0 `swagger.json`. Swagger UI mounted at `/api-docs`.

| # | Task | Status |
|---|---|---|
| T-09-01-01 | Run `rails generate rswag:install` to scaffold `spec/swagger_helper.rb` and `swagger/v1/swagger.yaml` | `[x]` |
| T-09-01-02 | Write rswag request spec for Auth endpoints (sign_in, refresh, verify) | `[x]` |
| T-09-01-03 | Write rswag request specs for User and Profile endpoints | `[x]` |
| T-09-01-04 | Write rswag request specs for Role, Group, Permission endpoints | `[x]` |
| T-09-01-05 | Write rswag request specs for Vendor, Brand, ProductClass, ProductCategory endpoints | `[x]` |
| T-09-01-06 | Write rswag request specs for Product (CRUD, advance search, last price, filters) endpoints | `[x]` |
| T-09-01-07 | Write rswag request specs for Stock (deposit, withdraw, recalculate, transactions) endpoints | `[x]` |
| T-09-01-08 | Write rswag request specs for Customer and LogisticCompany endpoints | `[x]` |
| T-09-01-09 | Write rswag request specs for Order (CRUD, status lists, export, combine bills, bulk update, reports) endpoints | `[x]` |
| T-09-01-10 | Write rswag request specs for Upload and Country endpoints | `[x]` |
| T-09-01-11 | Run `bundle exec rails rswag:specs:swaggerize` and verify `swagger/v1/swagger.yaml` is valid | `[x]` |
| T-09-01-12 | Mount Rswag UI and API engines in `routes.rb` at `/api-docs` | `[x]` |
| T-09-01-13 | Verify Swagger UI loads at `/api-docs` and all endpoints are navigable | `[x]` |

---

### STORY-09-02 — Test Coverage & Code Quality
**Status:** 🟢 Completed  
**Description:** Achieve ≥ 90% RSpec test coverage. Zero RuboCop offences. All CI quality gates pass.

| # | Task | Status |
|---|---|---|
| T-09-02-01 | Configure SimpleCov in `spec/spec_helper.rb`: `minimum_coverage 90`, output to `coverage/` | `[x]` |
| T-09-02-02 | Run full RSpec suite: `bundle exec rspec --format progress`; note any failures | `[x]` |
| T-09-02-03 | Fix all failing specs | `[x]` |
| T-09-02-04 | Review SimpleCov report; write missing specs for uncovered branches | `[x]` |
| T-09-02-05 | Ensure all 8 grand total calculation combinations are covered by specs | `[x]` |
| T-09-02-06 | Ensure stock deposit/withdraw/checkpoint specs cover edge cases (zero stock, over-withdrawal) | `[x]` |
| T-09-02-07 | Ensure signed export URL expiry is tested (stub `Time.now` for expiry test) | `[x]` |
| T-09-02-08 | Run `bundle exec rubocop` and list all offences | `[x]` |
| T-09-02-09 | Run `bundle exec rubocop --autocorrect-all` for auto-fixable offences | `[x]` |
| T-09-02-10 | Manually fix remaining RuboCop offences (complex cops that cannot be auto-corrected) | `[x]` |
| T-09-02-11 | Add `.github/workflows/ci.yml` (or equivalent) running `rspec` and `rubocop` on every push | `[x]` |

---

### STORY-09-03 — Database Indexes, Seeds & Production Config
**Status:** 🟢 Completed  
**Description:** Audit all database indexes for completeness. Add production environment configuration. Write comprehensive seeds so `rails db:seed` on a fresh database produces a fully working system.

| # | Task | Status |
|---|---|---|
| T-09-03-01 | Audit all FK columns and add missing indexes (check with `bundle exec rails db:schema:dump` and review) | `[x]` |
| T-09-03-02 | Verify unique index on `orders.order_number` | `[x]` |
| T-09-03-03 | Verify unique index on `products.sku` | `[x]` |
| T-09-03-04 | Verify unique index on `(branch_id, product_id)` in `product_stocks` | `[x]` |
| T-09-03-05 | Add index on `orders.running_date` (used in order number generation query) | `[x]` |
| T-09-03-06 | Add index on `orders.status` and `orders.logistic_status` (used in filtered list queries) | `[x]` |
| T-09-03-07 | Add index on `customers.deleted_at` (used in default scope) | `[x]` |
| T-09-03-08 | Configure `config/environments/production.rb`: `config.force_ssl = true`, `config.log_level = :info`, asset host, log formatter | `[x]` |
| T-09-03-09 | Configure Active Storage in production to use S3 (or equivalent object store); add env vars `AWS_BUCKET`, `AWS_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | `[x]` |
| T-09-03-10 | Write `db/seeds.rb` orchestrating: `load 'db/seeds/countries.rb'`, `load 'db/seeds/branches.rb'`, `load 'db/seeds/admin_user.rb'` | `[x]` |
| T-09-03-11 | Ensure `db/seeds/admin_user.rb` is idempotent (uses `find_or_create_by!`) | `[x]` |
| T-09-03-12 | Write `README.md` covering: prerequisites, environment variable list, setup steps (`bundle install`, `rails db:create db:migrate db:seed`), running the server, running tests | `[x]` |
| T-09-03-13 | Final security checklist review (see §9 of new_requirement.md): JWT secret, Pundit `verify_authorized`, export auth, FK nullify, 409 status | `[x]` |
| T-09-03-14 | Verify `rails db:seed` on a fresh database boots without errors and admin user can log in | `[x]` |
