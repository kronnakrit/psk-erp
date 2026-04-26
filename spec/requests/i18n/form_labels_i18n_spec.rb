# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders form section labels i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders add_orders change_orders view_all_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_order_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ลูกค้า as customer label" do
      expect(response.body).to include("ลูกค้า")
    end

    it "renders ข้อมูลออเดอร์ as Order Information section heading" do
      expect(response.body).to include("ข้อมูลออเดอร์")
    end

    it "renders รายการสินค้า as Order Lines section heading" do
      expect(response.body).to include("รายการสินค้า")
    end

    it "renders สรุปราคา as Summary section heading" do
      expect(response.body).to include("สรุปราคา")
    end

    it "renders ยอดรวมสุทธิ as Grand Total label" do
      expect(response.body).to include("ยอดรวมสุทธิ")
    end

    it "renders สร้างออเดอร์ as submit button" do
      expect(response.body).to include("สร้างออเดอร์")
    end
  end

  describe "EN user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_order_path
    end

    it "renders Customer as customer label" do
      expect(response.body).to include("Customer")
    end

    it "renders Order Information as section heading" do
      expect(response.body).to include("Order Information")
    end

    it "renders Create Order as submit button" do
      expect(response.body).to include("Create Order")
    end

    it "renders Grand Total as grand total label" do
      expect(response.body).to include("Grand Total")
    end
  end
end
