# frozen_string_literal: true

require "rails_helper"

# STORY-18-02 — Product Catalog API: Exclude Cost, Include Unit Definition Ratios
RSpec.describe "API::V1::Catalogs::Products catalog", type: :request do
  let(:admin_role) { create(:role, permissions: %w[view_products]) }
  let(:user)       { create(:user) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  # AC-01: product objects do not contain a "cost" key
  describe "GET /api/v1/catalogs/products (AC-01)" do
    before { create(:product, name: "Widget", price: 7.0, cost: 50.0) }

    it "does not include cost key in product response" do
      get api_v1_catalogs_products_path,
          params: { q: { name_cont: "Widget" } },
          headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      results = response.parsed_body["results"]
      expect(results).not_to be_empty
      expect(results.map(&:keys).flatten).not_to include("cost")
    end
  end

  # AC-02: unit_definitions array with id, name, ratio ordered by ratio ASC
  describe "GET /api/v1/catalogs/products (AC-02)" do
    let(:unit_group) { create(:unit_group) }
    let(:pc_def)     { create(:unit_definition, unit_group: unit_group, name: "Pc",  ratio: 1) }
    let(:box_def)    { create(:unit_definition, unit_group: unit_group, name: "Box", ratio: 12) }

    before do
      pc_def
      box_def
      create(:product, name: "UnitProduct", price: 7.0, unit_group: unit_group)
    end

    def fetch_product_json
      get api_v1_catalogs_products_path,
          params: { q: { name_cont: "UnitProduct" } },
          headers: { "Accept" => "application/json" }
      response.parsed_body["results"].find { |p| p["name"] == "UnitProduct" }
    end

    it "includes unit_definitions key" do
      p = fetch_product_json
      expect(p["unit_definitions"]).to be_an(Array)
    end

    it "returns both unit definitions" do
      p = fetch_product_json
      expect(p["unit_definitions"].size).to eq(2)
    end

    it "orders unit_definitions by ratio ASC" do
      p = fetch_product_json
      ratios = p["unit_definitions"].pluck("ratio")
      expect(ratios).to eq([1, 12])
    end

    it "includes correct fields for Pc unit" do
      p = fetch_product_json
      pc_entry = p["unit_definitions"].find { |u| u["name"] == "Pc" }
      expect(pc_entry).to include("id" => pc_def.id, "name" => "Pc", "ratio" => 1)
    end

    it "includes correct fields for Box unit" do
      p = fetch_product_json
      box_entry = p["unit_definitions"].find { |u| u["name"] == "Box" }
      expect(box_entry).to include("id" => box_def.id, "name" => "Box", "ratio" => 12)
    end
  end

  # AC-03: unauthenticated request returns 401
  describe "GET /api/v1/catalogs/products unauthenticated (AC-03)" do
    it "returns 401" do
      sign_out user
      get api_v1_catalogs_products_path,
          headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
