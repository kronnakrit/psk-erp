require "rails_helper"

RSpec.describe "Section heading tokens on show pages", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders view_all_orders view_invoices view_products view_purchase_orders
      view_product_stocks
    ])
  end
  let(:user) { create(:user) }
  let!(:order) { create(:order) }
  let!(:invoice) { create(:invoice) }
  let!(:product) { create(:product) }
  let!(:purchase_order) { create(:purchase_order) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  it "orders show page includes section-heading" do
    get order_path(order)
    expect(response.body).to include("section-heading")
  end

  it "invoices show page includes section-heading" do
    get invoice_path(invoice)
    expect(response.body).to include("section-heading")
  end

  it "products show page includes section-heading" do
    get product_path(product)
    expect(response.body).to include("section-heading")
  end
end
