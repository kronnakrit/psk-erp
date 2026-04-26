# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::V1::Catalogs::Products fifo_cost", type: :request do
  let(:admin_role) { create(:role, permissions: %w[view_products]) }
  let(:user)       { create(:user) }
  let(:product)    { create(:product, enable_stock: true) }

  before do
    create(:branch, :main)
    user.profile.update!(role: admin_role)
    sign_in user
  end

  def make_lot(remaining:, cost:, received_date: Date.current)
    po = create(:purchase_order)
    create(:product_lot,
           product:            product,
           purchase_order:     po,
           original_quantity:  remaining,
           remaining_quantity: remaining,
           unit_cost:          cost,
           status:             ProductLot::STATUS_ACTIVE,
           received_date:      received_date)
  end

  let(:path) { fifo_cost_api_v1_catalogs_product_path(product) }

  # AC-01: multi-lot response shape
  describe "GET /api/v1/catalogs/products/:id/fifo_cost" do
    context "with two active lots and sufficient quantity (AC-01)" do
      let!(:lot_a) { make_lot(remaining: 10, cost: 20, received_date: 3.days.ago) }
      let!(:lot_b) { make_lot(remaining: 5,  cost: 30, received_date: 1.day.ago) }

      before { get path, params: { quantity: 12 } }

      it "returns 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns correct weighted_avg_cost" do
        expect(response.parsed_body["weighted_avg_cost"].to_f).to eq(21.67)
      end

      it "returns two allocations in FIFO order" do
        allocations = response.parsed_body["allocations"]
        expect(allocations.size).to eq(2)
        expect(allocations.first["lot_number"]).to eq(lot_a.lot_number)
        expect(allocations.last["lot_number"]).to eq(lot_b.lot_number)
      end

      it "returns has_phantom: false" do
        expect(response.parsed_body["has_phantom"]).to be(false)
      end
    end

    # AC-02: no lots → all phantom
    context "with no active lots (AC-02)" do
      before { get path, params: { quantity: 5 } }

      it "returns 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns weighted_avg_cost of 0" do
        expect(response.parsed_body["weighted_avg_cost"].to_f).to eq(0)
      end

      it "returns empty allocations array" do
        expect(response.parsed_body["allocations"]).to be_empty
      end

      it "returns has_phantom: true" do
        expect(response.parsed_body["has_phantom"]).to be(true)
      end
    end

    # AC-03: missing quantity → 422
    context "with missing quantity param (AC-03)" do
      before { get path }

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        expect(response.parsed_body["error"]).to include("quantity is required")
      end
    end

    # AC-04: zero or negative quantity → 422
    context "with quantity = 0 (AC-04)" do
      before { get path, params: { quantity: 0 } }

      it "returns 422" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        expect(response.parsed_body["error"]).to include("greater than 0")
      end
    end

    # AC-05: unit_definition_id converts quantity to base units
    context "with unit_definition_id (AC-05)" do
      let(:unit_group) { create(:unit_group) }
      let!(:dozen)     { create(:unit_definition, unit_group: unit_group, name: "dozen", ratio: 12) }
      let!(:lot_a)     { make_lot(remaining: 24, cost: 50, received_date: 1.day.ago) }

      before do
        product.update!(unit_group: unit_group)
        get path, params: { quantity: 2, unit_definition_id: dozen.id }
      end

      it "returns 200" do
        expect(response).to have_http_status(:ok)
      end

      it "converts 2 dozens to 24 base units and allocates fully" do
        allocations = response.parsed_body["allocations"]
        expect(allocations.first["allocated_qty"].to_f).to eq(24)
      end

      it "returns correct weighted_avg_cost" do
        expect(response.parsed_body["weighted_avg_cost"].to_f).to eq(50.0)
      end
    end

    # AC-06: unauthenticated → redirect (Devise authenticate_user! redirects to sign_in)
    context "when unauthenticated (AC-06)" do
      before do
        sign_out user
        get path, params: { quantity: 1 }
      end

      it "redirects (no access without authentication)" do
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
