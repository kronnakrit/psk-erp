# frozen_string_literal: true
# E2E System Spec — TC-11-01..03: Invoices
# Based on: testcases/TC-11-invoices.md

require "rails_helper"

RSpec.describe "TC-11 — Invoices", type: :system do
  let(:admin)    { create_admin_user }
  let(:customer) { create(:customer, first_name: "TC11", last_name: "Customer") }
  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, ratio: 1) }
  let(:product)    { create(:product, price: 500) }

  def create_paid_order(cust = customer)
    o = create(:order, :paid, customer: cust, created_by: admin, grand_total: 1_000)
    create(:order_line, order: o, product: product, unit_definition: unit_def,
           quantity: 2, unit_price: 500)
    o
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-11-01 — Invoice CRUD
  # ──────────────────────────────────────────────────────────────────
  describe "TC-11-01 — Invoice CRUD" do
    before { sign_in_as(admin) }

    it "TC-11-01-01: create invoice by selecting orders", js: true do
      order = create_paid_order
      visit new_invoice_path
      # Check the order checkbox
      find("[data-testid='order-checkbox-#{order.id}']").check
      # Click Create Invoice → opens preview modal
      find("[data-testid='create-invoice-btn']").click
      # Wait for modal to appear
      find("[data-testid='invoice-preview-modal']", wait: 5)
      # Click Confirm — submits form, Turbo redirects to invoices list
      find("[data-testid='preview-confirm-btn']").click
      # Verify redirect to invoice list and invoice was created
      expect(page).to have_current_path(invoices_path, wait: 8, ignore_query: true)
      inv = Invoice.last
      expect(inv).to be_present
      expect(inv.invoice_orders.pluck(:order_id)).to include(order.id)
    end

    it "TC-11-01-02: invoice number is auto-generated and unique" do
      inv = create(:invoice, customer: customer, created_by: admin)
      expect(inv.invoice_number).to be_present

      # Attempt to create another invoice with same invoice_number
      dup = Invoice.new(
        customer: customer,
        invoice_date: Date.current,
        invoice_number: inv.invoice_number,
        status: "Dr"
      )
      expect(dup).not_to be_valid
      expect(dup.errors[:invoice_number]).to include("has already been taken")
    end

    it "TC-11-01-03: edit invoice remark updates it" do
      inv = create(:invoice, customer: customer, created_by: admin)
      visit edit_invoice_path(inv)
      fill_in "invoice_remark", with: "Updated remark TC11"
      click_button "Save"
      expect(page).to have_text("Invoice updated")
      expect(inv.reload.remark).to eq("Updated remark TC11")
    end

    it "TC-11-01-04: cancel invoice removes it from active list" do
      inv = create(:invoice, customer: customer, created_by: admin)
      visit invoice_path(inv)
      click_button "Cancel Invoice"
      expect(page).to have_text("Invoice cancelled")
      expect(inv.reload.status).to eq("Cc")
    end

    it "TC-11-01-05: invoice list is paginated" do
      # Creates enough invoices to trigger pagination (Pagy default = 20 per page)
      22.times { create(:invoice, customer: customer, created_by: admin) }
      visit invoices_path
      # Pagy series_nav renders <nav class="pagy series-nav" aria-label="...">
      expect(page).to have_css("nav.pagy")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-11-02 — Invoice Orders (Linking Orders to Invoice)
  # ──────────────────────────────────────────────────────────────────
  describe "TC-11-02 — Invoice Orders" do
    let(:invoice) { create(:invoice, customer: customer, created_by: admin) }

    before { sign_in_as(admin) }

    it "TC-11-02-01: link order to invoice via add_orders page" do
      order = create_paid_order
      visit add_orders_invoice_path(invoice)
      find("[data-testid='add-order-checkbox-#{order.id}']").check
      click_button "Add Selected Orders"
      expect(page).to have_text("order(s) added to invoice")
      expect(invoice.reload.orders).to include(order)
    end

    it "TC-11-02-02: invoice total equals sum of linked orders grand_totals" do
      order1 = create_paid_order
      order2 = create_paid_order
      invoice.invoice_orders.create!(order: order1)
      invoice.invoice_orders.create!(order: order2)
      invoice.recalculate_total!

      visit invoice_path(invoice)
      expect(invoice.reload.total_amount).to eq(order1.grand_total + order2.grand_total)
    end

    it "TC-11-02-03: remove order link destroys InvoiceOrder record" do
      order1 = create_paid_order
      order2 = create_paid_order
      invoice.invoice_orders.create!(order: order1)
      invoice.invoice_orders.create!(order: order2)
      invoice.recalculate_total!

      initial_count = invoice.invoice_orders.count # 2
      visit invoice_path(invoice)

      # button_to with method: :delete — controller guard requires ≥2 orders
      # rack_test submits the hidden _method=delete form directly, turbo_confirm ignored
      # use data-testid to target the specific order's Remove button
      find("button[data-testid='remove-order-#{order1.id}']").click
      expect(invoice.reload.invoice_orders.count).to eq(initial_count - 1)
    end

    it "TC-11-02-04: same order cannot be linked to same invoice twice" do
      order = create_paid_order
      invoice.invoice_orders.create!(order: order)
      invoice.recalculate_total!

      # Attempt to link the same order again via add_orders page
      visit add_orders_invoice_path(invoice)
      # order should not appear as eligible (already on this non-cancelled invoice)
      # scope to the table body to avoid matching the invoice number in the page title
      expect(page).to have_text("No eligible orders for this customer.")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-11-03 — Invoice Images (Receipts)
  # ──────────────────────────────────────────────────────────────────
  describe "TC-11-03 — Invoice Images" do
    let(:invoice) { create(:invoice, customer: customer, created_by: admin) }

    before { sign_in_as(admin) }

    it "TC-11-03-01: upload invoice image attaches to invoice" do
      image_path = Rails.root.join("spec/fixtures/test_image.png")
      # Create a minimal PNG fixture if it doesn't exist
      unless File.exist?(image_path)
        File.binwrite(
          image_path,
          "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02" \
          "\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00" \
          "\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82"
        )
      end

      visit invoice_path(invoice)
      attach_file("invoice_image[image]", image_path)
      click_button "Upload"
      expect(page).to have_text("Image uploaded.")
      expect(invoice.reload.invoice_images.count).to eq(1)
    end

    it "TC-11-03-03: delete invoice image removes it" do
      image_path = Rails.root.join("spec/fixtures/test_image.png")
      unless File.exist?(image_path)
        File.binwrite(
          image_path,
          "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02" \
          "\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00" \
          "\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82"
        )
      end

      img = invoice.invoice_images.create!
      img.image.attach(
        io: File.open(image_path),
        filename: "test_image.png",
        content_type: "image/png"
      )

      initial_count = invoice.invoice_images.count
      visit invoice_path(invoice)

      within("#invoice_image_#{img.id}") do
        click_button "✕"
      end
      expect(invoice.reload.invoice_images.count).to eq(initial_count - 1)
    end

    it "TC-11-03-04: non-image file upload is rejected" do
      skip "File type validation for invoice images not implemented — accept='image/*' is client-side only"
    end
  end
end
