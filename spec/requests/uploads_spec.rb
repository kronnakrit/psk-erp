# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Uploads", type: :request do
  let(:admin_role) { create(:role, permissions: %w[view_uploads add_uploads]) }
  let(:user) { create(:user) }
  let(:xlsx_content) do
    # Minimal valid xlsx binary via RubyXL or a base64 fixture
    file_path = Rails.root.join("spec/fixtures/files/sample_import.xlsx")
    File.exist?(file_path) ? File.binread(file_path) : generate_minimal_xlsx
  end

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /uploads" do
    it "returns 200" do
      get uploads_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /uploads" do
    context "with a valid .xlsx file" do
      let(:xlsx_file) do
        tmp = Tempfile.new(["products", ".xlsx"])
        tmp.binmode
        tmp.write(xlsx_content)
        tmp.rewind
        Rack::Test::UploadedFile.new(tmp, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                                     original_filename: "products.xlsx")
      end

      it "creates an upload record and enqueues job" do
        allow(BulkProductImportJob).to receive(:perform_later)
        expect do
          post uploads_path, params: { upload: { file: xlsx_file } }
        end.to change(Upload, :count).by(1)
        expect(BulkProductImportJob).to have_received(:perform_later)
        expect(response).to redirect_to(uploads_path)
        expect(Upload.last.status).to eq("pending")
      end

      it "redirects with alert when upload fails to save" do
        allow_any_instance_of(Upload).to receive(:save).and_return(false)
        post uploads_path, params: { upload: { file: xlsx_file } }
        expect(response).to redirect_to(uploads_path)
        expect(flash[:alert]).to include("Upload failed")
      end
    end

    context "with an invalid file type" do
      let(:csv_file) do
        Rack::Test::UploadedFile.new(
          StringIO.new("col1,col2\nval1,val2"),
          "text/csv",
          original_filename: "products.csv"
        )
      end

      it "redirects with an alert and does not create an upload" do
        expect do
          post uploads_path, params: { upload: { file: csv_file } }
        end.not_to change(Upload, :count)
        expect(response).to redirect_to(uploads_path)
        expect(flash[:alert]).to include("Only .xlsx files")
      end
    end

    context "when not authenticated" do
      before { sign_out user }

      it "redirects to login" do
        post uploads_path, params: { upload: { file: nil } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  private

  def generate_minimal_xlsx
    require "caxlsx"
    pkg = Axlsx::Package.new
    pkg.workbook.add_worksheet(name: "Sheet1") { |ws| ws.add_row(%w[vendor sku name]) }
    pkg.to_stream.read
  end
end
