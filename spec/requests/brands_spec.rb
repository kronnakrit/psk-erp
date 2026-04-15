# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Brands", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_brands add_brands change_brands delete_brands
           ])
  end
  let(:user) { create(:user) }
  let!(:brand) { create(:brand, name: "Cool Brand") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /brands" do
    it "returns 200" do
      get brands_path
      expect(response).to have_http_status(:ok)
    end

    it "lists brands" do
      get brands_path
      expect(response.body).to include("Cool Brand")
    end
  end

  describe "GET /brands/new" do
    it "returns 200" do
      get new_brand_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /brands" do
    let(:valid_attrs) { { name: "New Brand", description: "A cool brand", remark: "" } }

    it "creates and redirects" do
      expect do
        post brands_path, params: { brand: valid_attrs }
      end.to change(Brand, :count).by(1)
      expect(response).to redirect_to(brands_path)
    end

    it "renders new on invalid data" do
      post brands_path, params: { brand: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /brands/:id" do
    it "updates and redirects" do
      patch brand_path(brand), params: { brand: { name: "Updated Brand" } }
      expect(response).to redirect_to(brands_path)
      expect(brand.reload.name).to eq("Updated Brand")
    end
  end

  describe "DELETE /brands/:id" do
    it "deletes the brand" do
      expect do
        delete brand_path(brand)
      end.to change(Brand, :count).by(-1)
      expect(response).to redirect_to(brands_path)
    end
  end
end
