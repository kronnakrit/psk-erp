require "rails_helper"

RSpec.describe "Orders index design tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders add_orders change_orders delete_orders view_all_orders
    ])
  end
  let(:user) { create(:user) }
  let!(:order) { create(:order) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "GET /orders" do
    before { get orders_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders btn-primary on New Order button" do
      expect(response.body).to include("btn-primary")
    end

    it "renders row-action-primary on View/Edit links" do
      expect(response.body).to include("row-action-primary")
    end

    it "renders row-action-muted on Print link" do
      expect(response.body).to include("row-action-muted")
    end

    it "renders row-action-danger on Delete button" do
      expect(response.body).to include("row-action-danger")
    end
  end
end
