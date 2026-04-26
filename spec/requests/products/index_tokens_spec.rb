require "rails_helper"

RSpec.describe "Products index design tokens", type: :request do
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

  describe "GET /products" do
    before { get products_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders btn-primary on New Product button" do
      expect(response.body).to include("btn-primary")
    end

    it "renders row-action-primary on Stock/Edit links" do
      expect(response.body).to include("row-action-primary")
    end

    it "renders row-action-muted on Images link" do
      expect(response.body).to include("row-action-muted")
    end

    it "renders row-action-danger on Delete button" do
      expect(response.body).to include("row-action-danger")
    end
  end
end
