# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /orders/export_excel", type: :request do
  let(:role_with_permission)    { create(:role, permissions: %w[view_orders view_all_orders export_orders_excel]) }
  let(:role_without_permission) { create(:role, permissions: %w[view_orders view_all_orders]) }
  let(:user)                    { create(:user) }
  let(:customer)                { create(:customer) }
  let(:order)                   { create(:order, customer: customer) }

  before { create(:order_line, order: order, quantity: 2, unit_price: 500.00, discount_price: 0) }

  # (a) Authenticated + authorized user receives HTTP 200 xlsx download
  context "when authenticated with export_orders_excel permission" do
    before do
      user.profile.update!(role: role_with_permission)
      sign_in user
    end

    it "returns HTTP 200 with xlsx content type" do
      post export_excel_orders_path, params: { "ids[]" => [order.id] }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    end

    it "sets the Content-Disposition to attachment" do
      post export_excel_orders_path, params: { "ids[]" => [order.id] }
      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "includes a dated filename in the Content-Disposition" do
      post export_excel_orders_path, params: { "ids[]" => [order.id] }
      expect(response.headers["Content-Disposition"]).to match(/orders_export_\d{8}\.xlsx/)
    end
  end

  # (b) User without export_orders_excel permission → redirect (HTML user_not_authorized handler)
  context "when authenticated without export_orders_excel permission" do
    before do
      user.profile.update!(role: role_without_permission)
      sign_in user
    end

    it "redirects (user not authorized)" do
      post export_excel_orders_path, params: { "ids[]" => [order.id] }
      expect(response).to have_http_status(:found)
    end
  end

  # (c) Unauthenticated request → 302 redirect to login
  context "when unauthenticated" do
    it "redirects to the login page" do
      post export_excel_orders_path, params: { "ids[]" => [order.id] }
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # (d) Authorized user with empty ids[] → redirect with flash alert
  context "when authenticated with permission but no ids[] provided" do
    before do
      user.profile.update!(role: role_with_permission)
      sign_in user
    end

    it "redirects to orders path" do
      post export_excel_orders_path, params: {}
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(orders_path)
    end

    it "sets a flash alert" do
      post export_excel_orders_path, params: {}
      follow_redirect!
      expect(response.body).to include("No orders selected.")
    end
  end
end
