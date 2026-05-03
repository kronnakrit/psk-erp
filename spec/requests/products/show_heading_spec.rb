require "rails_helper"

RSpec.describe "Products show heading tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_products add_products change_products delete_products view_product_stocks
    ])
  end
  let(:user) { create(:user) }
  let!(:product) { create(:product) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "GET /products/:id" do
    before { get product_path(product) }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders page-heading on h1" do
      expect(response.body).to include("page-heading")
    end

    it "renders section-heading for sub-sections" do
      expect(response.body).to include("section-heading")
    end
  end
end
