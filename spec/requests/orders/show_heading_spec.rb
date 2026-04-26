require "rails_helper"

RSpec.describe "Orders show heading tokens", type: :request do
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

  describe "GET /orders/:id" do
    before { get order_path(order) }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders page-heading on h1" do
      expect(response.body).to include("page-heading")
    end

    it "renders back-link" do
      expect(response.body).to include("back-link")
    end

    it "renders ← Back text" do
      expect(response.body).to include("back-link")
      expect(response.body).to match(/←\s+(กลับ|Back)/)
    end

    it "renders section-heading for sub-sections" do
      expect(response.body).to include("section-heading")
    end
  end
end
