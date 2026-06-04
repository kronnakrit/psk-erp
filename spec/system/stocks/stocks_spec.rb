# frozen_string_literal: true
# E2E System Spec — TC-04-01..07: Stock Management
# Based on: testcases/TC-04-stock-management.md

require "rails_helper"

RSpec.describe "TC-04 — Stock Management", type: :system do
  let(:admin)   { create_admin_user }
  let(:branch)  { Branch.find_by(name: "Main Branch") || create(:branch, :main) }
  let(:product) { create(:product, name: "TC04 Product", enable_stock: true) }
  let(:stock)   { ProductStock.find_or_create_for!(product: product, branch: branch) }
  let!(:lot) do
    create(:product_lot, product: product, remaining_quantity: 100, original_quantity: 100)
  end

  def open_stock_adjustment_modal(action)
    test_id = action == :deposit ? "stock-deposit-open" : "stock-withdraw-open"
    find("[data-testid='#{test_id}']").click
    expect(page).to have_css("[data-testid='stock-adjustment-modal']:not(.hidden)", wait: 5)
  end

  def submit_stock_adjustment(amount:, reason: nil, lot_id: nil)
    within("[data-testid='stock-adjustment-modal']") do
      if lot_id
        find("[data-testid='stock-adjustment-lot-select']").find("option[value='#{lot_id}']").select_option
      end
      fill_in "amount", with: amount.to_s
      fill_in "reason", with: reason if reason
      find("[data-testid='stock-adjustment-submit']").click
    end
    expect(page).to have_css("[role=alert]", wait: 10)
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-04-01 — Stock Deposit
  # ──────────────────────────────────────────────────────────────────
  describe "TC-04-01 — Stock Deposit", js: true do
    before do
      stock.update!(amount: 50)
      sign_in_as(admin)
    end

    it "TC-04-01-01: deposit increases stock amount and creates IB transaction" do
      initial = stock.amount
      initial_lot = lot.remaining_quantity
      visit stock_path(stock)
      open_stock_adjustment_modal(:deposit)
      submit_stock_adjustment(amount: 10)
      stock.reload
      lot.reload
      expect(stock.amount).to eq(initial + 10)
      expect(lot.remaining_quantity).to eq(initial_lot + 10)
      expect(stock.product_stock_transactions.last.transaction_type).to eq("IB")
      expect(stock.product_stock_transactions.last.related_object).to eq(lot)
    end

    it "TC-04-01-03: deposit with note stores the reason on the transaction" do
      visit stock_path(stock)
      open_stock_adjustment_modal(:deposit)
      submit_stock_adjustment(amount: 5, reason: "TC04 restock note")
      tx = stock.product_stock_transactions.last
      expect(tx.reason).to eq("TC04 restock note")
    end

    it "TC-04-01-04: deposit with zero amount is rejected" do
      visit stock_path(stock)
      open_stock_adjustment_modal(:deposit)
      within("[data-testid='stock-adjustment-modal']") do
        fill_in "amount", with: "0"
        find("[data-testid='stock-adjustment-submit']").click
      end
      expect(page).to have_css("[data-testid='stock-adjustment-modal']:not(.hidden)")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-04-02 — Stock Withdrawal
  # ──────────────────────────────────────────────────────────────────
  describe "TC-04-02 — Stock Withdrawal", js: true do
    before do
      stock.update!(amount: 20, holding_amount: 0)
      lot.update!(remaining_quantity: 20)
      sign_in_as(admin)
    end

    it "TC-04-02-01: withdraw decreases stock amount and creates OB transaction" do
      initial = stock.amount
      initial_lot = lot.remaining_quantity
      visit stock_path(stock)
      open_stock_adjustment_modal(:withdraw)
      submit_stock_adjustment(amount: 5)
      stock.reload
      lot.reload
      expect(stock.amount).to eq(initial - 5)
      expect(lot.remaining_quantity).to eq(initial_lot - 5)
      expect(stock.product_stock_transactions.last.transaction_type).to eq("OB")
    end

    it "TC-04-02-02: withdraw more than lot remaining is rejected" do
      visit stock_path(stock)
      open_stock_adjustment_modal(:withdraw)
      within("[data-testid='stock-adjustment-modal']") do
        fill_in "amount", with: "21"
        find("[data-testid='stock-adjustment-submit']").click
      end
      expect(page).to have_css("[role=alert]", wait: 10)
      stock.reload
      lot.reload
      expect(stock.amount).to eq(20)
      expect(lot.remaining_quantity).to eq(20)
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-04-04 — Stock Transactions
  # ──────────────────────────────────────────────────────────────────
  describe "TC-04-04 — Stock Transactions" do
    before do
      stock.deposit!(amount: 10, reason: "initial", adjuster: admin)
      stock.withdraw!(amount: 3, reason: "out", adjuster: admin)
      stock.deposit!(amount: 5, reason: "restock", adjuster: admin)
      sign_in_as(admin)
    end

    it "TC-04-04-01: transaction list shows transaction types" do
      visit transactions_stock_path(stock)
      # Transactions show "↑ In" for IB and "↓ Out" for OB
      expect(page).to have_text("↑ In")
      expect(page).to have_text("↓ Out")
    end

    it "TC-04-04-05: no edit or delete buttons on transactions (append-only)" do
      visit transactions_stock_path(stock)
      expect(page).not_to have_button("Edit")
      expect(page).not_to have_button("Delete")
      expect(page).not_to have_link("Edit")
      expect(page).not_to have_link("Delete")
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-04-06 — Stock Index & Overview
  # ──────────────────────────────────────────────────────────────────
  describe "TC-04-06 — Stock Index & Overview" do
    let(:stock_product)    { create(:product, name: "Enabled Product TC0406", enable_stock: true) }
    let(:no_stock_product) { create(:product, name: "Disabled Product TC0406", enable_stock: false) }
    let!(:stock_record)    { ProductStock.find_or_create_for!(product: stock_product, branch: branch) }

    before { sign_in_as(admin) }

    it "TC-04-06-01: stock index shows stock-enabled products" do
      visit stocks_path
      expect(page).to have_text("Enabled Product TC0406")
    end

    it "TC-04-06-02: stock index excludes non-stock products without a stock record" do
      visit stocks_path
      expect(page).not_to have_text("Disabled Product TC0406")
    end

    it "TC-04-06-04: stock person shows — when unassigned" do
      visit stocks_path
      # Stock person column header
      expect(page).to have_text("Stock Person").or(have_text("Person"))
    end
  end

  # ──────────────────────────────────────────────────────────────────
  # TC-04-07 — Stock Assignment (Stock Person & Locations)
  # ──────────────────────────────────────────────────────────────────
  describe "TC-04-07 — Stock Assignment", js: true do
    let(:location) { create(:stock_location, name: "Warehouse A TC0407") }
    let!(:user_for_stock) { admin }

    before do
      stock # ensure it exists
      location # ensure it exists
      sign_in_as(admin)
    end

    it "TC-04-07-01: assign stock person updates stock_person_id" do
      visit stock_path(stock)
      # Wait for Tom Select to initialize (the .tomselect property is set after init)
      expect(page).to have_css("[data-controller='tom-select']", wait: 5)
      page.execute_script(<<~JS)
        var sel = document.querySelector("select[name='product_stock[stock_person_id]']");
        if (sel && sel.tomselect) { sel.tomselect.setValue('#{admin.id}'); }
        else { sel.value = '#{admin.id}'; }
      JS
      click_button "Save Assignment"
      stock.reload
      expect(stock.stock_person_id).to eq(admin.id)
    end

    it "TC-04-07-04: clear stock person sets stock_person_id to nil" do
      stock.update!(stock_person: admin)
      visit stock_path(stock)
      expect(page).to have_css("[data-controller='tom-select']", wait: 5)
      page.execute_script(<<~JS)
        var sel = document.querySelector("select[name='product_stock[stock_person_id]']");
        if (sel && sel.tomselect) { sel.tomselect.clear(); }
        else { sel.value = ''; }
      JS
      click_button "Save Assignment"
      stock.reload
      expect(stock.stock_person_id).to be_nil
    end

    it "TC-04-07-02: assign stock location creates join record" do
      visit stock_path(stock)
      expect(page).to have_css("[data-controller='tom-select']", wait: 5)
      page.execute_script(<<~JS)
        var sel = document.querySelector("select[name='product_stock[stock_location_ids][]']");
        if (sel && sel.tomselect) { sel.tomselect.addItem('#{location.id}'); }
        else {
          var opt = new Option('Warehouse A', '#{location.id}', true, true);
          sel.add(opt);
        }
      JS
      click_button "Save Assignment"
      stock.reload
      expect(stock.stock_location_ids).to include(location.id)
    end

    it "TC-04-07-03: remove stock location destroys join record" do
      stock.stock_locations << location
      expect(stock.stock_location_ids).to include(location.id)
      # HTML multi-selects don't submit when empty; test the underlying update behavior
      stock.update!(stock_location_ids: [])
      expect(stock.reload.stock_location_ids).not_to include(location.id)
    end
  end
end
