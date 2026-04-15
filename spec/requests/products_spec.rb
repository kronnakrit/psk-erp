# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_products add_products change_products delete_products can_view_cost
           ])
  end
  let(:user) { create(:user) }
  let!(:product) { create(:product, name: "Widget Alpha", product_type: "Sa") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /products" do
    it "returns 200" do
      get products_path
      expect(response).to have_http_status(:ok)
    end

    it "lists products" do
      get products_path
      expect(response.body).to include("Widget Alpha")
    end
  end

  describe "GET /products/new" do
    it "returns 200" do
      get new_product_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /products" do
    let(:valid_attrs) do
      {
        name: "New Product", product_type: "Sa", price: "150.00",
        cost: "80.00", enable_stock: "0"
      }
    end

    it "creates and redirects" do
      expect do
        post products_path, params: { product: valid_attrs }
      end.to change(Product, :count).by(1)
      expect(response).to redirect_to(products_path)
    end

    it "auto-generates sku" do
      post products_path, params: { product: valid_attrs }
      created = Product.find_by!(name: "New Product")
      expect(created.sku).to be_present
    end

    it "renders new on invalid data" do
      post products_path, params: { product: { name: "", product_type: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /products/:id/edit" do
    it "returns 200" do
      get edit_product_path(product)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /products/:id" do
    it "updates and redirects" do
      patch product_path(product), params: { product: { name: "Widget Beta" } }
      expect(response).to redirect_to(products_path)
      expect(product.reload.name).to eq("Widget Beta")
    end

    it "renders edit on invalid data" do
      patch product_path(product), params: { product: { name: "", product_type: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /products/:id" do
    it "deletes and redirects" do
      expect do
        delete product_path(product)
      end.to change(Product, :count).by(-1)
      expect(response).to redirect_to(products_path)
    end
  end

  describe "cost hidden from unauthorized user" do
    let(:no_cost_role) do
      create(:role, permissions: %w[view_products add_products change_products delete_products])
    end

    it "does not show cost column when permission missing" do
      user.profile.update!(role: no_cost_role)
      get products_path
      expect(response.body).not_to include("Cost")
    end
  end

  describe "GET /api/v1/catalogs/products" do
    it "returns json with product list" do
      get api_v1_catalogs_products_path, headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["results"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/catalogs/products/filters" do
    it "returns products matching filter" do
      create(:product, name: "Stock Product", enable_stock: true)
      post filters_api_v1_catalogs_products_path,
           params: { has_stock: "true" },
           headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["results"].pluck("enable_stock")).to all(be_truthy)
    end
  end

  describe "GET /products (Stock link shortcut)" do
    let(:stock_role) do
      create(:role, permissions: %w[
               view_products add_products change_products delete_products can_view_cost
               view_product_stocks
             ])
    end

    before { user.profile.update!(role: stock_role) }

    it "includes Stock link for products with enable_stock: true" do
      stock_product = create(:product, name: "Stockable Widget", enable_stock: true)
      get products_path
      expected_url = CGI.unescapeHTML(stocks_path(q: { product_id_eq: stock_product.id }))
      expect(response.body).to include(expected_url)
    end

    it "does not include Stock link for products with enable_stock: false" do
      non_stock_product = create(:product, name: "No Stock Widget", enable_stock: false)
      get products_path
      expected_url = stocks_path(q: { product_id_eq: non_stock_product.id })
      expect(response.body).not_to include(expected_url)
    end
  end
end
