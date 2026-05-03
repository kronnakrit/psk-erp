# frozen_string_literal: true
# E2E System Spec — TC-12-01/02/03: Delivery Order Print
# Based on: testcases/TC-12-delivery-order.md

require "rails_helper"

RSpec.describe "TC-12 — Delivery Order Print", type: :system do
  let(:admin)    { create_admin_user }
  let(:customer) { create(:customer, first_name: "สมชาย", last_name: "ใจดี") }
  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, name: "ชิ้น", ratio: 1) }
  let(:product)  { create(:product, name: "สินค้า A", price: 500) }
  let(:order) do
    create(:order,
           customer: customer,
           address: "123 ถนนพระราม 9",
           remark: "หมายเหตุสาธารณะ",
           internal_note: "NOTE_INTERNAL_SECRET",
           created_by: admin)
  end
  let!(:line1) { create(:order_line, order: order, product: product, unit_definition: unit_def, quantity: 3, unit_price: 500) }
  let!(:line2) { create(:order_line, order: order, product: product, unit_definition: unit_def, quantity: 1, unit_price: 200) }
  let!(:line3) { create(:order_line, order: order, product: product, unit_definition: unit_def, quantity: 2, unit_price: 300) }

  # ──────────────────────────────────────────────────────────────────
  # TC-12-01 — Access Control
  # ──────────────────────────────────────────────────────────────────
  describe "TC-12-01 — Access Control" do
    it "TC-12-01-01: delivery order requires authentication" do
      visit delivery_order_order_path(order)
      expect(page).to have_current_path("/login", ignore_query: true)
    end

    it "TC-12-01-02: delivery order requires view_orders permission" do
      limited = create_limited_user
      sign_in_as(limited)
      visit delivery_order_order_path(order)
      expect(page).to have_text("403").or(have_text("ไม่มีสิทธิ์")).or(have_text("Forbidden"))
    end

    it "TC-12-01-03: non-existent order returns 404" do
      sign_in_as(admin)
      visit delivery_order_order_path(id: 999_999)
      expect(page).to have_text("404").or(have_text("Not Found")).or(have_text("ไม่พบ"))
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-12-02 — Layout Content
  # ──────────────────────────────────────────────────────────────────
  describe "TC-12-02 — Layout Content" do
    before { sign_in_as(admin) }

    it "TC-12-02-01: page title contains order number" do
      visit delivery_order_order_path(order)
      expect(page).to have_title("บิลขนส่ง – #{order.order_number}")
    end

    it "TC-12-02-02: barcode SVG element present with order number" do
      visit delivery_order_order_path(order)
      expect(page).to have_css("svg[data-delivery-order-target='barcode']")
      expect(page).to have_css("svg[data-order-number='#{order.order_number}']")
    end

    it "TC-12-02-03: order number displayed below barcode" do
      visit delivery_order_order_path(order)
      expect(page).to have_text(order.order_number)
    end

    it "TC-12-02-04: customer name and address displayed" do
      visit delivery_order_order_path(order)
      expect(page).to have_text(customer.fullname)
      expect(page).to have_text("123 ถนนพระราม 9")
    end

    it "TC-12-02-05: order date displayed" do
      visit delivery_order_order_path(order)
      formatted_date = order.running_date.strftime("%d/%m/%Y")
      expect(page).to have_text(formatted_date)
    end

    it "TC-12-02-06: table has 7 columns with Thai headers" do
      visit delivery_order_order_path(order)
      expect(page).to have_css("th", text: "NO.")
      expect(page).to have_css("th", text: "จำนวน")
      expect(page).to have_css("th", text: "หน่วย")
      expect(page).to have_css("th", text: "รายละเอียด")
      expect(page).to have_css("th", text: "ราคาต่อหน่วย")
      expect(page).to have_css("th", text: "รวม")
      expect(page).to have_css("thead tr th", count: 7)
    end

    it "TC-12-02-07: each order line rendered as table row" do
      visit delivery_order_order_path(order)
      expect(page).to have_css("tbody tr", count: 3)
    end

    it "TC-12-02-08: internal_note excluded from HTML" do
      visit delivery_order_order_path(order)
      expect(page.html).not_to include("NOTE_INTERNAL_SECRET")
    end

    it "TC-12-02-09: remark (public note) included" do
      visit delivery_order_order_path(order)
      expect(page).to have_text("หมายเหตุสาธารณะ")
    end

    it "TC-12-02-10: grand total section present" do
      visit delivery_order_order_path(order)
      expect(page).to have_text("รวมทั้งสิ้น")
    end

    it "TC-12-02-11: signature section present" do
      visit delivery_order_order_path(order)
      expect(page).to have_text("ลงชื่อ")
      expect(page).to have_text("ผู้รับของ")
    end

    it "TC-12-02-12: no sidebar or navigation" do
      visit delivery_order_order_path(order)
      expect(page).not_to have_css("nav")
      expect(page).not_to have_css("[data-controller='sidebar']")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-12-03 — Print Settings
  # ──────────────────────────────────────────────────────────────────
  describe "TC-12-03 — Print Settings" do
    before { sign_in_as(admin) }

    it "TC-12-03-01: A4 is the default selected paper size", js: true do
      visit delivery_order_order_path(order)
      # A4 radio button is checked by default; Stimulus connect() also injects @page style
      expect(page).to have_checked_field("paper_size", with: "A4", wait: 5)
    end

    it "TC-12-03-02: A5 radio button present" do
      visit delivery_order_order_path(order)
      expect(page).to have_css("input[type='radio'][value='A5']")
    end

    it "TC-12-03-03: print button (พิมพ์) present" do
      visit delivery_order_order_path(order)
      expect(page).to have_button("พิมพ์")
    end

    it "TC-12-03-04: print controls have no-print class (hidden in print view)" do
      visit delivery_order_order_path(order)
      expect(page).to have_css(".no-print")
    end
  end
end
