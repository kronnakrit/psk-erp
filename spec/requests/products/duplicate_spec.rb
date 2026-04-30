# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /products/:id/duplicate", type: :request do
  let(:product) { create(:product) }

  context "when user lacks add_products permission (AC-05)" do
    let(:role) { create(:role, permissions: %w[view_products]) }
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role)
      sign_in user
      product # ensure product exists before each example
    end

    it "is denied (redirects with not_authorized flash)" do
      post duplicate_product_path(product)
      expect(response).to have_http_status(:found)
      expect(flash[:alert]).to be_present
    end

    it "does not create a new product" do
      expect {
        post duplicate_product_path(product)
      }.not_to change(Product, :count)
    end
  end

  context "when user has add_products permission" do
    let(:role) { create(:role, permissions: %w[view_products add_products change_products]) }
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role)
      sign_in user
      product # ensure product exists before change block
    end

    it "creates a duplicate and redirects to edit page" do
      expect {
        post duplicate_product_path(product)
      }.to change(Product, :count).by(1)
      expect(response).to redirect_to(edit_product_path(Product.last))
    end

    it "prefixes the name with 'Copy of'" do
      post duplicate_product_path(product)
      expect(Product.last.name).to eq("Copy of #{product.name}")
    end
  end
end
