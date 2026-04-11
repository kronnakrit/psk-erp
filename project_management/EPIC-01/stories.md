# EPIC-01 — Project Bootstrap & Infrastructure

**Phase:** 1  
**Status:** � Completed  
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
**Status:** 🟢 Completed  
**Description:** Create the new Rails 8 application with PostgreSQL as the database engine, skipping the default test framework in favour of RSpec. Verify the app boots with no errors.

| # | Task | Status |
|---|---|---|
| T-01-01-01 | Run `rails new psk-erp --database=postgresql --skip-test --css=tailwind` | `[x]` |
| T-01-01-02 | Commit initial Rails skeleton to version control | `[x]` |
| T-01-01-03 | Configure `database.yml` with correct host/user/password for dev and test environments | `[x]` |
| T-01-01-04 | Run `rails db:create` and verify both `psk_erp_development` and `psk_erp_test` databases exist | `[x]` |
| T-01-01-05 | Set up `.env` file (gitignored) and `dotenv-rails` gem for local environment variables | `[x]` |
| T-01-01-06 | Store DB credentials and JWT secret in `.env`; reference via `ENV[]` in `database.yml` and credentials | `[x]` |

---

### STORY-01-02 — Gem Dependencies Installation
**Status:** 🟢 Completed  
**Description:** Add all required gems to the `Gemfile`, install them, and verify no dependency conflicts.

| # | Task | Status |
|---|---|---|
| T-01-02-01 | Add authentication gems: `devise`, `devise-jwt` | `[x]` |
| T-01-02-02 | Add authorisation gem: `pundit` | `[x]` |
| T-01-02-03 | Add pagination gem: `pagy` | `[x]` |
| T-01-02-04 | Add search gem: `ransack` | `[x]` |
| T-01-02-05 | Add UI gems: `railsblocks` (or equivalent Tailwind component set) | `[x]` |
| T-01-02-06 | Add Excel gems: `caxlsx`, `caxlsx-rails` | `[x]` |
| T-01-02-07 | Add import gem: `roo` | `[x]` |
| T-01-02-08 | Add background job gems: `sidekiq`, `redis` | `[x]` |
| T-01-02-09 | Add chart gems: `chartkick`, `groupdate` | `[x]` |
| T-01-02-10 | Add testing gems (test/development group): `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `faker`, `simplecov` | `[x]` |
| T-01-02-11 | Add code quality gems: `rubocop-rails`, `rubocop-rspec` | `[x]` |
| T-01-02-12 | Add API docs gem: `rswag` | `[x]` |
| T-01-02-13 | Run `bundle install` and resolve any conflicts | `[x]` |

---

### STORY-01-03 — Infrastructure & Tooling Configuration
**Status:** 🟢 Completed  
**Description:** Configure Sidekiq, Active Storage, Tailwind CSS, and Railsblocks. Mount admin tools with proper authentication gates.

| # | Task | Status |
|---|---|---|
| T-01-03-01 | Run `rails active_storage:install` and migrate | `[x]` |
| T-01-03-02 | Configure `config/storage.yml` with local adapter for development | `[x]` |
| T-01-03-03 | Create `config/sidekiq.yml` with queues: `default`, `imports`, `reports` | `[x]` |
| T-01-03-04 | Mount Sidekiq Web UI at `/sidekiq` protected by admin authentication in `routes.rb` | `[x]` |
| T-01-03-05 | Configure Redis URL in `.env` (`REDIS_URL`) and `config/initializers/sidekiq.rb` | `[x]` |
| T-01-03-06 | Run Tailwind CSS install (`rails tailwindcss:install`) and verify compilation | `[x]` |
| T-01-03-07 | Install and configure Railsblocks per gem documentation | `[x]` |
| T-01-03-08 | Add `Procfile` with `web: rails server` and `sidekiq: bundle exec sidekiq` for Foreman | `[x]` |
| T-01-03-09 | Generate RuboCop baseline config: `bundle exec rubocop --auto-gen-config` | `[x]` |
| T-01-03-10 | Configure Pagy in `config/initializers/pagy.rb` (default page size: 20) | `[x]` |

---

### STORY-01-04 — Base Application Layout
**Status:** 🟢 Completed  
**Description:** Build the persistent sidebar + header layout that all authenticated pages will use. Sidebar must include the full menu hierarchy. Flash messages appear below the header.

| # | Task | Status |
|---|---|---|
| T-01-04-01 | Create `app/views/layouts/application.html.erb` with header + sidebar + main content structure | `[x]` |
| T-01-04-02 | Create `app/views/layouts/_header.html.erb` partial (logo left, user dropdown right) | `[x]` |
| T-01-04-03 | Create `app/views/layouts/_sidebar.html.erb` with full menu: Dashboard, Order, Catalog (collapsible group with 5 items), User Group, User, Customer, Logistic Company | `[x]` |
| T-01-04-04 | Wrap main content area in `<%= turbo_frame_tag "main_content" %>` | `[x]` |
| T-01-04-05 | Create `app/views/layouts/_flash.html.erb` for success/error/warning alerts (Railsblocks `rb_alert`) | `[x]` |
| T-01-04-06 | Create Stimulus `sidebar_controller.js` to handle Catalog group expand/collapse with `localStorage` persistence | `[x]` |
| T-01-04-07 | Create Stimulus `flash_controller.js` to auto-dismiss flash alerts after 5 seconds | `[x]` |
| T-01-04-08 | Implement mobile-responsive sidebar: icon-only rail on < 1024px; hamburger overlay toggle | `[x]` |
| T-01-04-09 | Set up RSpec: run `rails generate rspec:install`; configure FactoryBot and Shoulda Matchers in `spec/rails_helper.rb` | `[x]` |
| T-01-04-10 | Write a smoke test verifying the root route renders within 200ms | `[x]` |
| T-01-04-11 | Verify `rails server` boots cleanly; confirm layout renders with no JS errors in browser console | `[x]` |
