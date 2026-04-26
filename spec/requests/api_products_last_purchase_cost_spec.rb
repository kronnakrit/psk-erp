# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::V1::Catalogs::Products last_purchase_cost", type: :request do
  let(:admin_role) { create(:role, permissions: %w[view_products]) }
  let(:user)       { create(:user) }
  let(:product)    { create(:product, cost: 42.50) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /api/v1/catalogs/products/:id/last_purchase_cost" do
    context "when no confirmed PO exists" do
      it "returns product.cost" do
        get last_purchase_cost_api_v1_catalogs_product_path(product)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["unit_cost"].to_f).to eq(42.50)
      end
    end

    context "when a confirmed PO line exists" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:supplier)   { create(:supplier) }
      let(:unit_group) { create(:unit_group) }
      let(:unit_def)   { create(:unit_definition, unit_group: unit_group, ratio: 1) }
      let(:confirmed_po) { create(:purchase_order, supplier: supplier) }

      before do
        product.update!(unit_group: unit_group)
        confirmed_po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
        create(:purchase_order_line,
               purchase_order: confirmed_po, product: product,
               unit_definition: unit_def, unit_cost: 99.99)
      end

      it "returns the PO line unit_cost" do
        get last_purchase_cost_api_v1_catalogs_product_path(product)
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["unit_cost"].to_f).to eq(99.99)
      end
    end

    context "when product does not exist" do
      it "returns 404" do
        get last_purchase_cost_api_v1_catalogs_product_path(id: 999_999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
