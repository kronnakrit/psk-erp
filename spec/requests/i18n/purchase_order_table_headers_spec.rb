require "rails_helper"

RSpec.describe "Purchase orders show and form table header i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_purchase_orders add_purchase_orders change_purchase_orders])
  end
  let(:user) { create(:user) }
  let!(:purchase_order) { create(:purchase_order) }

  describe "TH user visiting GET /purchase_orders/:id" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get purchase_order_path(purchase_order)
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders จำนวน as Qty column header" do
      expect(response.body).to include("จำนวน")
    end

    it "renders ราคาต้นทุน as Unit Cost column header" do
      expect(response.body).to include("ราคาต้นทุน")
    end
  end

  describe "TH user visiting GET /purchase_orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_purchase_order_path
    end

    it "renders จำนวน as Qty column header in form" do
      expect(response.body).to include("จำนวน")
    end

    it "renders ราคาต้นทุน as Unit Cost column header in form" do
      expect(response.body).to include("ราคาต้นทุน")
    end
  end
end
