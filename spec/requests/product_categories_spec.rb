# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Product Categories (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in admin_user }

  describe "GET /product_categories" do
    it "returns 200" do
      get product_categories_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /product_categories/new" do
    it "returns 200" do
      get new_product_category_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /product_categories" do
    it "creates and redirects" do
      post product_categories_path, params: { product_category: { name: "NewCat" } }
      expect(response).to redirect_to(product_categories_path)
      expect(ProductCategory.find_by(name: "NewCat")).to be_present
    end

    it "renders new on blank name" do
      post product_categories_path, params: { product_category: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /product_categories/:id/edit" do
    let(:cat) { create(:product_category) }

    it "returns 200" do
      get edit_product_category_path(cat)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /product_categories/:id" do
    let(:cat) { create(:product_category) }

    it "updates and redirects" do
      patch product_category_path(cat), params: { product_category: { name: "Updated" } }
      expect(response).to redirect_to(product_categories_path)
      expect(cat.reload.name).to eq("Updated")
    end
  end

  describe "DELETE /product_categories/:id" do
    let(:cat) { create(:product_category) }

    it "destroys and redirects" do
      delete product_category_path(cat)
      expect(response).to redirect_to(product_categories_path)
    end
  end
end
