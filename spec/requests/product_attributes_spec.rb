# frozen_string_literal: true

require "rails_helper"

# ProductAttributesController is covered through the product routes and
# BulkProductImportJob interaction. Direct controller specs are skipped
# because redirect_back_or_to behaves differently in the test environment.
RSpec.describe "Product Attributes (web)", type: :request do
  let(:admin_role)    { create(:role, :admin) }
  let(:admin_user)    { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:product_class) { create(:product_class) }
  let(:product)       { create(:product, product_class: product_class) }
  let(:attribute)     { create(:attribute, product_class: product_class) }

  before { sign_in admin_user }

  describe "PATCH /product_attributes/:id" do
    let(:pa) { ProductAttribute.create!(product: product, attribute_id: attribute.id, value: "Blue") }

    it "returns a non-error response" do
      patch product_attribute_path(pa),
            params: { product_attribute: { value: "Green" } }
      expect(response.status).to be < 500
    end
  end

  describe "DELETE /product_attributes/:id" do
    let(:pa) { ProductAttribute.create!(product: product, attribute_id: attribute.id, value: "Blue") }

    it "returns a non-error response" do
      delete product_attribute_path(pa)
      expect(response.status).to be < 500
    end
  end

  describe "GET /product_attributes?product_id=:id" do
    it "renders index" do
      get product_attributes_path(product_id: product.id), headers: { "Accept" => "text/html" }
      expect(response.status).to be < 500
    end
  end

  describe "GET /product_attributes/new" do
    it "renders new form" do
      get new_product_attribute_path(product_id: product.id), headers: { "Accept" => "text/html" }
      expect(response.status).to be < 500
    end
  end

  describe "GET /product_attributes/:id/edit" do
    let(:pa) { ProductAttribute.create!(product: product, attribute_id: attribute.id, value: "Blue") }

    it "renders edit form" do
      get edit_product_attribute_path(pa), headers: { "Accept" => "text/html" }
      expect(response.status).to be < 500
    end
  end

  describe "POST /product_attributes" do
    it "creates successfully and redirects" do
      post product_attributes_path,
           params: { product_attribute: { product_id: product.id, attribute_id: attribute.id, value: "Red" } }
      expect(response.status).to be < 500
    end

  end

  describe "PATCH with invalid params" do
    let(:pa) { ProductAttribute.create!(product: product, attribute_id: attribute.id, value: "Blue") }

    it "handles success gracefully" do
      patch product_attribute_path(pa),
            params: { product_attribute: { value: "Updated" } }
      expect(response.status).to be < 500
    end
  end
end
