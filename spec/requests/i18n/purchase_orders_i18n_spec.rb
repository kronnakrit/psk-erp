require "rails_helper"

RSpec.describe "Purchase Orders i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_purchase_orders add_purchase_orders])
  end
  let!(:purchase_order) { create(:purchase_order) }

  describe "Thai user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get purchase_orders_path
    end

    it "renders ใบสั่งซื้อ as page title" do
      expect(response.body).to include("ใบสั่งซื้อ")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get purchase_orders_path
    end

    it "renders Purchase Orders as page title" do
      expect(response.body).to include("Purchase Orders")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
