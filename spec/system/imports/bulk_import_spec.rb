# frozen_string_literal: true
# E2E System Spec — TC-10-01..03: Bulk Product Import
# Based on: testcases/TC-10-bulk-import.md

require "rails_helper"
require "tmpdir"

RSpec.describe "TC-10 — Bulk Product Import", type: :system do
  let(:admin) { create_admin_user }

  # Helpers for creating temporary test files
  def create_xlsx_file
    path = Rails.root.join("tmp", "test_import_#{SecureRandom.hex(4)}.xlsx")
    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(name: "Products") do |ws|
        ws.add_row %w[sku name price barcode vendor brand product_class product_type]
        ws.add_row ["TC-001", "Test Product A", "100", "123456789", "", "", "", "Sa"]
      end
      p.serialize(path.to_s)
    end
    path.to_s
  end

  def create_csv_file
    path = Rails.root.join("tmp", "test_import_#{SecureRandom.hex(4)}.csv")
    File.write(path, "sku,name,price\nTC-001,Product A,100")
    path.to_s
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-10-01 — File Upload Validation
  # ──────────────────────────────────────────────────────────────────
  describe "TC-10-01 — File Upload Validation" do
    before { sign_in_as(admin) }

    after do
      # Clean up temp files
      Dir.glob(Rails.root.join("tmp", "test_import_*.{xlsx,csv,xls}")).each do |f|
        File.delete(f) if File.exist?(f)
      end
    end

    it "TC-10-01-01: upload valid .xlsx file succeeds with flash notice" do
      xlsx_path = create_xlsx_file
      visit uploads_path
      attach_file("upload[file]", xlsx_path)
      click_button "Upload & Import"
      expect(page).to have_text("File uploaded. Import is processing.")
    end

    it "TC-10-01-02: upload .csv file is rejected" do
      csv_path = create_csv_file
      visit uploads_path
      attach_file("upload[file]", csv_path)
      click_button "Upload & Import"
      expect(page).to have_text("Only .xlsx files are accepted.")
    end

    it "TC-10-01-04: submit without selecting file is rejected" do
      visit uploads_path
      click_button "Upload & Import"
      expect(page).to have_text("Only .xlsx files are accepted.")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-10-02 — Import Job Processing
  # ──────────────────────────────────────────────────────────────────
  describe "TC-10-02 — Import Job Processing" do
    before { sign_in_as(admin) }

    after do
      Dir.glob(Rails.root.join("tmp", "test_import_*.xlsx")).each do |f|
        File.delete(f) if File.exist?(f)
      end
    end

    it "TC-10-02-01: SolidQueue job is enqueued after successful upload" do
      xlsx_path = create_xlsx_file
      visit uploads_path
      attach_file("upload[file]", xlsx_path)
      expect {
        click_button "Upload & Import"
      }.to have_enqueued_job(BulkProductImportJob)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-10-03 — Real-time Import Notification
  # (Turbo Stream / ActionCable — requires JS)
  # ──────────────────────────────────────────────────────────────────
  describe "TC-10-03 — Real-time Import Notification" do
    it "TC-10-03-01: Turbo Stream notification on job completion — not tested in system spec" do
      skip "ActionCable integration tested at unit level; Turbo Stream broadcast requires async infra"
    end

    it "TC-10-03-02: ImportNotificationsChannel subscription active — not tested in system spec" do
      skip "WebSocket channel subscription verified in integration/channel specs"
    end

    it "TC-10-03-03: notification shows success count — not tested in system spec" do
      skip "Broadcast notification tested at unit level"
    end

    it "TC-10-03-04: notification shows error count — not tested in system spec" do
      skip "Broadcast notification tested at unit level"
    end
  end
end
