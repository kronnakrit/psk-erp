# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::V1::Catalogs::Products lots", type: :request do
  let(:user) { create(:user) }
  let(:role) { create(:role, permissions: %w[view_products]) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "GET /api/v1/catalogs/products/:id/lots" do
    context "when product has active lots" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:unit_group) { create(:unit_group) }
      let(:product)    { create(:product, unit_group: unit_group, enable_stock: true) }
      let(:po)         { create(:purchase_order) }
      let!(:lot_old)   { create(:product_lot, product: product, purchase_order: po, received_date: 1.month.ago) }
      let!(:lot_new)   { create(:product_lot, product: product, purchase_order: po, received_date: Date.current) }

      it "returns 200 with lots ordered by received_date ASC" do
        get lots_api_v1_catalogs_product_path(product)
        expect(response).to have_http_status(:ok)
        ids = response.parsed_body.pluck("id")
        expect(ids).to eq([lot_old.id, lot_new.id])
      end

      it "includes expected fields" do
        get lots_api_v1_catalogs_product_path(product)
        lot_data = response.parsed_body.first
        expect(lot_data.keys).to include("id", "lot_number", "received_date", "remaining_quantity", "unit_cost")
      end
    end

    context "when product has no lots" do
      let(:product) { create(:product) }

      it "returns 200 with empty array" do
        get lots_api_v1_catalogs_product_path(product)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end
    end

    context "when product has enable_stock: false" do
      let(:product) { create(:product, enable_stock: false) }

      it "returns 200 with empty array" do
        get lots_api_v1_catalogs_product_path(product)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end
    end

    context "when product does not exist" do
      it "returns 404" do
        get lots_api_v1_catalogs_product_path(id: 999_999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
