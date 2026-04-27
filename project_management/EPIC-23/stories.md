# EPIC-23 — Username-Based Authentication

**Phase:** 23
**Status:** 🔴 Not Started
**Goal:** Users authenticate via their unique username instead of email address on both the web login form and the JWT API endpoint, and the admin seed file no longer contains a hardcoded fallback password.

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

## Stories

### STORY-23-01 — Devise Core: Authenticate by Username

**Status:** 🔴 Not Started
**Description:** Configure Devise to use `username` as the authentication key and add a case-insensitive `find_for_database_authentication` override on the `User` model so both the web login and the JWT API login resolve users by username.

**User Perspective:**
As a user, I want to log in with my username and password, so that I do not need to remember my email address.

**Acceptance Criteria:**

| #     | Given                                              | When                                                                             | Then                                                                                       |
| ----- | -------------------------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| AC-01 | A user with `username: "alice"` exists and is active | `POST /login` is submitted with `user[username]: "alice"` and correct password  | Response redirects `302` to root path and the user session is established                  |
| AC-02 | A user with `username: "ALICE"` exists and is active | `POST /login` is submitted with `user[username]: "alice"` (lowercase)            | Response redirects `302` to root path (case-insensitive lookup succeeds)                   |
| AC-03 | No user with `username: "ghost"` exists             | `POST /login` is submitted with `user[username]: "ghost"` and any password       | Response re-renders the login form with HTTP `200` and no session is created               |
| AC-04 | A user with `username: "bob"` exists and is active  | `POST /login` is submitted with `user[username]: "bob"` and wrong password       | Response re-renders the login form with HTTP `200` and a Devise failure flash is present   |
| AC-05 | A user with `username: "carol"` exists but `is_active: false` | `POST /login` is submitted with correct username and password        | Response re-renders with HTTP `200`; flash includes the inactive account message           |
| AC-06 | Any user                                           | `POST /login` is submitted with `user[email]: "alice@example.com"` (email param) | Response re-renders with HTTP `200`; no session is created (email is not the auth key)     |

**Edge Cases:**

- Username with leading/trailing whitespace is stripped before lookup.
- `username` with mixed case (e.g. `"Alice"`) matches `"alice"` in the database.
- Submitting an empty `username` re-renders the form with a blank field error.

| #          | Task                                                                                                                                     | Status |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| T-23-01-01 | Update `config/initializers/devise.rb`: uncomment and set `config.authentication_keys = [:username]`                                     | `[ ]`  |
| T-23-01-02 | Update `config/initializers/devise.rb`: change `config.case_insensitive_keys` from `[:email]` to `[:username]`                          | `[ ]`  |
| T-23-01-03 | Update `config/initializers/devise.rb`: change `config.strip_whitespace_keys` from `[:email]` to `[:username]`                          | `[ ]`  |
| T-23-01-04 | Add `User.find_for_database_authentication(conditions)` class method in `app/models/user.rb` that queries `WHERE lower(username) = lower(?)` and falls back to Devise default | `[ ]`  |
| T-23-01-05 | Write RSpec model spec `spec/models/user_authentication_spec.rb`: case-insensitive match returns user, not-found returns `nil`, inactive user is found but fails `active_for_authentication?` | `[ ]`  |

---

### STORY-23-02 — Login View: Replace Email Field with Username Field

**Status:** 🔴 Not Started
**Description:** Update the Devise sessions login view (`app/views/devise/sessions/new.html.erb`) to replace the email input with a username text input so the form submits the correct `user[username]` parameter.

**User Perspective:**
As a user, I want to see a "Username" input on the login page, so that I know to enter my username to sign in.

**Acceptance Criteria:**

| #     | Given                              | When                              | Then                                                                                         |
| ----- | ---------------------------------- | --------------------------------- | -------------------------------------------------------------------------------------------- |
| AC-01 | An unauthenticated visitor         | `GET /login` is requested         | Response is `200` and the HTML body contains a `<input>` with `name="user[username]"`        |
| AC-02 | An unauthenticated visitor         | `GET /login` is requested         | Response body does **not** contain `name="user[email]"` or `type="email"` input              |
| AC-03 | An unauthenticated visitor         | `GET /login` is requested         | The label text "Username" is present in the response body                                    |
| AC-04 | An unauthenticated visitor         | `GET /login` is requested         | The placeholder text "your_username" (or equivalent) is present on the username input        |
| AC-05 | A user submits the form with valid username + password | `POST /login` is submitted | Response redirects `302` to root (form params are accepted)                            |

**Edge Cases:**

- The password field label and behaviour remain unchanged.
- The "Remember me" checkbox remains unchanged.
- The `autocomplete` attribute on the username field must be set to `"username"` (not `"email"`).

| #          | Task                                                                                                                                 | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-23-02-01 | Update `app/views/devise/sessions/new.html.erb`: replace `f.email_field :email` with `f.text_field :username`                        | `[ ]`  |
| T-23-02-02 | Update label text from `"Email"` to `"Username"` and placeholder from `"you@example.com"` to `"your_username"` in the same view     | `[ ]`  |
| T-23-02-03 | Update `autocomplete` attribute from `"email"` to `"username"` on the username field in `app/views/devise/sessions/new.html.erb`     | `[ ]`  |
| T-23-02-04 | Write RSpec request spec `spec/requests/sessions_spec.rb`: `GET /login` renders username field; `POST /login` with correct credentials redirects `302`; wrong password re-renders `200`; inactive user re-renders `200` | `[ ]`  |

