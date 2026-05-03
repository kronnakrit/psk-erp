require "rails_helper"

RSpec.describe "Purchase Orders show heading tokens", type: :request do
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

  describe "GET /purchase_orders/:id" do
    before { get purchase_order_path(purchase_order) }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders page-heading on h1" do
      expect(response.body).to include("page-heading")
    end

  end
end
