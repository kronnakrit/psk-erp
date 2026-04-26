# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products#lots", type: :request do
  let(:role)    { create(:role, permissions: %w[view_products]) }
  let(:user)    { create(:user) }
  let(:product) { create(:product) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "GET /products/:id/lots" do
    context "when authenticated with view_products permission" do
      it "returns 200 with no lots" do
        get lots_product_path(product)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No lots have been created")
      end

      it "returns 200 and shows lots when lots exist" do
        po  = create(:purchase_order)
        lot = create(:product_lot, product: product, purchase_order: po)
        get lots_product_path(product)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(lot.lot_number)
      end
    end

    context "when user has no view_products permission" do
      it "redirects" do
        user.profile.update!(role: create(:role, permissions: []))
        get lots_product_path(product)
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
