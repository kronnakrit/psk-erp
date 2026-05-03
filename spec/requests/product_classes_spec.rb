# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ProductClasses", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_product_classes add_product_classes change_product_classes delete_product_classes
           ])
  end
  let(:user) { create(:user) }
  let!(:product_class) { create(:product_class, name: "Clothing") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /product_classes" do
    it "returns 200 and lists product classes" do
      get product_classes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Clothing")
    end
  end

  describe "POST /product_classes" do
    it "creates and redirects" do
      expect do
        post product_classes_path, params: { product_class: { name: "Electronics" } }
      end.to change(ProductClass, :count).by(1)
      expect(response).to redirect_to(product_classes_path)
    end

    it "renders new on blank name" do
      post product_classes_path, params: { product_class: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /product_classes/:id" do
    it "updates and redirects" do
      patch product_class_path(product_class), params: { product_class: { name: "Footwear" } }
      expect(response).to redirect_to(product_classes_path)
      expect(product_class.reload.name).to eq("Footwear")
    end
  end

  describe "GET /product_classes/:id" do
    it "returns 200" do
      get product_class_path(product_class)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /product_classes/new" do
    it "returns 200" do
      get new_product_class_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /product_classes/:id/edit" do
    it "returns 200" do
      get edit_product_class_path(product_class)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /product_classes/:id with invalid data" do
    it "renders edit with unprocessable_content" do
      patch product_class_path(product_class), params: { product_class: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /product_classes/:id" do
    it "deletes the product class" do
      expect do
        delete product_class_path(product_class)
      end.to change(ProductClass, :count).by(-1)
      expect(response).to redirect_to(product_classes_path)
    end
  end
end

RSpec.describe "ProductCategories", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_product_categories add_product_categories change_product_categories delete_product_categories
           ])
  end
  let(:user) { create(:user) }
  let!(:product_category) { create(:product_category, name: "T-Shirts") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /product_categories" do
    it "returns 200 and lists categories" do
      get product_categories_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("T-Shirts")
    end
  end

  describe "POST /product_categories" do
    it "creates and redirects" do
      expect do
        post product_categories_path, params: { product_category: { name: "Hoodies" } }
      end.to change(ProductCategory, :count).by(1)
      expect(response).to redirect_to(product_categories_path)
    end
  end

  describe "DELETE /product_categories/:id" do
    it "deletes the category" do
      expect do
        delete product_category_path(product_category)
      end.to change(ProductCategory, :count).by(-1)
    end
  end

  describe "GET /product_categories/:id" do
    it "returns 200" do
      get product_category_path(product_category)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /product_categories/:id with invalid data" do
    it "renders edit with unprocessable_content" do
      patch product_category_path(product_category), params: { product_category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/catalogs/list_product_categories" do
    it "returns all categories unpaginated" do
      get api_v1_catalogs_list_product_categories_path
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["results"].pluck("name")).to include("T-Shirts")
    end
  end
end
