# EPIC-01 — Project Bootstrap & Infrastructure

**Phase:** 1  
**Status:** 🔴 Not Started  
**Goal:** A working Rails 8 skeleton with all dependencies installed, PostgreSQL connected, Railsblocks/Tailwind rendering, base sidebar + header layout, and the RSpec/RuboCop toolchain ready.

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

### STORY-01-01 — Rails Application Initialisation
**Status:** � In Progress  
**Description:** Create the new Rails 8 application with PostgreSQL as the database engine, skipping the default test framework in favour of RSpec. Verify the app boots with no errors.

| # | Task | Status |
|---|---|---|
| T-01-01-01 | Run `rails new psk-erp --database=postgresql --skip-test --css=tailwind` | `[x]` |
| T-01-01-02 | Commit initial Rails skeleton to version control | `[~]` |
| T-01-01-03 | Configure `database.yml` with correct host/user/password for dev and test environments | `[ ]` |
| T-01-01-04 | Run `rails db:create` and verify both `psk_erp_development` and `psk_erp_test` databases exist | `[ ]` |
| T-01-01-05 | Set up `.env` file (gitignored) and `dotenv-rails` gem for local environment variables | `[ ]` |
| T-01-01-06 | Store DB credentials and JWT secret in `.env`; reference via `ENV[]` in `database.yml` and credentials | `[ ]` |

---

### STORY-01-02 — Gem Dependencies Installation
**Status:** 🔴 Not Started  
**Description:** Add all required gems to the `Gemfile`, install them, and verify no dependency conflicts.

| # | Task | Status |
|---|---|---|
| T-01-02-01 | Add authentication gems: `devise`, `devise-jwt` | `[ ]` |
| T-01-02-02 | Add authorisation gem: `pundit` | `[ ]` |
| T-01-02-03 | Add pagination gem: `pagy` | `[ ]` |
| T-01-02-04 | Add search gem: `ransack` | `[ ]` |
| T-01-02-05 | Add UI gems: `railsblocks` (or equivalent Tailwind component set) | `[ ]` |
| T-01-02-06 | Add Excel gems: `caxlsx`, `caxlsx-rails` | `[ ]` |
| T-01-02-07 | Add import gem: `roo` | `[ ]` |
| T-01-02-08 | Add background job gems: `sidekiq`, `redis` | `[ ]` |
| T-01-02-09 | Add chart gems: `chartkick`, `groupdate` | `[ ]` |
| T-01-02-10 | Add testing gems (test/development group): `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `faker`, `simplecov` | `[ ]` |
| T-01-02-11 | Add code quality gems: `rubocop-rails`, `rubocop-rspec` | `[ ]` |
| T-01-02-12 | Add API docs gem: `rswag` | `[ ]` |
| T-01-02-13 | Run `bundle install` and resolve any conflicts | `[ ]` |

---

### STORY-01-03 — Infrastructure & Tooling Configuration
**Status:** 🔴 Not Started  
**Description:** Configure Sidekiq, Active Storage, Tailwind CSS, and Railsblocks. Mount admin tools with proper authentication gates.

| # | Task | Status |
|---|---|---|
| T-01-03-01 | Run `rails active_storage:install` and migrate | `[ ]` |
| T-01-03-02 | Configure `config/storage.yml` with local adapter for development | `[ ]` |
| T-01-03-03 | Create `config/sidekiq.yml` with queues: `default`, `imports`, `reports` | `[ ]` |
| T-01-03-04 | Mount Sidekiq Web UI at `/sidekiq` protected by admin authentication in `routes.rb` | `[ ]` |
| T-01-03-05 | Configure Redis URL in `.env` (`REDIS_URL`) and `config/initializers/sidekiq.rb` | `[ ]` |
| T-01-03-06 | Run Tailwind CSS install (`rails tailwindcss:install`) and verify compilation | `[ ]` |
| T-01-03-07 | Install and configure Railsblocks per gem documentation | `[ ]` |
| T-01-03-08 | Add `Procfile` with `web: rails server` and `sidekiq: bundle exec sidekiq` for Foreman | `[ ]` |
| T-01-03-09 | Generate RuboCop baseline config: `bundle exec rubocop --auto-gen-config` | `[ ]` |
| T-01-03-10 | Configure Pagy in `config/initializers/pagy.rb` (default page size: 20) | `[ ]` |

---

### STORY-01-04 — Base Application Layout
**Status:** 🔴 Not Started  
**Description:** Build the persistent sidebar + header layout that all authenticated pages will use. Sidebar must include the full menu hierarchy. Flash messages appear below the header.

| # | Task | Status |
|---|---|---|
| T-01-04-01 | Create `app/views/layouts/application.html.erb` with header + sidebar + main content structure | `[ ]` |
| T-01-04-02 | Create `app/views/layouts/_header.html.erb` partial (logo left, user dropdown right) | `[ ]` |
| T-01-04-03 | Create `app/views/layouts/_sidebar.html.erb` with full menu: Dashboard, Order, Catalog (collapsible group with 5 items), User Group, User, Customer, Logistic Company | `[ ]` |
| T-01-04-04 | Wrap main content area in `<%= turbo_frame_tag "main_content" %>` | `[ ]` |
| T-01-04-05 | Create `app/views/layouts/_flash.html.erb` for success/error/warning alerts (Railsblocks `rb_alert`) | `[ ]` |
| T-01-04-06 | Create Stimulus `sidebar_controller.js` to handle Catalog group expand/collapse with `localStorage` persistence | `[ ]` |
| T-01-04-07 | Create Stimulus `flash_controller.js` to auto-dismiss flash alerts after 5 seconds | `[ ]` |
| T-01-04-08 | Implement mobile-responsive sidebar: icon-only rail on < 1024px; hamburger overlay toggle | `[ ]` |
| T-01-04-09 | Set up RSpec: run `rails generate rspec:install`; configure FactoryBot and Shoulda Matchers in `spec/rails_helper.rb` | `[ ]` |
| T-01-04-10 | Write a smoke test verifying the root route renders within 200ms | `[ ]` |
| T-01-04-11 | Verify `rails server` boots cleanly; confirm layout renders with no JS errors in browser console | `[ ]` |