---

### STORY-23-03 — Harden Admin Seed File: Remove Hardcoded Fallback Password

**Status:** 🔴 Not Started
**Description:** The admin seed file currently has `ENV.fetch("ADMIN_DEFAULT_PASSWORD", "Admin@12345!")` — a hardcoded fallback password that would silently be used in production if the environment variable is not set. This story removes the fallback so deployment fails loudly if the variable is missing, and registers the secret in Kamal's deploy config.

**User Perspective:**
As a system administrator, I want the admin seed to fail with a clear error if `ADMIN_DEFAULT_PASSWORD` is not set, so that a predictable default password is never deployed to production.

**Acceptance Criteria:**

| #     | Given                                               | When                                          | Then                                                                                                  |
| ----- | --------------------------------------------------- | --------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| AC-01 | `ADMIN_DEFAULT_PASSWORD` is set in the environment  | `rails db:seed` is run                        | Admin user is seeded with the provided password; no error raised                                      |
| AC-02 | `ADMIN_DEFAULT_PASSWORD` is **not** set             | `rails db:seed` is run in production          | A `KeyError` (from `ENV.fetch`) is raised and seed aborts with a descriptive message                  |
| AC-03 | `ADMIN_DEFAULT_PASSWORD` is not set                 | `rails db:seed` is run in development or test | The seed uses a safe development default (e.g. `"Admin@12345!"`) via environment-aware branching      |
| AC-04 | Kamal deploys to production                         | `bin/kamal deploy` runs                       | `ADMIN_DEFAULT_PASSWORD` is sourced from `.kamal/secrets` and injected into the container environment |

**Edge Cases:**

- `.kamal/secrets` must never contain the actual password value committed to git (it is gitignored).
- The hardcoded string `"Admin@12345!"` must not appear in any file tracked by git after this story is complete.

| #          | Task                                                                                                                                                         | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-23-03-01 | Update `db/seeds/admin_user.rb`: replace `ENV.fetch("ADMIN_DEFAULT_PASSWORD", "Admin@12345!")` with a production-safe fetch that raises in production and falls back to a dev default otherwise | `[ ]`  |
| T-23-03-02 | Add `ADMIN_DEFAULT_PASSWORD` to `env.secret` in `config/deploy.yml`                                                                                          | `[ ]`  |
| T-23-03-03 | Add `ADMIN_DEFAULT_PASSWORD=...` placeholder comment to `.kamal/secrets` documentation block (not the real value)                                            | `[ ]`  |
| T-23-03-04 | Verify `git grep "Admin@12345"` returns no results in tracked files                                                                                          | `[ ]`  |

---

### STORY-23-04 — API JWT Login: Verify Username Parameter

**Status:** 🔴 Not Started
**Description:** The JWT API login endpoint (`POST /api/v1/auth/sign_in`) inherits from `Devise::SessionsController`. After the model-level `find_for_database_authentication` override in STORY-23-01, this endpoint automatically supports `user[username]` params — but existing rswag integration specs and request specs that post `user[email]` must be updated to match the new authentication key.

**User Perspective:**
As a mobile/API client developer, I want to authenticate via `POST /api/v1/auth/sign_in` by sending `user[username]` and `user[password]`, so that the API contract matches the web login behaviour.

**Acceptance Criteria:**

| #     | Given                                                   | When                                                                                         | Then                                                                                           |
| ----- | ------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| AC-01 | A user with `username: "alice"` exists and is active    | `POST /api/v1/auth/sign_in` is called with `{ user: { username: "alice", password: "..." } }` | Response is `200 OK` with a JSON body containing `user.id`, `user.email`, `user.username` and `Authorization` header with JWT |
| AC-02 | No user with `username: "ghost"` exists                 | `POST /api/v1/auth/sign_in` is called with `{ user: { username: "ghost", password: "..." } }` | Response is `401 Unauthorized` with `{ "error": "Invalid credentials" }`                      |
| AC-03 | A user exists but `is_active: false`                    | `POST /api/v1/auth/sign_in` is called with correct username + password                       | Response is `401 Unauthorized`                                                                 |
| AC-04 | An API client posts `user[email]` instead of `user[username]` | `POST /api/v1/auth/sign_in` is called with `{ user: { email: "alice@example.com", password: "..." } }` | Response is `401 Unauthorized` (email is not the auth key)                         |
| AC-05 | `DELETE /api/v1/auth/sign_out` is called with a valid `Authorization` header | Logout request is made                                                        | Response is `200 OK` with `{ "message": "Logged out successfully" }`                           |

**Edge Cases:**

- The `Authorization: Bearer <token>` header in the response must be present on AC-01.
- An expired or revoked JWT on sign-out must return `401` (existing JTIMatcher behaviour, no change).

| #          | Task                                                                                                                                       | Status |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------ |
| T-23-04-01 | Write RSpec request spec `spec/requests/api/v1/auth/sessions_spec.rb`: `POST /api/v1/auth/sign_in` with valid username+password returns `200` with JWT; invalid username returns `401`; inactive user returns `401`; email param returns `401` | `[ ]`  |
| T-23-04-02 | Update `spec/integration/users_profiles_spec.rb` (rswag): change any `user[email]` sign-in request body param to `user[username]`         | `[ ]`  |
| T-23-04-03 | Regenerate Swagger docs via `bundle exec rails rswag:specs:swaggerize` and verify `POST /api/v1/auth/sign_in` request schema shows `username` not `email` | `[ ]`  |
