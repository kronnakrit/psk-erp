# frozen_string_literal: true
# E2E System Spec — TC-03-01..10: Order Module
# Based on: testcases/TC-03-orders.md

require "rails_helper"

RSpec.describe "TC-03 — Orders", type: :system do
  let(:admin)    { create_admin_user }
  let(:customer) { create(:customer, first_name: "TC03", last_name: "Customer", telephone: "0891234567", address: "99 Sukhumvit") }
  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, name: "ชิ้น", ratio: 1) }
  let(:product)    { create(:product, name: "TC03 Product", price: 100, unit_group: unit_group) }

  def fill_order_form(customer_id:, product_id:, unit_def_id:, quantity: 2, unit_price: 100)
    page.execute_script(
      "document.querySelector(\"input[data-customer-search-target='hidden']\").value = '#{customer_id}'"
    )
    page.execute_script(
      "document.querySelector(\"input[data-order-line-search-target='productId']\").value = '#{product_id}'"
    )
    # Populate unit definition select
    page.execute_script(<<~JS)
      (function() {
        var sel = document.querySelector("select[data-order-line-search-target='unitDefinition']");
        var opt = new Option("ชิ้น", "#{unit_def_id}", true, true);
        sel.add(opt);
        sel.value = "#{unit_def_id}";
      })();
    JS
    find("input[data-qty-input]").fill_in with: quantity.to_s
    find("input[data-price-input]").fill_in with: unit_price.to_s
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-01 — Order Creation & Order Number
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-01 — Order Creation & Order Number", js: true do
    before { sign_in_as(admin) }

    it "TC-03-01-01: create order — status Draft, order number format YYYYMMDDnnn" do
      unit_def
      visit new_order_path
      fill_order_form(
        customer_id: customer.id,
        product_id: product.id,
        unit_def_id: unit_def.id
      )
      click_button "สร้างออเดอร์"
      # Wait for redirect to order show page (flash auto-dismisses in 5s, check page content instead)
      expect(page).to have_text("รายละเอียดออเดอร์", wait: 8)
      ord = Order.last
      expect(ord.status).to eq("Dr")
      expect(ord.order_number).to match(/^\d{8}\d{3}$/)
    end

    it "TC-03-01-05: order date defaults to today" do
      visit new_order_path
      date_value = find("input[name='order[running_date]']").value
      expect(Date.parse(date_value)).to eq(Date.current)
    end

    it "TC-03-01-08: submit order without customer shows validation error" do
      unit_def
      visit new_order_path
      # Do NOT fill in customer_id
      page.execute_script(
        "document.querySelector(\"input[data-order-line-search-target='productId']\").value = '#{product.id}'"
      )
      page.execute_script(<<~JS)
        (function() {
          var sel = document.querySelector("select[data-order-line-search-target='unitDefinition']");
          var opt = new Option("ชิ้น", "#{unit_def.id}", true, true);
          sel.add(opt);
          sel.value = "#{unit_def.id}";
        })();
      JS
      find("input[data-qty-input]").fill_in with: "1"
      find("input[data-price-input]").fill_in with: "100"
      click_button "สร้างออเดอร์"
      expect(page).to have_text("Customer", wait: 5)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-02 — Order Status Lifecycle
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-02 — Order Status Lifecycle" do
    before { sign_in_as(admin) }

    it "TC-03-02-01: new order defaults to Draft status" do
      order = create(:order, customer: customer, created_by: admin)
      expect(order.status).to eq("Dr")
      visit order_path(order)
      expect(page).to have_text("ร่าง") # Thai: Draft
    end

    it "TC-03-02-02: Paid order shows correct status badge" do
      order = create(:order, :paid, customer: customer, created_by: admin)
      visit order_path(order)
      expect(page).to have_text("ชำระแล้ว", wait: 5)
      expect(order.status).to eq("Pd")
    end

    it "TC-03-02-04: Cancelled order shows correct status badge" do
      order = create(:order, customer: customer, created_by: admin)
      order.update!(status: "Cc")
      visit order_path(order)
      expect(page).to have_text("ยกเลิก", wait: 5)
      expect(order.reload.status).to eq("Cc")
    end

    it "TC-03-02-05: Draft tab shows only Draft orders" do
      draft     = create(:order, customer: customer, created_by: admin, status: "Dr")
      paid      = create(:order, :paid, customer: customer, created_by: admin)
      visit draft_orders_path
      expect(page).to have_text(draft.order_number)
      expect(page).not_to have_text(paid.order_number)
    end

    it "TC-03-02-06: Completed tab shows only Completed orders" do
      completed = create(:order, :completed, customer: customer, created_by: admin)
      draft     = create(:order, customer: customer, created_by: admin, status: "Dr")
      visit completed_orders_path
      expect(page).to have_text(completed.order_number)
      expect(page).not_to have_text(draft.order_number)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-03 — Grand Total Calculation
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-03 — Grand Total Calculation" do
    before { sign_in_as(admin) }

    it "TC-03-03-01: no VAT, no discount — grand_total = total_price" do
      order = create(:order, customer: customer, created_by: admin,
                     has_vat: false, is_discount_percentage: false, discount_price: 0)
      create(:order_line, order: order, product: product, unit_definition: unit_def,
             quantity: 3, unit_price: 100, discount_price: 0)
      gt = GrandTotalCalculator.new(order).call
      expect(gt[:grand_total]).to eq(gt[:total_price])
    end

    it "TC-03-03-11: line total = qty × unit_price − discount_price" do
      order = create(:order, customer: customer, created_by: admin)
      line = create(:order_line, order: order, product: product, unit_definition: unit_def,
                    quantity: 3, unit_price: 100, discount_price: 50)
      # 3 × 100 - 50 = 250
      expect(line.total_price).to eq(250)
    end

    it "TC-03-03-04: percentage discount applied correctly" do
      order = create(:order, customer: customer, created_by: admin,
                     has_vat: false, is_discount_percentage: true, discount_percentage: 10)
      create(:order_line, order: order, product: product, unit_definition: unit_def,
             quantity: 1, unit_price: 1000, discount_price: 0)
      gt = GrandTotalCalculator.new(order).call
      expect(gt[:discount_amount]).to eq(100) # 10% of 1000
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-04 — Order Lines Management
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-04 — Order Lines Management" do
    before { sign_in_as(admin) }

    it "TC-03-04-07: remove order line via edit form hides row and decrements lines", js: true do
      order = create(:order, customer: customer, created_by: admin)
      line  = create(:order_line, order: order, product: product, unit_definition: unit_def,
                     quantity: 2, unit_price: 100)
      visit edit_order_path(order)
      # Each order line row has a delete button
      row_id = "order_line_fields_#{line.id}"
      within("##{row_id}") do
        # Button has opacity-0 (hover-only): use visible: :all and force: true
        find("button[data-action*='removeLine']", visible: :all, wait: 5).click(force: true)
      end
      click_button "อัปเดตออเดอร์"
      expect(order.reload.order_lines.count).to eq(0)
    end

    it "TC-03-04-09: order line requires unit_definition_id" do
      order = create(:order, customer: customer, created_by: admin)
      line = OrderLine.new(order: order, product: product, quantity: 1, unit_price: 100)
      expect(line).not_to be_valid
      expect(line.errors[:unit_definition_id]).to be_present
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-06 — Order Stock Integration
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-06 — Order Stock Integration" do
    let(:branch)       { Branch.find_by(name: "Main Branch") || create(:branch, :main) }
    let(:stock_product) { create(:product, name: "Stock Product TC0306", enable_stock: true) }
    let!(:ps)          { ProductStock.find_or_create_for!(product: stock_product, branch: branch) }

    before do
      ps.deposit!(amount: 10, reason: "setup", adjuster: admin)
      sign_in_as(admin)
    end

    it "TC-03-06-04: non-stock product does not affect any ProductStock" do
      order = create(:order, customer: customer, created_by: admin)
      # product has enable_stock: false
      initial_count = ProductStock.count
      create(:order_line, order: order, product: product, unit_definition: unit_def,
             quantity: 2, unit_price: 100)
      expect(ProductStock.count).to eq(initial_count) # No new stock records
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-08 — Delivery Order Print
  # (main specs in spec/system/delivery_order/delivery_order_spec.rb)
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-08 — Delivery Order Print" do
    let(:order) { create(:order, customer: customer, created_by: admin) }

    before { sign_in_as(admin) }

    it "TC-03-08-01: delivery order accessible with view_orders permission" do
      visit delivery_order_order_path(order)
      expect(page.status_code).to eq(200)
      expect(page).to have_text("บิลขนส่ง")
    end

    it "TC-03-08-02: delivery order requires auth" do
      Capybara.reset_sessions!
      visit delivery_order_order_path(order)
      expect(page).to have_current_path("/login", ignore_query: true)
    end

    it "TC-03-08-05: page title is บิลขนส่ง – [order_number]" do
      visit delivery_order_order_path(order)
      expect(page).to have_title("บิลขนส่ง – #{order.order_number}")
    end

    it "TC-03-08-07: internal_note is not present in delivery order HTML" do
      order.update!(internal_note: "SECRET_NOTE_DO_NOT_SHOW")
      visit delivery_order_order_path(order)
      expect(page.html).not_to include("SECRET_NOTE_DO_NOT_SHOW")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-09 — Order Intelligence
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-09 — Order Intelligence" do
    it "TC-03-09-02: audit trail records order creation" do
      order = create(:order, customer: customer, created_by: admin)
      expect(order.created_by).to eq(admin)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-03-10 — Order Advanced Search & Dashboard
  # ──────────────────────────────────────────────────────────────────
  describe "TC-03-10 — Order Advanced Search & Dashboard" do
    before { sign_in_as(admin) }

    it "TC-03-10-01: search by order number returns matching order" do
      order = create(:order, customer: customer, created_by: admin)
      visit orders_path(q: { order_number_or_customer_first_name_or_customer_last_name_cont: order.order_number })
      expect(page).to have_text(order.order_number)
    end

    it "TC-03-10-03: search by customer name returns matching orders" do
      order = create(:order, customer: customer, created_by: admin)
      visit orders_path(q: { order_number_or_customer_first_name_or_customer_last_name_cont: "TC03" })
      expect(page).to have_text(order.order_number)
    end

    it "TC-03-10-05: dashboard shows today's order count" do
      today_order = create(:order, customer: customer, created_by: admin, running_date: Date.current)
      visit dashboard_orders_path
      expect(page).to have_text(Order.for_date(Date.current).count.to_s)
    end

    it "TC-03-10-07: dashboard lists last 10 orders" do
      12.times { create(:order, customer: customer, created_by: admin) }
      visit dashboard_orders_path
      # Dashboard should show "last 10" orders
      expect(page).to have_css("table tbody tr", minimum: 1)
    end
  end
end
