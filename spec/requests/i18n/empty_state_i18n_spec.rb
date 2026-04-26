# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Empty state messages i18n (orders, products, customers)", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders view_all_orders view_products view_customers])
  end
  let(:user) { create(:user) }

  before do
    user.profile.update!(role: role, preferred_locale: "th")
    sign_in user
  end

  describe "TH user with no orders visits GET /orders" do
    before { get orders_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai empty-state message for orders" do
      expect(response.body).to include("ไม่พบออเดอร์")
    end
  end

  describe "TH user with no products visits GET /products" do
    before { get products_path }

    it "renders Thai empty-state message for products" do
      expect(response.body).to include("ไม่พบสินค้า")
    end
  end

  describe "TH user with no customers visits GET /customers" do
    before { get customers_path }

    it "renders Thai empty-state message for customers" do
      expect(response.body).to include("ไม่พบลูกค้า")
    end
  end
end
