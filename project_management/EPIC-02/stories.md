# EPIC-02 — Authentication & User Management

**Phase:** 2  
**Status:** � Completed  
**Goal:** Users can log in via Devise + JWT; admins can manage users and assign roles; Pundit authorisation enforced across all controllers; sidebar menu items conditioned on permissions.

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

### STORY-02-01 — Devise & JWT Authentication Setup
**Status:** 🟢 Completed  
**Description:** Install and configure Devise with the devise-jwt strategy. Users authenticate with username + password. Access tokens expire after 15 minutes; refresh tokens expire after 7 days. Inactive users are blocked.

| # | Task | Status |
|---|---|---|
| T-02-01-01 | Run `rails generate devise:install` and follow setup prompts | `[x]` |
| T-02-01-02 | Generate `User` model via Devise: `rails generate devise User` | `[x]` |
| T-02-01-03 | Add `username:string` (unique, not null) and `is_active:boolean` (default: true) columns to `users` migration | `[x]` |
| T-02-01-04 | Add `jti:string` (not null, unique) column to `users` for JTI Matcher strategy | `[x]` |
| T-02-01-05 | Configure `devise-jwt` in `config/initializers/devise.rb`: access token TTL 15 minutes, secret from credentials | `[x]` |
| T-02-01-06 | Configure JTI Matcher: include `Devise::JWT::RevocationStrategies::JTIMatcher` in `User` model | `[x]` |
| T-02-01-07 | Override `User#active_for_authentication?` to return `false` when `is_active == false` | `[x]` |
| T-02-01-08 | Create `Api::V1::Auth::SessionsController` overriding Devise sessions to return tokens in JSON body | `[x]` |
| T-02-01-09 | Implement refresh token endpoint `POST /api/v1/auth/refresh` | `[x]` |
| T-02-01-10 | Implement verify endpoint `POST /api/v1/auth/verify` | `[x]` |
| T-02-01-11 | Create Devise login view at `/login` styled with Railsblocks form components | `[x]` |
| T-02-01-12 | Write RSpec request specs: successful login, invalid credentials, inactive user blocked | `[x]` |

---

### STORY-02-02 — User Profile & Role Model
**Status:** 🟢 Completed  
**Description:** Every User has exactly one Profile. Profile links to a Role. Role stores an array of permission codenames in PostgreSQL. Seed one default admin user.

| # | Task | Status |
|---|---|---|
| T-02-02-01 | Generate `Role` model: `name:string`, `permissions:string[]` (PostgreSQL array), `group_id:bigint` | `[x]` |
| T-02-02-02 | Generate `Profile` model: `user_id:bigint` (unique FK), `role_id:bigint` (nullable FK), `first_name`, `last_name`, `address`, `remark`, `telephone` | `[x]` |
| T-02-02-03 | Add `has_one :profile` to `User`; `belongs_to :user` and `belongs_to :role, optional: true` to `Profile` | `[x]` |
| T-02-02-04 | Add `has_many :profiles` to `Role` | `[x]` |
| T-02-02-05 | Implement `Profile#full_name` helper returning `"#{first_name} #{last_name}".strip` | `[x]` |
| T-02-02-06 | Create `after_create` callback on `User` to auto-create a blank `Profile` | `[x]` |
| T-02-02-07 | Add `db/seeds/admin_user.rb` seeding username `admin`, email `admin@psk.com`, `is_active: true`, and an "Admin" Role with all permissions | `[x]` |
| T-02-02-08 | Write RSpec model specs for User, Profile, Role (validations, associations, callbacks) | `[x]` |

---

### STORY-02-03 — Pundit Authorisation Framework
**Status:** 🟢 Completed  
**Description:** Implement Pundit as the centralised authorisation layer. Every controller action must call `authorize`. Permissions are checked against `current_user.profile.role.permissions`. Two custom permissions (`can_view_cost`, `see_sale_graph`) handled explicitly.

| # | Task | Status |
|---|---|---|
| T-02-03-01 | Run `rails generate pundit:install` to create `ApplicationPolicy` | `[x]` |
| T-02-03-02 | Implement `ApplicationPolicy` base: map `index?`, `show?`, `create?`, `update?`, `destroy?` to `view_`, `view_`, `add_`, `change_`, `delete_` permission codenames | `[x]` |
| T-02-03-03 | Add `after_action :verify_authorized, except: :index` and `after_action :verify_policy_scoped, only: :index` to `ApplicationController` | `[x]` |
| T-02-03-04 | Create a `PermissionCheckable` concern with `has_permission?(codename)` helper method reading `current_user.profile.role.permissions` | `[x]` |
| T-02-03-05 | Create `ProductPolicy` with `can_view_cost?` predicate | `[x]` |
| T-02-03-06 | Create `OrderPolicy` with `report?` predicate enforcing `see_sale_graph` | `[x]` |
| T-02-03-07 | Implement `rescue_from Pundit::NotAuthorizedError` in `ApplicationController` returning `403 Forbidden` JSON | `[x]` |
| T-02-03-08 | Write RSpec policy specs for `ApplicationPolicy`, `ProductPolicy`, `OrderPolicy` | `[x]` |

---

### STORY-02-04 — User & Role Management UI
**Status:** 🟢 Completed  
**Description:** Admin can list, create, edit, deactivate/activate users and force-reset passwords. Full CRUD for roles. Permissions list is read-only. Sidebar menu items hidden based on user permissions.

| # | Task | Status |
|---|---|---|
| T-02-04-01 | Implement `UsersController` with `index`, `new`, `create`, `edit`, `update`, `destroy`, `activate`, `deactivate` actions | `[x]` |
| T-02-04-02 | Implement `Users::ForcePasswordController` with `update` action (validates `password1 == password2`) | `[x]` |
| T-02-04-03 | Implement `ProfilesController` with `show` and `update` for the authenticated user's own profile | `[x]` |
| T-02-04-04 | Build User list view: Railsblocks `rb_table` with search (Ransack on username, name, email, telephone) | `[x]` |
| T-02-04-05 | Build User form view (new/edit): Railsblocks `rb_form` with role dropdown | `[x]` |
| T-02-04-06 | Implement `RolesController` (full CRUD); list view with permissions multi-select | `[x]` |
| T-02-04-07 | Implement `PermissionsController` (`index` only) returning all seeded permission codenames | `[x]` |
| T-02-04-08 | Add permission guard to `_sidebar.html.erb`: each menu item only renders if `policy(:model).index?` passes | `[x]` |
| T-02-04-09 | Add corresponding API routes for all user/profile/role actions under `/api/v1/` | `[x]` |
| T-02-04-10 | Write RSpec request specs for user CRUD, activate/deactivate, force password, role CRUD | `[x]` |
