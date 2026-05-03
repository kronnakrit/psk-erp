# frozen_string_literal: true
# E2E System Spec — TC-02-02: Brand Management
# Based on: testcases/TC-02-products.md

require "rails_helper"

RSpec.describe "TC-02-02 — Brand Management", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-02-02-01
  it "TC-02-02-01: creates a brand and it appears in the list" do
    visit new_brand_path
    fill_in "Name", with: "TC Brand 0201"
    click_button "Create Brand"

    expect(page).to have_text("Brand created successfully.")
    expect(page).to have_text("TC Brand 0201")
  end

  # TC-02-02-02
  it "TC-02-02-02: edits brand name and saves" do
    brand = create(:brand, name: "Old Brand TC0202")

    visit edit_brand_path(brand)
    fill_in "Name", with: "Updated Brand TC0202"
    click_button "Update Brand"

    expect(page).to have_text("Brand updated successfully.")
    brand.reload
    expect(brand.name).to eq("Updated Brand TC0202")
  end

  # TC-02-02-03
  it "TC-02-02-03: deletes brand not linked to any products" do
    brand = create(:brand, name: "Deletable Brand TC0203")

    visit brands_path
    within("tr", text: brand.name) do
      click_button "Delete"
    end

    expect(page).to have_text("Brand deleted successfully.")
    expect(Brand.exists?(brand.id)).to be false
  end
end
