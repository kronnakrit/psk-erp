# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase orders search and line product placeholder i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_purchase_orders add_purchase_orders change_purchase_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /purchase_orders" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get purchase_orders_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai purchase order search placeholder" do
      expect(response.body).to include("ค้นหาโดยเลขที่ใบสั่งซื้อ")
    end
  end

  describe "TH user visiting GET /purchase_orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_purchase_order_path
    end

    it "renders Thai PO line product search placeholder" do
      expect(response.body).to include("ค้นหา SKU หรือชื่อสินค้า")
    end
  end
end
