# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ProductImages", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_products view_product_images add_product_images delete_product_images
           ])
  end
  let(:user)    { create(:user) }
  let(:product) { create(:product) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /products/:product_id/product_images" do
    it "returns 200" do
      get product_product_images_path(product)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /products/:product_id/product_images" do
    it "creates a product image record" do
      image_file = Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/test_image.png"),
        "image/png"
      )
      expect do
        post product_product_images_path(product),
             params: { product_image: { image: image_file } }
      end.to change { product.product_images.count }.by(1)
    end
  end

  describe "DELETE /products/:product_id/product_images/:id" do
    it "destroys the product image record" do
      product_image = create(:product_image, product: product)
      expect do
        delete product_product_image_path(product, product_image)
      end.to change { product.product_images.count }.by(-1)
      expect(response).to redirect_to(product_product_images_path(product))
    end
  end
end
