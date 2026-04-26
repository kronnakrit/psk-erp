---
description: "Use when writing Ruby on Rails code: models, controllers, views, migrations, jobs, specs, services, or API endpoints. Covers Active Record patterns, Hotwire/Turbo, Pundit authorization, Sidekiq jobs, RSpec testing, and PSK ERP project conventions."
applyTo: "**/*.rb,**/*.erb,**/routes.rb,**/Gemfile"
---

# Rails Standards — PSK ERP

## Stack

| Layer         | Technology                                          |
| ------------- | --------------------------------------------------- |
| Framework     | Rails 8, Ruby 3.3+                                  |
| UI            | Railsblocks (Tailwind) + Hotwire (Turbo + Stimulus) |
| Database      | PostgreSQL 16+                                      |
| Auth          | Devise + devise-jwt (JTIMatcher)                    |
| Authorization | Pundit                                              |
| Background    | Sidekiq + Redis                                     |
| Pagination    | Pagy                                                |
| Search        | Ransack                                             |
| Testing       | RSpec + FactoryBot + Shoulda Matchers               |

---

## Architecture

- **Thin controllers** — keep actions to find/build/respond. Extract business logic into service objects.
- **Service objects** for complex logic (e.g. `GrandTotalCalculator`, `OrderNumberGenerator`, `OrderExcelService`). One public method `#call`.
- **Concerns** for shared model behaviour (`SoftDeletable`, `ImageCompressible`).
- Use `ActiveSupport::CurrentAttributes` (`Current.user`) to pass request context to models/jobs.

---

## Active Record

### Associations & Queries

```ruby
# Always eager-load associations to prevent N+1
@orders = Order.includes(:customer, :order_lines, :logistic_company).page(params[:page])

# Use joins when filtering on association; includes when rendering it
Order.joins(:customer).where(customers: { country_id: "TH" })

# Named scopes for reusable query logic
scope :active, -> { where(deleted_at: nil) }
scope :by_status, ->(s) { where(status: s) }
scope :search, ->(q) { where("name ILIKE ?", "%#{sanitize_sql_like(q)}%") }

# Batch processing for large datasets
User.find_each(batch_size: 1000) { |u| u.do_something }
```

### Validations

- Validate all inputs at the model layer; never trust params directly.
- Use `uniqueness`, `presence`, `numericality`, `length` validators explicitly.
- Add custom validators as `validate :method_name` for domain rules.

### Callbacks

```ruby
before_validation :auto_generate_sku          # generate identifiers
before_save       :auto_set_initial_name       # derived fields
after_commit      :recalculate_grand_total     # trigger side-effects after commit
before_destroy    :check_order_lines           # guard protected relations
```

### Soft Delete

Use the `SoftDeletable` concern:

```ruby
# Default scope excludes deleted records
default_scope -> { where(deleted_at: nil) }

record.soft_delete!   # sets deleted_at
record.restore!       # clears deleted_at
```

### Migrations

- Always write reversible migrations (`change` or explicit `up`/`down`).
- Index every FK column and every column used in `WHERE` / `ORDER BY`.
- Use `on_delete: :nullify` for FK where orphan records are acceptable (e.g. `orders.logistic_company_id`).
- Use `on_delete: :restrict` where deletion must be blocked (e.g. `order_lines.product_id`).

```ruby
add_reference :orders, :logistic_company, foreign_key: { on_delete: :nullify }, null: true
add_index :product_stocks, %i[branch_id product_id], unique: true
```

---

## Controllers

### Structure

```ruby
class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: %i[show edit update destroy]
  after_action  :verify_authorized               # Pundit guard

  def index
    @orders = policy_scope(Order).includes(:customer).page(params[:page])
    authorize Order
  end

  def create
    @order = Order.new(order_params)
    authorize @order
    if @order.save
      redirect_to @order, notice: "Order created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find(params[:id])
    authorize @order
  end

  def order_params
    params.require(:order).permit(:customer_id, :logistic_company_id, :remark, ...)
  end
end
```

- **Always** call `authorize @resource` (Pundit) in every action.
- **Always** use `policy_scope` for collection queries.
- Render with `status: :unprocessable_entity` on failed saves (required for Turbo).
- Return `head :no_content` on successful DELETE.

---

## Pundit Policies

```ruby
class OrderPolicy < ApplicationPolicy
  def index?  = user_has?("view_orders")
  def create? = user_has?("create_orders")
  def update? = user_has?("edit_orders") || record.created_by == user
  def report? = user_has?("see_sale_graph")

  private

  def user_has?(permission)
    user.profile&.role&.permissions&.include?(permission)
  end
end
```

- The `cost` field on products is excluded from serializers unless `user_has?("can_view_cost")`.
- `ApplicationController` must have `after_action :verify_authorized` and `after_action :verify_policy_scoped, only: :index`.

---

## API Design

### Conventions

- All API routes under `/api/v1/`.
- Authenticate via `Authorization: Bearer <jwt_token>`.
- JWT access tokens expire in **15 minutes**; refresh tokens in **7 days**.
- Reject inactive users (`is_active = false`) with `403 Forbidden`.

### Pagination Envelope

