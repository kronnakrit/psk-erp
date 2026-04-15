# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkProductImportJob, type: :job do
  include ActiveJob::TestHelper

  let(:admin_role) { create(:role, :admin) }
  let(:user)       { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  def build_upload(xlsx_content)
    upload = Upload.new(user: user, status: "pending")
    upload.file.attach(
      io: StringIO.new(xlsx_content),
      filename: "test.xlsx",
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    upload.save!
    upload
  end

  def minimal_xlsx
    pkg = Axlsx::Package.new
    pkg.workbook.add_worksheet(name: "Test") do |ws|
      ws.add_row(%w[vendor sku brand product_categories product_type barcode name unit price cost description_en
                    description_th])
      ws.add_row(["VendorBroadcast", "BSKUTEST", "BrandBR", "", "Sa", "BC_BRD", "Broadcast Prod", "Pc", "10", "5",
                  "Desc", "คำอธิบาย"])
    end
    pkg.to_stream.read
  end

  before do
    ActiveStorage::Current.url_options = { host: "localhost" }
  end

  describe "Turbo Stream broadcast on job completion" do
    it "broadcasts to the user import status channel" do
      upload = build_upload(minimal_xlsx)
      broadcast_channel = "import_status_#{user.id}"

      expect do
        perform_enqueued_jobs { described_class.perform_later(upload.id) }
      end.to have_broadcasted_to(broadcast_channel)
    end
  end
end
