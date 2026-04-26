require "rails_helper"

RSpec.describe "Purchase Orders index design tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_purchase_orders add_purchase_orders change_purchase_orders delete_purchase_orders
    ])
  end
  let(:user) { create(:user) }
  let!(:purchase_order) { create(:purchase_order) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "GET /purchase_orders" do
    before { get purchase_orders_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders btn-primary on New Purchase Order button" do
      expect(response.body).to include("btn-primary")
    end

    it "renders row-action-primary on View/Edit links" do
      expect(response.body).to include("row-action-primary")
    end

    it "renders row-action-danger on Delete button" do
      expect(response.body).to include("row-action-danger")
    end
  end
end
