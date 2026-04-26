# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Products form labels i18n", type: :request do
  let(:role) { create(:role, permissions: %w[view_products add_products change_products]) }
  let(:user) { create(:user) }

  describe "TH user visiting GET /products/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_product_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ชื่อสินค้า as Name label" do
      expect(response.body).to include("ชื่อสินค้า")
    end

    it "renders ข้อมูลสินค้า as Product Information section heading" do
      expect(response.body).to include("ข้อมูลสินค้า")
    end

    it "renders ราคา as Pricing section heading" do
      expect(response.body).to include("ราคา")
    end

    it "renders เพิ่มสินค้า as submit button" do
      expect(response.body).to include("เพิ่มสินค้า")
    end
  end

  describe "EN user visiting GET /products/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_product_path
    end

    it "renders Name as name label" do
      expect(response.body).to include("Name")
    end

    it "renders Product Information as section heading" do
      expect(response.body).to include("Product Information")
    end

    it "renders Create Product as submit button" do
      expect(response.body).to include("Create Product")
    end
  end
end
