# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 Orders report_order", type: :request do
  let(:customer) { create(:customer) }

  def jwt_headers_for(user)
    post "/api/v1/auth/sign_in",
         params: { user: { username: user.username, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  context "with see_sale_graph permission" do
    let(:role) { create(:role, permissions: %w[view_orders see_sale_graph]) }
    let(:user) { create(:user) }
    let!(:order) do
      create(:order, :completed, customer: customer, grand_total: 1000, running_date: Date.new(2026, 1, 15))
    end

    let(:headers) do
      user.profile.update!(role: role)
      jwt_headers_for(user)
    end

    it "returns 200 with correct JSON keys" do
      post report_order_api_v1_orders_path,
           params: { start_date: "2026-01-01", end_date: "2026-01-31" },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.keys).to match_array(%w[draft paid completed cancelled])
    end

    it "includes grand_total__sum keys in each array entry" do
      post report_order_api_v1_orders_path,
           params: { start_date: "2026-01-01", end_date: "2026-01-31" },
           headers: headers, as: :json
      json = response.parsed_body
      entry = json["completed"].first
      expect(entry.keys).to include("year", "month", "grand_total__sum")
      expect(entry["grand_total__sum"]).to eq(1000.0)
    end
  end

  context "without see_sale_graph permission" do
    let(:role) { create(:role, permissions: %w[view_orders]) }
    let(:user) { create(:user) }

    let(:headers) do
      user.profile.update!(role: role)
      jwt_headers_for(user)
    end

    it "returns 403" do
      post report_order_api_v1_orders_path,
           params: { start_date: "2026-01-01", end_date: "2026-01-31" },
           headers: headers, as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
