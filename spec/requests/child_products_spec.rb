# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Child Products (web)", type: :request do
  let(:admin_role)    { create(:role, :admin) }
  let(:admin_user)    { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:product_class) { create(:product_class) }
  let(:parent)        { create(:product, :parent, product_class: product_class) }
  let(:child)         { create(:product, :child, parent: parent, product_class: product_class) }

  before { sign_in admin_user }

  describe "PATCH /child_products/:id" do
    it "updates child product and redirects" do
      patch child_product_path(child), params: { product: { name: "Updated Child" } }
      expect(response).to redirect_to(products_path)
      expect(child.reload.name).to eq("Updated Child")
    end

    it "returns 422 json on validation failure" do
      patch child_product_path(child), params: { product: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /child_products/:id" do
    it "destroys child product and redirects" do
      delete child_product_path(child)
      expect(response).to redirect_to(products_path)
      expect(Product.find_by(id: child.id)).to be_nil
    end
  end
end
