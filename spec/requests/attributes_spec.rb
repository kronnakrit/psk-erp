# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Attributes", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_attributes add_attributes change_attributes delete_attributes
           ])
  end
  let(:user) { create(:user) }
  let!(:product_class) { create(:product_class, name: "Clothing") }
  let!(:attribute) { create(:attribute, name: "Color", product_class: product_class) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /product_classes/:product_class_id/attributes" do
    it "returns 200 and lists attributes" do
      get product_class_attributes_path(product_class)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Color")
    end
  end

  describe "POST /product_classes/:product_class_id/attributes" do
    it "creates attribute scoped to product_class" do
      expect do
        post product_class_attributes_path(product_class),
             params: { attribute: { name: "Size" } }
      end.to change(Attribute, :count).by(1)
      expect(response).to redirect_to(product_class_attributes_path(product_class))
    end

    it "rejects duplicate name within same product class" do
      post product_class_attributes_path(product_class),
           params: { attribute: { name: "Color" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /product_classes/:product_class_id/attributes/:id" do
    it "updates and redirects" do
      patch product_class_attribute_path(product_class, attribute),
            params: { attribute: { name: "Pattern" } }
      expect(response).to redirect_to(product_class_attributes_path(product_class))
      expect(attribute.reload.name).to eq("Pattern")
    end
  end

  describe "DELETE /product_classes/:product_class_id/attributes/:id" do
    it "deletes the attribute" do
      expect do
        delete product_class_attribute_path(product_class, attribute)
      end.to change(Attribute, :count).by(-1)
    end
  end
end
