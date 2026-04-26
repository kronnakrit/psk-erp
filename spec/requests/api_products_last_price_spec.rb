# frozen_string_literal: true

require "rails_helper"

# STORY-18-03 — Unit-Aware last_price Endpoint (request specs T-18-03-03 to T-18-03-05)
RSpec.describe "API::V1::Catalogs::Products last_price", type: :request do
  let(:admin_role) { create(:role, permissions: %w[view_products]) }
  let(:user)       { create(:user) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  # Shared setup factory helpers (kept out of top-level lets to avoid memoized helper limit)
  def setup_unit_context
    customer   = create(:customer)
    unit_group = create(:unit_group)
    pc_def     = create(:unit_definition, unit_group: unit_group, name: "Pc",  ratio: 1)
    box_def    = create(:unit_definition, unit_group: unit_group, name: "Box", ratio: 12)
    product    = create(:product, price: 7.0, unit_group: unit_group)
    { customer: customer, unit_group: unit_group, pc_def: pc_def,
      box_def: box_def, product: product }
  end

  def last_price_url(product, customer, extra_params = {})
    url = last_price_api_v1_catalogs_product_path(product, customer)
    extra_params.any? ? "#{url}?#{extra_params.to_query}" : url
  end

  # AC-01: customer last paid ฿80 for Box unit; returns 80 as last_price
  describe "with unit_definition_id matching prior order (AC-01)" do
    it "returns last_price 80 and default_price 7" do
      ctx   = setup_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 80.0, unit_definition: ctx[:box_def])
      get last_price_url(ctx[:product], ctx[:customer],
                         unit_definition_id: ctx[:box_def].id),
          headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["last_price"].to_f).to eq(80.0)
      expect(response.parsed_body["default_price"].to_f).to eq(7.0)
    end
  end

  # AC-02: customer has not ordered in Box unit; returns last_price null
  describe "with unit_definition_id and no matching prior order (AC-02)" do
    it "returns last_price null and default_price 7" do
      ctx   = setup_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 50.0, unit_definition: ctx[:pc_def])
      get last_price_url(ctx[:product], ctx[:customer],
                         unit_definition_id: ctx[:box_def].id),
          headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["last_price"]).to be_nil
      expect(response.parsed_body["default_price"].to_f).to eq(7.0)
    end
  end

  # AC-03: no unit_definition_id param — legacy behaviour
  describe "without unit_definition_id param (AC-03)" do
    it "returns most recent order line price regardless of unit" do
      ctx   = setup_unit_context
      order = create(:order, customer: ctx[:customer])
      create(:order_line, order: order, product: ctx[:product],
                          unit_price: 55.0, unit_definition: ctx[:pc_def])
      get last_price_url(ctx[:product], ctx[:customer]),
          headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["last_price"].to_f).to eq(55.0)
      expect(response.parsed_body["default_price"].to_f).to eq(7.0)
    end
  end

  # AC-04: unauthenticated request
  describe "unauthenticated request (AC-04)" do
    it "returns 401" do
      ctx = setup_unit_context
      sign_out user
      get last_price_url(ctx[:product], ctx[:customer],
                         unit_definition_id: ctx[:box_def].id),
          headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
