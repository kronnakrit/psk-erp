# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 Orders", type: :request do
  let(:customer) { create(:customer) }

  def jwt_headers_for(user)
    post "/api/v1/auth/sign_in",
         params: { user: { username: user.username, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  let(:role) { create(:role, permissions: %w[view_orders change_orders bulk_update_order_status]) }
  let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
  let(:headers) { jwt_headers_for(user) }

  describe "GET /api/v1/orders" do
    let!(:order) { create(:order, customer: customer, created_by: user) }

    it "returns 200 with orders list" do
      get api_v1_orders_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["orders"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/orders/draft" do
    let!(:order) { create(:order, customer: customer, created_by: user) }

    it "returns draft orders" do
      get draft_api_v1_orders_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/orders/paid" do
    let!(:order) { create(:order, :paid, customer: customer, created_by: user) }

    it "returns paid orders" do
      get paid_api_v1_orders_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/orders/completed" do
    let!(:order) { create(:order, :completed, customer: customer, created_by: user) }

    it "returns completed orders" do
      get completed_api_v1_orders_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/orders/cancelled" do
    let!(:order) { create(:order, :cancelled, customer: customer, created_by: user) }

    it "returns cancelled orders" do
      get cancelled_api_v1_orders_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/orders/dashboard" do
    it "returns dashboard counts" do
      get dashboard_api_v1_orders_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to include("today_count", "draft_count", "monthly_revenue")
    end
  end

  describe "GET /api/v1/orders/:id" do
    let!(:order) { create(:order, customer: customer, created_by: user) }

    it "returns order details" do
      get api_v1_order_path(order), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(order.id)
    end
  end

  describe "POST /api/v1/orders" do
    it "creates an order" do
      post api_v1_orders_path,
           params: { order: { customer_id: customer.id, status: "Dr", running_date: Date.today.iso8601 } },
           headers: headers, as: :json
      expect(response).to have_http_status(:created)
    end

    it "returns 422 on invalid params" do
      post api_v1_orders_path,
           params: { order: { customer_id: nil } },
           headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/orders/:id" do
    let!(:order) { create(:order, customer: customer, created_by: user) }

    it "updates an order" do
      patch api_v1_order_path(order),
            params: { order: { remark: "Updated" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/orders/:id" do
    let!(:order) { create(:order, customer: customer, created_by: user) }
    let(:admin_role) { create(:role, :admin) }
    let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
    let(:admin_headers) { jwt_headers_for(admin_user) }

    it "destroys the order" do
      delete api_v1_order_path(order), headers: admin_headers, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "POST /api/v1/orders/advance_search" do
    let!(:order) { create(:order, customer: customer, created_by: user) }

    it "returns filtered results" do
      post advance_search_api_v1_orders_path,
           params: { q: {} },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/orders/filters" do
    let!(:order) { create(:order, customer: customer, created_by: user) }

    it "filters by status" do
      post filters_api_v1_orders_path,
           params: { status: "Dr" },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "filters by date range" do
      post filters_api_v1_orders_path,
           params: { from: "2020-01-01", to: "2030-12-31" },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/orders/bulk_update_status" do
    let!(:order1) { create(:order, customer: customer, created_by: user) }
    let!(:order2) { create(:order, customer: customer, created_by: user) }

    it "bulk updates status by ids" do
      post bulk_update_status_api_v1_orders_path,
           params: { ids: [order1.id, order2.id], status: "Pd" },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end

    it "returns error when both ids and is_selected_all provided" do
      post bulk_update_status_api_v1_orders_path,
           params: { ids: [order1.id], is_selected_all: true, status: "Pd" },
           headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 422 on invalid status" do
      post bulk_update_status_api_v1_orders_path,
           params: { ids: [order1.id], status: "INVALID" },
           headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "bulk updates all with is_selected_all" do
      post bulk_update_status_api_v1_orders_path,
           params: { is_selected_all: true, status: "Pd" },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
