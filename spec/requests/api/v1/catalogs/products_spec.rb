# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v1 Catalogs Products", type: :request do
  def jwt_headers_for(user)
    post "/api/v1/auth/sign_in",
         params: { user: { username: user.username, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  let(:role) { create(:role, permissions: %w[view_products]) }
  let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
  let(:headers) { jwt_headers_for(user) }
  let!(:product) { create(:product, name: "Catalog Widget", product_type: "Sa") }

  describe "GET /api/v1/catalogs/products" do
    it "returns 200 with product list" do
      get api_v1_catalogs_products_path, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/catalogs/products/:id" do
    it "returns 200 with product details" do
      get api_v1_catalogs_product_path(product), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(product.id)
    end
  end

  describe "GET /api/v1/catalogs/products/:id/parent" do
    let!(:child) { create(:product, :child, parent: product, name: "Child Widget") }

    it "returns 200 with child products" do
      get parent_api_v1_catalogs_product_path(product), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/catalogs/products/:id/child" do
    let!(:child) { create(:product, :child, parent: product, name: "Child Item") }

    it "returns 200 with child product details" do
      get child_api_v1_catalogs_product_path(child), headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(child.id)
    end
  end

  describe "GET /api/v1/catalogs/products/:id/advance_search" do
    it "returns 200 with search results" do
      get advance_search_api_v1_catalogs_product_path(product),
          params: { q: { name_cont: "Widget" } },
          headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["results"]).to be_an(Array)
    end
  end
end
