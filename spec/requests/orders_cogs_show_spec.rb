# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders show COGS column (EPIC-17)", type: :request do
  before { create(:branch, :main) }

  let(:admin_role)    { create(:role, permissions: %w[view_orders add_orders change_orders can_view_cost]) }
  let(:limited_role)  { create(:role, permissions: %w[view_orders]) }
  let(:product)       { create(:product, enable_stock: true) }
  let(:order)         { create(:order) }
  let!(:order_line)   { create(:order_line, order: order, product: product, quantity: 2) }

  describe "GET /orders/:id (show)" do
    context "with can_view_cost permission (AC-01, AC-02)" do
      let(:user) { create(:user) }

      before do
        user.profile.update!(role: admin_role)
        sign_in user
      end

      it "returns 200" do
        get order_path(order)
        expect(response).to have_http_status(:ok)
      end

      it "shows COST column header" do
        get order_path(order)
        expect(response.body).to include("Cost")
      end

      it "does not show Lot column header" do
        get order_path(order)
        expect(response.body).not_to include(">Lot<")
      end

      it "shows cogs value in the row" do
        order_line.update_columns(cogs: 25.50) # rubocop:disable Rails/SkipsModelValidations
        get order_path(order)
        expect(response.body).to include("25.50")
      end
    end

    context "without can_view_cost permission (AC-04)" do
      let(:user) { create(:user) }

      before do
        user.profile.update!(role: limited_role)
        sign_in user
      end

      it "returns 200" do
        get order_path(order)
        expect(response).to have_http_status(:ok)
      end

      it "does not show COST column header" do
        get order_path(order)
        expect(response.body).not_to include(">Cost<")
      end
    end
  end
end