```json
{
  "count": 150,
  "next": "/api/v1/orders?page=3",
  "previous": "/api/v1/orders?page=1",
  "results": []
}
```

### HTTP Status Codes

| Scenario                       | Code |
| ------------------------------ | ---- |
| Validation failure             | 400  |
| Unauthorized                   | 401  |
| Forbidden                      | 403  |
| Not found                      | 404  |
| Protected association conflict | 409  |

```ruby
rescue_from ActiveRecord::RecordNotFound  { render json: { error: "Not Found" },  status: :not_found }
rescue_from Pundit::NotAuthorizedError    { render json: { error: "Forbidden" },   status: :forbidden }
```

---

## Hotwire / Turbo

### Turbo Frames

```erb
<%# Wrap content in a named frame for scoped updates %>
<%= turbo_frame_tag dom_id(@order) do %>
  <%= render "order_detail", order: @order %>
<% end %>

<%# Lazy-load expensive content %>
<%= turbo_frame_tag "dashboard_stats", src: dashboard_stats_path, loading: :lazy %>
```

### Turbo Streams

```ruby
# Controller: respond with both formats
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to orders_path }
end
```

```erb
<%# create.turbo_stream.erb %>
<%= turbo_stream.prepend "orders", partial: "orders/order", locals: { order: @order } %>
<%= turbo_stream.update  "orders_count", @orders_count %>
```

### Stimulus

```javascript
// app/javascript/controllers/order_lines_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["lines", "total"];

  addLine() {
    /* ... */
  }
  removeLine(event) {
    /* ... */
  }
}
```

- Use Stimulus for **DOM interactions only** — no business logic in JS.
- Persist UI state (sidebar open/close) in `localStorage` from Stimulus.

---

## Background Jobs (Sidekiq)

```ruby
class BulkProductImportJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(upload_id)
    upload = Upload.find(upload_id)
    # ... parse with roo, upsert records
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("BulkProductImportJob: upload #{upload_id} not found — #{e.message}")
  end
end
```

- **Always pass IDs** to jobs, never ActiveRecord objects.
- Use queues: `critical` → `default` → `low` by priority.
- Slow operations (Excel generation, image compression, bulk imports) **must** use Sidekiq.
- Never run slow operations synchronously in the request cycle.

---

## RSpec Testing

### Target ≥ 95% coverage (SimpleCov).

### Model Specs

```ruby
RSpec.describe Order, type: :model do
  describe "associations" do
    it { should belong_to(:customer) }
    it { should have_many(:order_lines).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
  end

  describe "grand total calculation" do
    it "calculates correctly with VAT" do
      order = create(:order, :with_vat)
      expect(order.grand_total).to eq(expected_total)
    end
  end
end
```

### Request Specs

```ruby
RSpec.describe "GET /api/v1/orders", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }   # helper that sets Bearer token

  it "returns paginated orders" do
    create_list(:order, 3, created_by: user)
    get api_v1_orders_path, headers: headers
    expect(response).to have_http_status(:ok)
    expect(json["count"]).to eq(3)
  end

  it "requires authentication" do
    get api_v1_orders_path
    expect(response).to have_http_status(:unauthorized)
  end
end
```

### Factory Conventions

```ruby
FactoryBot.define do
  factory :order do
    association :customer
    association :created_by, factory: :user
    status { "Dr" }
    running_date { Date.today }

    trait :paid      { status { "Pd" } }
    trait :completed { status { "Cp" } }
    trait :with_vat  { has_vat { true }; is_included_vat { false } }
  end
end
```

---

## PSK ERP Domain Conventions

### Status Codes (string enums)

| Domain            | Values                                                                   |
| ----------------- | ------------------------------------------------------------------------ |
| Order status      | `Dr` (Draft), `Pd` (Paid), `Cp` (Completed), `Cc` (Cancelled)            |
| Logistic status   | `WTS` (Wait to Send), `ST` (Sent), `HP` (Handpick), `TWH` (To Warehouse) |
| Product type      | `Sa` (Standalone), `Pr` (Parent), `Ch` (Child)                           |
| Order line unit   | `Dz` (Dozen), `Pc` (Piece), `Pa` (Pack), `Se` (Set), `Ct` (Carton)       |
| Stock transaction | `IB` (Inbound), `OB` (Outbound)                                          |

### Order Number Generation

Use `OrderNumberGenerator#call(running_date)` — never inline the collision-safe loop.

### Grand Total

Use `GrandTotalCalculator#call(order)` — never calculate inline in the model or controller.

### Export Security

Order export endpoints must require:

- A valid Bearer token, **OR**
- A signed URL token via `Rails.application.message_verifier(:export)` valid for **10 minutes**.

Never expose an unauthenticated export endpoint.

### Logistic Company FK

`orders.logistic_company_id` uses `on_delete: :nullify` — deleting a logistic company must **not** cascade-delete its orders.

---

## Code Quality

- Run `bundle exec rubocop` before committing; fix all offences (no inline `# rubocop:disable` unless justified).
- `bundle exec rspec` must pass with zero failures.
- No raw SQL without `sanitize_sql` or parameterized bindings.
- No N+1 queries — audit with `includes`/`eager_load` on every collection that renders associations.
