# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoice Images (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:customer)   { create(:customer) }
  let(:invoice)    { create(:invoice, customer: customer, created_by: admin_user) }

  before { sign_in admin_user }

  describe "POST /invoices/:invoice_id/invoice_images" do
    context "when no image is provided" do
      it "redirects with alert" do
        post invoice_invoice_images_path(invoice), params: { invoice_image: { image: nil } }
        expect(response).to redirect_to(invoice_path(invoice))
      end
    end

    context "when a valid image is provided" do
      it "creates an invoice image and redirects" do
        tmpfile = Tempfile.new(["test_image", ".png"])
        tmpfile.write("\x89PNG\r\n\u001A\n" + ("x" * 100))
        tmpfile.rewind
        file = Rack::Test::UploadedFile.new(tmpfile.path, "image/png")

        post invoice_invoice_images_path(invoice),
             params: { invoice_image: { image: file } }
        tmpfile.close
        tmpfile.unlink
        expect(response).to redirect_to(invoice_path(invoice))
      end

      it "creates an invoice image via turbo_stream" do
        tmpfile = Tempfile.new(["test_image_ts", ".png"])
        tmpfile.write("\x89PNG\r\n\u001A\n" + ("x" * 100))
        tmpfile.rewind
        file = Rack::Test::UploadedFile.new(tmpfile.path, "image/png")

        post invoice_invoice_images_path(invoice),
             params: { invoice_image: { image: file } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        tmpfile.close
        tmpfile.unlink
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE /invoices/:invoice_id/invoice_images/:id" do
    let(:invoice_image) { InvoiceImage.create!(invoice: invoice) }

    it "destroys the invoice image and redirects" do
      delete invoice_invoice_image_path(invoice, invoice_image)
      expect(response).to redirect_to(invoice_path(invoice))
      expect(InvoiceImage.find_by(id: invoice_image.id)).to be_nil
    end
  end
end
