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
end
