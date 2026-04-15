# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 Orders Report endpoints", type: :request do
  let(:customer) { create(:customer) }

  def jwt_headers_for(user)
    post "/api/v1/auth/sign_in",
         params: { user: { email: user.email, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  context "with see_sale_graph permission" do
    let(:role) { create(:role, permissions: %w[view_orders see_sale_graph]) }
    let(:user) { create(:user) }
    let!(:order) do
      create(:order, :completed, customer: customer, grand_total: 1500, running_date: Date.new(2026, 1, 15))
    end

    let(:headers) do
      user.profile.update!(role: role)
      jwt_headers_for(user)
    end

    describe "POST /api/v1/orders/customer_report" do
      it "returns xlsx with 200" do
        post customer_report_api_v1_orders_path,
             params: { start_date: "2026-01-01", end_date: "2026-01-31" },
             headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("spreadsheetml")
        expect(response.headers["Content-Disposition"]).to include("customer_report")
      end
    end

    describe "POST /api/v1/orders/sales_report" do
      it "returns xlsx with 200" do
        post sales_report_api_v1_orders_path,
             params: { start_date: "2026-01-01", end_date: "2026-01-31" },
             headers: headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("spreadsheetml")
        expect(response.headers["Content-Disposition"]).to include("sales_report")
      end
    end
  end

  context "without see_sale_graph permission" do
    let(:role) { create(:role, permissions: %w[view_orders]) }
    let(:user) { create(:user) }

    let(:headers) do
      user.profile.update!(role: role)
      jwt_headers_for(user)
    end

    describe "POST /api/v1/orders/customer_report" do
      it "returns 403" do
        post customer_report_api_v1_orders_path,
             params: { start_date: "2026-01-01", end_date: "2026-01-31" },
             headers: headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe "POST /api/v1/orders/sales_report" do
      it "returns 403" do
        post sales_report_api_v1_orders_path,
             params: { start_date: "2026-01-01", end_date: "2026-01-31" },
             headers: headers, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
