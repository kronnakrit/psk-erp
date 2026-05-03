# frozen_string_literal: true
# E2E System Spec — TC-09-01..03: Reports & Excel Export
# Based on: testcases/TC-09-reports-exports.md

require "rails_helper"

RSpec.describe "TC-09 — Reports & Excel Export", type: :system do
  let(:admin)    { create_admin_user }
  let(:customer) { create(:customer) }
  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, ratio: 1) }
  let(:product)    { create(:product) }
  let(:order) do
    o = create(:order, customer: customer, created_by: admin)
    create(:order_line, order: o, product: product, unit_definition: unit_def)
    o
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-09-01 — Order Reports
  # ──────────────────────────────────────────────────────────────────
  describe "TC-09-01 — Order Reports" do
    it "TC-09-01-01: export single order returns xlsx content-type" do
      order # ensure created
      sign_in_as(admin)
      visit export_order_path(order)
      expect(page.response_headers["Content-Type"]).to include(
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )
    end

    it "TC-09-01-03: export requires view_orders permission" do
      order
      limited = create_limited_user
      sign_in_as(limited)
      visit export_order_path(order)
      expect(page).to have_text("403").or(have_text("Forbidden")).or(have_text("ไม่มีสิทธิ์"))
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-09-02 — Stock Reports
  # (Excel export for stocks not yet implemented in application)
  # ──────────────────────────────────────────────────────────────────
  describe "TC-09-02 — Stock Reports" do
    it "TC-09-02-01: stock excel export — not yet implemented" do
      skip "Stock bulk excel export not implemented in application"
    end

    it "TC-09-02-02: stock transactions export — not yet implemented" do
      skip "Stock transactions export not implemented in application"
    end

    it "TC-09-02-03: stock export columns — not yet implemented" do
      skip "Stock bulk excel export not implemented in application"
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-09-03 — Purchase Order Reports
  # (Excel export for POs not yet implemented in application)
  # ──────────────────────────────────────────────────────────────────
  describe "TC-09-03 — Purchase Order Reports" do
    it "TC-09-03-01: PO excel export — not yet implemented" do
      skip "PO bulk excel export not implemented in application"
    end

    it "TC-09-03-02: PO lines export — not yet implemented" do
      skip "PO detail excel export not implemented in application"
    end
  end
end
