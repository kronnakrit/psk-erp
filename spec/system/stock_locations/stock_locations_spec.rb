# frozen_string_literal: true
# E2E System Spec — TC-13-01: Stock Locations
# Based on: testcases/TC-13-stock-locations.md

require "rails_helper"

RSpec.describe "TC-13-01 — Stock Location CRUD", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-13-01-01
  it "TC-13-01-01: creates stock location" do
    visit new_stock_location_path
    fill_in "Name", with: "Warehouse A – Row 3"
    click_button "Create Stock Location"

    expect(page).to have_text("Stock location created.")
    expect(page).to have_text("Warehouse A – Row 3")
  end

  # TC-13-01-02
  it "TC-13-01-02: edits stock location name" do
    location = create(:stock_location, name: "Old Location TC1302")

    visit edit_stock_location_path(location)
    fill_in "Name", with: "New Location TC1302"
    click_button "Update Stock Location"

    expect(page).to have_text("Stock location updated.")
    location.reload
    expect(location.name).to eq("New Location TC1302")
  end

  # TC-13-01-03
  it "TC-13-01-03: deletes stock location not assigned to any stock" do
    location = create(:stock_location, name: "Delete Location TC1303")

    visit stock_locations_path
    within("tr", text: location.name) do
      click_button "Delete"
    end

    expect(page).to have_text("Stock location deleted.")
    expect(StockLocation.exists?(location.id)).to be false
  end

  # TC-13-01-04
  # NOTE: StockLocation has dependent: :destroy on product_stock_locations,
  # so deleting a location cascades. TC documents actual behaviour.
  it "TC-13-01-04: deleting location with assigned stocks cascades (no hard restriction)" do
    location = create(:stock_location, name: "Assigned Location TC1304")
    product  = create(:product)
    stock    = create(:product_stock, product: product)
    ProductStockLocation.create!(product_stock: stock, stock_location: location)

    visit stock_locations_path
    within("tr", text: location.name) do
      click_button "Delete"
    end

    # dependent: :destroy cascades — delete succeeds
    expect(page).to have_text("Stock location deleted.")
    expect(StockLocation.exists?(location.id)).to be false
  end

  # TC-13-01-05
  it "TC-13-01-05: stock locations list has pagination controls when many records" do
    26.times { |i| create(:stock_location, name: "Location #{format('%02d', i)} TC1305") }

    visit stock_locations_path

    expect(page).to have_css("[aria-label='pagination'], nav[role='navigation'], .pagination, a[rel='next']")
  end
end
