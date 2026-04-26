require "rails_helper"

RSpec.describe "Products show button tokens", type: :request do
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
    get product_path(product)
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders btn-primary on Edit" do
    expect(response.body).to include("btn-primary")
  end

  it "renders btn-secondary on Duplicate" do
    expect(response.body).to include("btn-secondary")
  end
end
