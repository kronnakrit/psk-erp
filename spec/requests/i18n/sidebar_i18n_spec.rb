require "rails_helper"

RSpec.describe "Sidebar i18n navigation", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders view_invoices view_purchase_orders view_products view_customers
      view_product_stocks
    ])
  end

  describe "Thai user (default)" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get root_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ออเดอร์ in the sidebar" do
      expect(response.body).to include("ออเดอร์")
    end

    it "renders แดชบอร์ด in the sidebar" do
      expect(response.body).to include("แดชบอร์ด")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get root_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Orders in the sidebar" do
      expect(response.body).to include("Orders")
    end

    it "renders Dashboard in the sidebar" do
      expect(response.body).to include("Dashboard")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
