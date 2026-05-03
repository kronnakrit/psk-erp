# TC-01 — Authentication & User Management
**Module:** Authentication, Users, Roles, Permissions  
**Based on:** EPIC-02, EPIC-23

---

## Legend
| Symbol | Meaning |
|---|---|
| ✅ | Pass |
| ❌ | Fail |
| ⏳ | Not Executed |

---

## TC-01-01 — Username/Password Login

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-01-01-01 | Login with valid credentials | Active user exists with username `admin` | 1. Navigate to `/login`<br>2. Enter valid username + password<br>3. Click "Sign in" | Redirected to dashboard (`/`); flash message absent | ⏳ |
| TC-01-01-02 | Login with wrong password | Active user exists | 1. Navigate to `/login`<br>2. Enter correct username + wrong password<br>3. Click "Sign in" | Stays on `/login`; error message "Invalid Username or password" shown | ⏳ |
| TC-01-01-03 | Login with non-existent username | — | 1. Navigate to `/login`<br>2. Enter unknown username + any password<br>3. Click "Sign in" | Stays on `/login`; generic invalid credentials error shown | ⏳ |
| TC-01-01-04 | Login as inactive user | User has `is_active: false` | 1. Navigate to `/login`<br>2. Enter credentials of inactive user<br>3. Click "Sign in" | Login rejected; error message shown; no session created | ⏳ |
| TC-01-01-05 | Access protected page without session | No session cookie | 1. Navigate to `/orders` directly | Redirected to `/login` with 302; Thai flash "คุณต้องเข้าสู่ระบบ..." shown | ⏳ |
| TC-01-01-06 | Remember Me checkbox | Active user | 1. Login with "Remember me" checked | Session persists beyond browser close (persistent cookie set) | ⏳ |
| TC-01-01-07 | Logout | Authenticated user | 1. Click logout button / link | Session destroyed; redirected to `/login` | ⏳ |

---

## TC-01-02 — User Management (Admin)

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-01-02-01 | Create new user | Admin logged in | 1. Navigate to `/users/new`<br>2. Fill in username, email, password<br>3. Assign role<br>4. Submit | User created; redirected to users list; new user appears | ⏳ |
| TC-01-02-02 | Create user with duplicate username | User with same username exists | 1. Try to create user with existing username | Form re-renders with validation error on username | ⏳ |
| TC-01-02-03 | Create user with duplicate email | User with same email exists | 1. Try to create user with existing email | Form re-renders with validation error on email | ⏳ |
| TC-01-02-04 | Edit user details | Admin logged in; user exists | 1. Navigate to `/users/:id/edit`<br>2. Change first/last name<br>3. Submit | User updated; success flash; changes reflected in profile | ⏳ |
| TC-01-02-05 | Deactivate user | Admin; active user | 1. Click "Deactivate" on user row | `is_active` set to `false`; user cannot log in | ⏳ |
| TC-01-02-06 | Reactivate user | Admin; inactive user | 1. Click "Activate" on user row | `is_active` set to `true`; user can log in again | ⏳ |
| TC-01-02-07 | Admin force-reset password | Admin; any user | 1. Navigate to user edit<br>2. Enter new password fields<br>3. Submit | Password updated; old password no longer works | ⏳ |
| TC-01-02-08 | Non-admin cannot access user management | User without `manage_users` permission | 1. Navigate to `/users` | 403 Forbidden | ⏳ |

---

## TC-01-03 — Role & Permission Management

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-01-03-01 | Create role with permissions | Admin logged in | 1. Navigate to `/roles/new`<br>2. Enter role name<br>3. Check permissions (e.g. `view_orders`, `create_orders`)<br>4. Submit | Role created with selected permissions array | ⏳ |
| TC-01-03-02 | Edit role permissions | Admin; role exists | 1. Navigate to `/roles/:id/edit`<br>2. Add/remove permissions<br>3. Submit | Role updated; users with that role gain/lose access immediately | ⏳ |
| TC-01-03-03 | Assign role to user | Admin; user and role exist | 1. Edit user profile<br>2. Select role from dropdown<br>3. Submit | Profile `role_id` updated | ⏳ |
| TC-01-03-04 | Sidebar hides menu items per permissions | User with limited permissions | 1. Log in as limited user<br>2. Check sidebar | Only permitted menu items visible (e.g. no "สต็อก" if `view_product_stocks` absent) | ⏳ |
| TC-01-03-05 | `can_view_cost` permission gates cost field | User without `can_view_cost` | 1. View product detail | `cost` field not rendered in HTML | ⏳ |
| TC-01-03-06 | `see_sale_graph` permission gates dashboard graph | User without `see_sale_graph` | 1. View dashboard | Sales graph section not rendered | ⏳ |
| TC-01-03-07 | Delete role with assigned users | Admin; role has users | 1. Attempt to delete role | Delete rejected with error message; role preserved | ⏳ |

---

## TC-01-04 — JWT API Authentication

| ID | Test Case | Preconditions | Steps | Expected Result | Status |
|---|---|---|---|---|---|
| TC-01-04-01 | Obtain JWT access token | Valid user credentials | POST `/api/v1/auth/sign_in` with `{ username, password }` | Response 200; `access_token` and `refresh_token` in body | ⏳ |
| TC-01-04-02 | Access API with valid token | Valid token obtained | GET `/api/v1/catalogs/products` with `Authorization: Bearer <token>` | Response 200; product list returned | ⏳ |
| TC-01-04-03 | Access API with expired token | Token older than 15 min | GET API endpoint with expired token | Response 401 Unauthorized | ⏳ |
| TC-01-04-04 | Access API without token | No Authorization header | GET any `/api/v1/` endpoint | Response 401 Unauthorized | ⏳ |
| TC-01-04-05 | Refresh token flow | Valid refresh token | POST `/api/v1/auth/refresh` with refresh token | New access token issued; response 200 | ⏳ |
| TC-01-04-06 | Sign out invalidates tokens | Authenticated session | POST `/api/v1/auth/sign_out` | Response 200; old token returns 401 on next request | ⏳ |
