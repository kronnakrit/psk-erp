require "rails_helper"

RSpec.describe "Table header column i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders view_all_orders view_invoices view_products view_customers
      view_purchase_orders view_users view_product_stocks
    ])
  end

  describe "TH user visiting GET /orders" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get orders_path
    end

    it "renders พนักงานขาย as Salesperson column header" do
      expect(response.body).to include("พนักงานขาย")
    end

    it "renders ยอดรวมสุทธิ as Grand Total column header" do
      expect(response.body).to include("ยอดรวมสุทธิ")
    end
  end

  describe "EN user visiting GET /orders" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get orders_path
    end

    it "renders Salesperson as column header" do
      expect(response.body).to include("Salesperson")
    end

    it "renders Grand Total as column header" do
      expect(response.body).to include("Grand Total")
    end
  end

  describe "TH user visiting GET /products" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get products_path
    end

    it "renders ประเภท as Type column header" do
      expect(response.body).to include("ประเภท")
    end
  end

  describe "TH user visiting GET /customers" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get customers_path
    end

    it "renders เบอร์โทรศัพท์ as Telephone column header" do
      expect(response.body).to include("เบอร์โทรศัพท์")
    end
  end

  describe "TH user visiting GET /purchase_orders" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get purchase_orders_path
    end

    it "renders จำนวนรายการ as Lines column header" do
      expect(response.body).to include("จำนวนรายการ")
    end
  end
end
