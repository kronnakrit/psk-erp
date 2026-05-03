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

  def generate_xlsx(sheets:)
    pkg = Axlsx::Package.new
    sheets.each do |sheet_name, rows|
      pkg.workbook.add_worksheet(name: sheet_name) do |ws|
        rows.each { |row| ws.add_row(row) }
      end
    end
    pkg.to_stream.read
  end

  before do
    ActiveStorage::Current.url_options = { host: "localhost" }
  end

  describe "#perform" do
    context "with a valid xlsx containing standalone products" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Clothing" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th],
                          ["VendorA", "SKU001", "BrandX", "Tops", "Sa", "BC001", "Test Shirt", "Pc", "100", "50",
                           "A shirt", "เสื้อ"]
                        ]
                      })
      end

      it "creates the product and marks upload completed" do
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("completed")
        expect(upload.result_summary["rows_processed"]).to eq(1)
        expect(upload.result_summary["rows_failed"]).to eq(0)
        expect(Product.find_by(sku: "SKU001")).to be_present
        expect(Vendor.find_by(name: "VendorA")).to be_present
        expect(Brand.find_by(name: "BrandX")).to be_present
        expect(ProductCategory.find_by(name: "Tops")).to be_present
      end
    end

    context "with a child row following a parent row" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Toys" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th],
                          ["VendorB", "PARENT01", "BrandY", "Games", "Pr", "BC002", "Parent Toy", "Pc", "200", "100",
                           "A toy", "ของเล่น"],
                          ["", "CHILD01", "", "", "Ch", "BC003", "Red Variant", "Pc", "220", "110", "", ""]
                        ]
                      })
      end

      it "links child to the last parent in the sheet" do
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("completed")
        expect(upload.result_summary["rows_processed"]).to eq(2)

        parent = Product.find_by(sku: "PARENT01")
        child  = Product.find_by(sku: "CHILD01")
        expect(child.parent).to eq(parent)
      end
    end

    context "with attribute columns" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Apparel" => [
                          ["vendor", "sku", "brand", "product_categories", "product_type", "barcode", "name", "unit",
                           "price", "cost", "description_en", "description_th", "attrColor"],
                          ["VendorC", "SKU_ATTR", "BrandZ", "", "Sa", "BC999", "Colored Item", "Pc", "99", "44",
                           "Desc", "คำอธิบาย", "Blue"]
                        ]
                      })
      end

      it "creates a product attribute for the attr column" do
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        product = Product.find_by(sku: "SKU_ATTR")
        expect(product).to be_present
        pa = product.product_attributes.first
        expect(pa).to be_present
        expect(pa.value).to eq("Blue")
      end
    end

    context "with an empty sheet" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Empty" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th]
                        ]
                      })
      end

      it "marks upload completed with 0 processed" do
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("completed")
        expect(upload.result_summary["rows_processed"]).to eq(0)
      end
    end

    context "with an unknown product_type value" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Test" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th],
                          ["V", "BADTYPE", "B", "", "XX", "", "Bad", "Pc", "0", "0", "", ""]
                        ]
                      })
      end

      it "records the row as failed" do
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("completed")
        expect(upload.result_summary["rows_failed"]).to eq(1)
        expect(upload.result_summary["errors"].first).to include("Unknown product_type")
      end
    end

    context "with a child row but no preceding parent" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Test" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th],
                          ["", "ORPHANCH", "", "", "Ch", "", "Orphan", "Pc", "0", "0", "", ""]
                        ]
                      })
      end

      it "records the row as failed with no parent error" do
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.result_summary["rows_failed"]).to eq(1)
        expect(upload.result_summary["errors"].first).to include("No parent product")
      end
    end

    context "when import_row raises a StandardError" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Test" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th],
                          ["VendorD", "SKU_ERR", "BrandA", "", "Sa", "", "Error Row", "Pc", "10", "5", "", ""]
                        ]
                      })
      end

      it "records the row as failed and marks upload completed" do
        allow_any_instance_of(described_class).to receive(:import_row).and_raise(StandardError, "unexpected row error")
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("completed")
        expect(upload.result_summary["rows_failed"]).to eq(1)
        expect(upload.result_summary["errors"].first).to include("unexpected row error")
      end
    end

    context "when a fatal StandardError occurs during processing" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "FatalTest" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th],
                          ["VendorE", "SKU_FATAL", "BrandB", "", "Sa", "", "Fatal Row", "Pc", "10", "5", "", ""]
                        ]
                      })
      end

      it "marks upload as failed with fatal error message" do
        allow(Roo::Spreadsheet).to receive(:open).and_raise(StandardError, "fatal spreadsheet error")
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("failed")
        expect(upload.result_summary["errors"].last).to include("Fatal: fatal spreadsheet error")
      end
    end

    context "when attribute save raises during set_attributes" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "Apparel2" => [
                          ["vendor", "sku", "brand", "product_categories", "product_type", "barcode", "name", "unit",
                           "price", "cost", "description_en", "description_th", "attrSize"],
                          ["VendorF", "SKU_ATTR2", "BrandC", "", "Sa", "BC_A2", "Sized Item", "Pc", "50", "25",
                           "Desc", "คำอธิบาย", "Large"]
                        ]
                      })
      end

      it "skips the attribute error and still marks upload completed" do
        allow_any_instance_of(ProductAttribute).to receive(:save!).and_raise(StandardError, "attr save error")
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("completed")
      end
    end

    context "when broadcast_result raises" do
      let(:xlsx_content) do
        generate_xlsx(sheets: {
                        "BroadcastTest" => [
                          %w[vendor sku brand product_categories product_type barcode name unit price cost
                             description_en description_th],
                          ["VendorG", "SKU_BCAST", "BrandD", "", "Sa", "", "Broadcast Item", "Pc", "10", "5", "", ""]
                        ]
                      })
      end

      it "swallows the broadcast error and still completes" do
        allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to).and_raise(StandardError, "broadcast failed")
        upload = build_upload(xlsx_content)
        perform_enqueued_jobs { described_class.perform_later(upload.id) }

        upload.reload
        expect(upload.status).to eq("completed")
      end
    end
  end
end
