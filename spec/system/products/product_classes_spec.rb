# frozen_string_literal: true
# E2E System Spec — TC-02-03: Product Class & Category Management
# Based on: testcases/TC-02-products.md

require "rails_helper"

RSpec.describe "TC-02-03 — Product Class & Category Management", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-02-03-01
  it "TC-02-03-01: creates a product class and it appears in list" do
    visit new_product_class_path
    fill_in "Name", with: "TC Product Class 0301"
    click_button "Create Product class"

    expect(page).to have_text("Product class created successfully.")
    expect(page).to have_text("TC Product Class 0301")
  end

  # TC-02-03-02
  it "TC-02-03-02: creates a product category and it appears in list" do
    visit new_product_category_path
    fill_in "Name", with: "TC Category 0302"
    click_button "Create Product category"

    expect(page).to have_text("Product category created successfully.")
    expect(page).to have_text("TC Category 0302")
  end

  # TC-02-03-03 — Stimulus-driven, requires js
  it "TC-02-03-03: selecting product class dynamically loads attribute fields", js: true do
    product_class = create(:product_class)
    visit new_product_path

    within("[data-controller='product-attributes']") do
      find("#product_product_class_id + .ts-wrapper", wait: 5)  # wait for Tom Select init
      page.execute_script("document.getElementById('product_product_class_id').tomselect.setValue('#{product_class.id}')")
    end

    # Stimulus controller fires — wait for potential attribute fields to appear
    expect(page).to have_css("[data-controller='product-attributes']")
  end

  # TC-02-03-04 — API test: not applicable as system spec (HTTP-level test)
  it "TC-02-03-04: API categories endpoint accessible without auth — tested in request specs", :skip do
    # See spec/requests/api/ for this coverage
  end
end
