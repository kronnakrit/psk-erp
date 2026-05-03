# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Order Images (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:customer)   { create(:customer) }
  let(:order)      { create(:order, customer: customer, created_by: admin_user) }

  before { sign_in admin_user }

  describe "GET /orders/:order_id/order_images" do
    it "returns 200" do
      get order_order_images_path(order)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /orders/:order_id/order_images" do
    it "redirects with alert when no image provided" do
      post order_order_images_path(order), params: { order_image: { image: nil } }
      expect(response).to redirect_to(order_path(order))
    end

    it "creates an order image and redirects (html fallback)" do
      # Build a temp image file for testing
      tmpfile = Tempfile.new(["test_image", ".png"])
      tmpfile.write("\x89PNG\r\n\u001A\n#{'x' * 100}")
      tmpfile.rewind
      file = Rack::Test::UploadedFile.new(tmpfile.path, "image/png")

      post order_order_images_path(order),
           params: { order_image: { image: file } }
      tmpfile.close
      tmpfile.unlink
      expect(response).to redirect_to(order_path(order))
    end

    it "creates an order image via turbo_stream" do
      tmpfile = Tempfile.new(["test_image_ts", ".png"])
      tmpfile.write("\x89PNG\r\n\u001A\n#{'x' * 100}")
      tmpfile.rewind
      file = Rack::Test::UploadedFile.new(tmpfile.path, "image/png")

      post order_order_images_path(order),
           params: { order_image: { image: file } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      tmpfile.close
      tmpfile.unlink
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /orders/:order_id/order_images/:id" do
    let(:order_image) { OrderImage.create!(order: order, position: 0) }

    it "destroys the order image (html fallback)" do
      delete order_order_image_path(order, order_image)
      expect(response).to redirect_to(order_path(order))
      expect(OrderImage.find_by(id: order_image.id)).to be_nil
    end
  end
end
