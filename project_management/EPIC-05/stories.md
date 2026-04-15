# EPIC-05 — Stock Management Module

**Phase:** 5  
**Status:** 🟢 Completed  
**Goal:** Inventory stock tracking per branch with deposit, withdraw, holding amounts, immutable transaction ledger, and checkpoint recalculation for balance reconciliation.

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

### STORY-05-01 — Branch Setup
**Status:** 🟢 Completed  
**Description:** The Branch model represents a physical warehouse location. The system currently operates with one branch but is architecturally multi-branch. Seed the default "Main Branch".

| # | Task | Status |
|---|---|---|
| T-05-01-01 | Generate `Branch` model: `name:string` (unique, not null), timestamps | `[x]` |
| T-05-01-02 | Add presence and uniqueness validation on `name` | `[x]` |
| T-05-01-03 | Implement `BranchesController` with full CRUD | `[x]` |
| T-05-01-04 | Build Branch list and form views | `[x]` |
| T-05-01-05 | Add `BranchPolicy` with standard Pundit predicates | `[x]` |
| T-05-01-06 | Add `Branch.default` class method returning the first branch (or `find_by(name: 'Main Branch')`) | `[x]` |
| T-05-01-07 | Add `db/seeds/branches.rb`: `Branch.find_or_create_by!(name: 'Main Branch')` | `[x]` |
| T-05-01-08 | Write RSpec model and request specs | `[x]` |

---

### STORY-05-02 — Product Stock Tracking
**Status:** 🟢 Completed  
**Description:** `ProductStock` tracks `amount` (physical) and `holding_amount` (reserved) per product per branch. `total_amount` is the available balance. Auto-created when first accessed for a branch + product pair.

| # | Task | Status |
|---|---|---|
| T-05-02-01 | Generate `ProductStock` model: `branch_id:bigint` FK, `product_id:bigint` FK, `amount:decimal{12,2}` (default 0), `holding_amount:decimal{12,2}` (default 0), timestamps | `[x]` |
| T-05-02-02 | Add unique index on `(branch_id, product_id)` | `[x]` |
| T-05-02-03 | Add `belongs_to :branch` and `belongs_to :product` associations | `[x]` |
| T-05-02-04 | Implement `total_amount` computed getter: `amount - holding_amount` | `[x]` |
| T-05-02-05 | Implement `ProductStock.find_or_create_for!(product:, branch: Branch.default)` class method (auto-create with amount 0) | `[x]` |
| T-05-02-06 | Implement `deposit!(amount:, reason:, related_object: nil)` instance method: increments `amount`, creates `IB` transaction | `[x]` |
| T-05-02-07 | Implement `withdraw!(amount:, reason:, related_object: nil)` instance method: decrements `amount`, creates `OB` transaction | `[x]` |
| T-05-02-08 | Implement `withdraw_from_holding!(amount:, reason:, related_object: nil)`: decrements both `amount` and `holding_amount`, creates `OB` transaction | `[x]` |
| T-05-02-09 | Implement `StocksController` with `index` and `show` actions | `[x]` |
| T-05-02-10 | Add `POST /stocks/:id/deposit` and `POST /stocks/:id/withdraw` custom member actions | `[x]` |
| T-05-02-11 | Build Stock list view: Railsblocks table showing product, branch, amount, holding_amount, total_amount | `[x]` |
| T-05-02-12 | Build Stock detail view with deposit/withdraw forms | `[x]` |
| T-05-02-13 | Add `StockPolicy` with standard predicates | `[x]` |
| T-05-02-14 | Write RSpec model specs: deposit, withdraw, withdraw_from_holding, total_amount, auto-create | `[x]` |
| T-05-02-15 | Write RSpec request specs for deposit and withdraw actions | `[x]` |

---

### STORY-05-03 — Stock Transaction Ledger & Checkpoint
**Status:** 🟢 Completed  
**Description:** Every stock movement creates an immutable `ProductStockTransaction` entry. Checkpoint recalculation replays all transactions from the last snapshot to reconcile discrepancies.

| # | Task | Status |
|---|---|---|
| T-05-03-01 | Generate `ProductStockTransaction` model: `product_stock_id:bigint` FK, `transaction_type:string{2}` (`IB`/`OB`), `amount:decimal{12,2}`, `related_object_type:string`, `related_object_id:bigint`, `reason:string{255}`, `recal_checkpoint:decimal{12,2}` (default 0), timestamps | `[x]` |
| T-05-03-02 | Add `belongs_to :product_stock` and `belongs_to :related_object, polymorphic: true, optional: true` | `[x]` |
| T-05-03-03 | Validate presence of `transaction_type`, `amount` (> 0); `transaction_type` must be `IB` or `OB` | `[x]` |
| T-05-03-04 | Implement `recalculate_checkpoint!` on `ProductStock`: sums all transactions since the last non-zero `recal_checkpoint`, updates `amount`, writes checkpoint to the latest transaction | `[x]` |
| T-05-03-05 | Add `POST /stocks/:id/recalculate_checkpoint` member action calling `recalculate_checkpoint!` | `[x]` |
| T-05-03-06 | Add `GET /stocks/:id/transactions` member action returning paginated transaction ledger | `[x]` |
| T-05-03-07 | Build transaction list view within Stock detail (Railsblocks table: date, type badge, amount, reason) | `[x]` |
| T-05-03-08 | Write RSpec model specs: transaction creation on deposit/withdraw; checkpoint recalculation correctness | `[x]` |
| T-05-03-09 | Write RSpec request specs for transactions list and recalculate checkpoint | `[x]` |
