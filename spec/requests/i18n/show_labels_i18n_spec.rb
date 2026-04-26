# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Show page section labels i18n", type: :request do
  let(:order_role) do
    create(:role, permissions: %w[view_orders add_orders change_orders view_all_orders])
  end
  let(:invoice_role) do
    create(:role, permissions: %w[view_invoices add_invoices change_invoices])
  end
  let(:po_role) do
    create(:role, permissions: %w[view_purchase_orders add_purchase_orders change_purchase_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders/:id" do
    let!(:order) { create(:order) }

    before do
      user.profile.update!(role: order_role, preferred_locale: "th")
      sign_in user
      get order_path(order)
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders รายละเอียดออเดอร์ as Order Details heading" do
      expect(response.body).to include("รายละเอียดออเดอร์")
    end

    it "renders ลูกค้า as Customer dt label" do
      expect(response.body).to include("ลูกค้า")
    end

    it "renders ที่อยู่ as Address dt label" do
      expect(response.body).to include("ที่อยู่")
    end
  end

  describe "TH user visiting GET /invoices/:id" do
    let!(:invoice) { create(:invoice) }

    before do
      user.profile.update!(role: invoice_role, preferred_locale: "th")
      sign_in user
      get invoice_path(invoice)
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders เลขที่ใบแจ้งหนี้ as Invoice # dt label" do
      expect(response.body).to include("เลขที่ใบแจ้งหนี้")
    end

    it "renders รายละเอียดใบแจ้งหนี้ as Invoice Details heading" do
      expect(response.body).to include("รายละเอียดใบแจ้งหนี้")
    end
  end

  describe "TH user visiting GET /purchase_orders/:id" do
    let!(:purchase_order) { create(:purchase_order) }

    before do
      user.profile.update!(role: po_role, preferred_locale: "th")
      sign_in user
      get purchase_order_path(purchase_order)
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ซัพพลายเออร์ as Supplier dt label" do
      expect(response.body).to include("ซัพพลายเออร์")
    end

    it "renders วันที่สั่งซื้อ as PO Date dt label" do
      expect(response.body).to include("วันที่สั่งซื้อ")
    end
  end
end
