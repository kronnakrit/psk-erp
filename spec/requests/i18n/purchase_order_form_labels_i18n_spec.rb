# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase orders form labels i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_purchase_orders add_purchase_orders change_purchase_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /purchase_orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_purchase_order_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ซัพพลายเออร์ as Supplier label" do
      expect(response.body).to include("ซัพพลายเออร์")
    end

    it "renders ข้อมูลใบสั่งซื้อ as PO Information section heading" do
      expect(response.body).to include("ข้อมูลใบสั่งซื้อ")
    end

    it "renders สร้างใบสั่งซื้อ as submit button" do
      expect(response.body).to include("สร้างใบสั่งซื้อ")
    end

    it "renders วันที่สั่งซื้อ as PO Date label" do
      expect(response.body).to include("วันที่สั่งซื้อ")
    end
  end

  describe "EN user visiting GET /purchase_orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_purchase_order_path
    end

    it "renders Supplier as supplier label" do
      expect(response.body).to include("Supplier")
    end

    it "renders Purchase Order Information as section heading" do
      expect(response.body).to include("Purchase Order Information")
    end

    it "renders Create Purchase Order as submit button" do
      expect(response.body).to include("Create Purchase Order")
    end
  end
end
