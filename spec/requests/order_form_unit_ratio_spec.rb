# frozen_string_literal: true

require "rails_helper"

# STORY-18-04 — Order Form: Ratio-Based Price Recalculation on Unit Change
# T-18-04-09 / T-18-04-10: Integration specs verifying that the HTML structure
# rendered by the order form supports the client-side ratio-based price recalculation
# (data-ratio, data-current-ratio, data-action attributes are all present).
RSpec.describe "Order form unit ratio HTML (STORY-18-04)", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders add_orders change_orders])
  end
  let(:user) { create(:user) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  def build_unit_context
    unit_group = create(:unit_group)
    pc_def     = create(:unit_definition, unit_group: unit_group, name: "Pc",  ratio: 1)
    box_def    = create(:unit_definition, unit_group: unit_group, name: "Box", ratio: 12)
    product    = create(:product, price: 7.0, unit_group: unit_group)
    customer   = create(:customer)
    { unit_group: unit_group, pc_def: pc_def, box_def: box_def,
      product: product, customer: customer }
  end

  # AC-01 / T-18-04-09 — edit page renders data-ratio on options and data-current-ratio on select
  describe "GET /orders/:id/edit (AC-06 — existing order line)" do
    def setup_edit_order(box_def:)
      ctx   = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: box_def || ctx[:box_def])
      get edit_order_path(order)
    end

    it "returns 200" do
      ctx = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get edit_order_path(order)
      expect(response).to have_http_status(:ok)
    end

    it "renders data-ratio on unit definition options" do
      ctx = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get edit_order_path(order)
      expect(response.body).to include("data-ratio=\"1\"")
      expect(response.body).to include("data-ratio=\"12\"")
    end

    it "wires up onUnitDefinitionChange and data-current-ratio on the unit select" do
      ctx = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get edit_order_path(order)
      expect(response.body).to include("data-current-ratio=")
      expect(response.body).to include("order-form#onUnitDefinitionChange")
    end

    it "sets data-current-ratio to Box ratio (12) for the saved order line" do
      ctx   = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get edit_order_path(order)
      expect(response.body).to include("data-current-ratio=\"12\"")
    end
  end

  # AC-02/AC-03 / T-18-04-10 — new order form has ratio attributes for JS calculation
  describe "GET /orders/new (AC-01 — new order)" do
    it "renders the unit definition select with change action" do
      get new_order_path
      expect(response.body).to include("order-form#onUnitDefinitionChange")
    end
  end

  # API: last_price with unit_definition_id is wired correctly (AC-01)
  describe "GET /api/v1/catalogs/products/:id/last_price/:customer_id?unit_definition_id (T-18-04-09)" do
    it "returns unit-accurate last price for Box" do
      ctx   = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get last_price_api_v1_catalogs_product_path(ctx[:product], ctx[:customer]),
          params: { unit_definition_id: ctx[:box_def].id },
          headers: { "Accept" => "application/json" }
      expect(response.parsed_body["last_price"].to_f).to eq(80.0)
    end

    it "returns default_price 7 for Box" do
      ctx   = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get last_price_api_v1_catalogs_product_path(ctx[:product], ctx[:customer]),
          params: { unit_definition_id: ctx[:box_def].id },
          headers: { "Accept" => "application/json" }
      expect(response.parsed_body["default_price"].to_f).to eq(7.0)
    end

    it "returns null last_price for Pc (no prior Pc orders)" do
      ctx   = build_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get last_price_api_v1_catalogs_product_path(ctx[:product], ctx[:customer]),
          params: { unit_definition_id: ctx[:pc_def].id },
          headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["last_price"]).to be_nil
    end
  end
end
