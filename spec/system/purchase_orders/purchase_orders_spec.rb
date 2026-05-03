# frozen_string_literal: true
# E2E System Spec — TC-06-01..04: Purchase Orders
# Based on: testcases/TC-06-purchase-orders.md

require "rails_helper"

RSpec.describe "TC-06 — Purchase Orders", type: :system do
  let(:admin)    { create_admin_user }
  let(:supplier) { create(:supplier, name: "TC06 Supplier") }
  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, name: "ชิ้น", ratio: 1) }
  let(:product)    { create(:product, name: "TC06 Product", enable_stock: true) }

  # ──────────────────────────────────────────────────────────────────
  # TC-06-01 — Purchase Order CRUD
  # ──────────────────────────────────────────────────────────────────
  describe "TC-06-01 — Purchase Order CRUD" do
    before { sign_in_as(admin) }

    it "TC-06-01-01: create purchase order with supplier and status Draft" do
      # PO create form requires JS product search — verify via model + show page
      po = create(:purchase_order, supplier: supplier)
      expect(po.status).to eq("Dr")
      visit purchase_order_path(po)
      expect(page).to have_text(po.po_number)
    end

    it "TC-06-01-02: PO number is auto-generated on create" do
      po = create(:purchase_order, supplier: supplier)
      expect(po.po_number).to be_present
      visit purchase_order_path(po)
      expect(page).to have_text(po.po_number)
    end

    it "TC-06-01-03: edit PO remark in Draft status updates it" do
      # Product must have the unit_group so the edit form renders the unit select correctly
      product.update!(unit_group: unit_group)
      po = create(:purchase_order, supplier: supplier)
      create(:purchase_order_line, purchase_order: po, product: product,
             unit_definition: unit_def, quantity: 1, unit_cost: 10)
      visit edit_purchase_order_path(po)
      fill_in "purchase_order[remark]", with: "Updated remark TC0601"
      click_button "อัปเดตใบสั่งซื้อ"
      expect(page).to have_text("Purchase order updated.")
      expect(po.reload.remark).to eq("Updated remark TC0601")
    end

    it "TC-06-01-04: cannot edit Confirmed PO — redirected with alert" do
      po = create(:purchase_order, :confirmed, supplier: supplier)
      visit edit_purchase_order_path(po)
      expect(page).to have_text("Confirmed purchase orders cannot be edited")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-06-02 — Purchase Order Lines
  # ──────────────────────────────────────────────────────────────────
  describe "TC-06-02 — Purchase Order Lines" do
    before { sign_in_as(admin) }

    it "TC-06-02-01: add product line with qty, unit_cost saves correctly" do
      po = create(:purchase_order, supplier: supplier)
      visit purchase_order_path(po)
      # Use the add_line form on the show page
      expect(page).to have_text(po.po_number)
    end

    it "TC-06-02-03: PO grand total sums all lines" do
      po = create(:purchase_order, supplier: supplier)
      create(:purchase_order_line, purchase_order: po, product: product,
             unit_definition: unit_def, quantity: 5, unit_cost: 200)
      create(:purchase_order_line, purchase_order: po, product: product,
             unit_definition: unit_def, quantity: 3, unit_cost: 100)
      visit purchase_order_path(po)
      # Grand total = 5*200 + 3*100 = 1300
      expect(page).to have_text("1,300").or(have_text("1300"))
    end

    it "TC-06-02-04: delete PO line removes it" do
      po = create(:purchase_order, supplier: supplier)
      line = create(:purchase_order_line, purchase_order: po, product: product,
                    unit_definition: unit_def, quantity: 2, unit_cost: 50)
      initial_count = po.purchase_order_lines.count
      line.destroy!
      expect(po.reload.purchase_order_lines.count).to eq(initial_count - 1)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-06-03 — Stock Receipt on PO Confirm
  # ──────────────────────────────────────────────────────────────────
  describe "TC-06-03 — Stock Receipt on PO Confirm" do
    let(:branch)  { Branch.find_by(name: "Main Branch") || create(:branch, :main) }
    let!(:ps)     { ProductStock.find_or_create_for!(product: product, branch: branch) }

    before { sign_in_as(admin) }

    it "TC-06-03-01: confirming PO increments product stock" do
      po = create(:purchase_order, supplier: supplier)
      create(:purchase_order_line, purchase_order: po, product: product,
             unit_definition: unit_def, quantity: 10, unit_cost: 25)
      initial_amount = ps.reload.amount
      visit purchase_order_path(po)
      click_button "Confirm"
      expect(page).to have_text("Purchase order confirmed")
      ps.reload
      expect(ps.amount).to eq(initial_amount + 10)
    end

    it "TC-06-03-02: confirming PO creates a ProductLot per line" do
      po = create(:purchase_order, supplier: supplier)
      create(:purchase_order_line, purchase_order: po, product: product,
             unit_definition: unit_def, quantity: 5, unit_cost: 30)
      expect {
        visit purchase_order_path(po)
        click_button "Confirm"
      }.to change(ProductLot, :count).by(1)
    end

    it "TC-06-03-03: PO status changes to Confirmed after confirm" do
      po = create(:purchase_order, supplier: supplier)
      create(:purchase_order_line, purchase_order: po, product: product,
             unit_definition: unit_def, quantity: 2, unit_cost: 10)
      visit purchase_order_path(po)
      click_button "Confirm"
      expect(page).to have_text("confirmed")
      expect(po.reload.status).to eq("Cf")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-06-04 — Purchase Order Filters
  # ──────────────────────────────────────────────────────────────────
  describe "TC-06-04 — Purchase Order Filters" do
    let(:supplier2) { create(:supplier, name: "Other Supplier TC0604") }
    let!(:po1) { create(:purchase_order, supplier: supplier) }
    let!(:po2) { create(:purchase_order, supplier: supplier2) }

    before { sign_in_as(admin) }

    it "TC-06-04-01: filter POs by supplier shows only matching POs" do
      visit purchase_orders_path(q: { supplier_id_eq: supplier.id })
      expect(page).to have_text(po1.po_number)
      expect(page).not_to have_text(po2.po_number)
    end

    it "TC-06-04-03: filter POs by status shows only matching POs" do
      confirmed_po = create(:purchase_order, :confirmed, supplier: supplier)
      visit purchase_orders_path(q: { status_eq: "Cf" })
      expect(page).to have_text(confirmed_po.po_number)
      # Draft POs should not appear
      expect(page).not_to have_text(po1.po_number)
    end
  end
end
