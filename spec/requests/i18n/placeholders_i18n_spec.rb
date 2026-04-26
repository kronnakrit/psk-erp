# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Search input placeholders i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders view_all_orders
      view_products
      view_customers
      view_purchase_orders
      view_invoices
      view_users
    ])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get orders_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai order search placeholder" do
      expect(response.body).to include("ค้นหาเลขที่ออเดอร์")
    end
  end

  describe "TH user visiting GET /products" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get products_path
    end

    it "renders Thai product search placeholder" do
      expect(response.body).to include("ค้นหาโดยชื่อ, SKU")
    end
  end

  describe "EN user visiting GET /orders" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get orders_path
    end

    it "renders English order search placeholder" do
      expect(response.body).to include("Search order number")
    end
  end
end
