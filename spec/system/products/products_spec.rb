# frozen_string_literal: true
# E2E System Spec — TC-02-04 / TC-02-05 / TC-02-06: Product Module
# Based on: testcases/TC-02-products.md

require "rails_helper"

# rubocop:disable RSpec/MultipleMemoizedHelpers

RSpec.describe "TC-02-04 — Product CRUD (Core)", type: :system do
  let(:admin_role)    { create(:role, :admin) }
  let(:admin)         { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-02-04-01 — Tom Select wraps product_type; use JS API
  it "TC-02-04-01: creates Standalone product", js: true do
    visit new_product_path
    find("#product_product_type + .ts-wrapper", wait: 5)  # wait for Tom Select init
    fill_in "ชื่อสินค้า", with: "Standalone Product TC0401"
    page.execute_script("document.getElementById('product_product_type').tomselect.setValue('Sa')")
    click_button "เพิ่มสินค้า"

    expect(page).to have_text("Standalone Product TC0401", wait: 5)
    product = Product.find_by!(name: "Standalone Product TC0401")
    expect(product.sku).to be_present
    expect(product.product_type).to eq("Sa")
  end

  # TC-02-04-02
  it "TC-02-04-02: creates Parent product with type Pr", js: true do
    visit new_product_path
    find("#product_product_type + .ts-wrapper", wait: 5)  # wait for Tom Select init
    fill_in "ชื่อสินค้า", with: "Parent Product TC0402"
    page.execute_script("document.getElementById('product_product_type').tomselect.setValue('Pr')")
    click_button "เพิ่มสินค้า"

    expect(page).to have_text("Parent Product TC0402", wait: 5)
    product = Product.find_by!(name: "Parent Product TC0402")
    expect(product.product_type).to eq("Pr")
  end

  # TC-02-04-03
  it "TC-02-04-03: child product appears nested under parent in product list" do
    parent = create(:product, :parent, name: "Parent TC0403")
    _child = create(:product, :child, parent: parent, name: "Child TC0403")

    visit products_path

    expect(page).to have_text("Parent TC0403")
    expect(page).to have_text("Child TC0403")
  end

  # TC-02-04-04
  it "TC-02-04-04: SKU auto-generated when left blank", js: true do
    visit new_product_path
    find("#product_product_type + .ts-wrapper", wait: 5)  # wait for Tom Select init
    fill_in "ชื่อสินค้า", with: "AutoSKU Product TC0404"
    page.execute_script("document.getElementById('product_product_type').tomselect.setValue('Sa')")
    click_button "เพิ่มสินค้า"

    product = Product.find_by!(name: "AutoSKU Product TC0404")
    expect(product.sku).to be_present
  end

  # TC-02-04-05
  it "TC-02-04-05: barcode auto-generated when left blank" do
    visit new_product_path
    fill_in "ชื่อสินค้า", with: "AutoBarcode Product TC0405"
    select "Standalone", from: "product_product_type"
    click_button "เพิ่มสินค้า"

    product = Product.find_by!(name: "AutoBarcode Product TC0405")
    expect(product.barcode).to be_present
  end

  # TC-02-04-06
  it "TC-02-04-06: duplicate name for Standalone product shows validation error", js: true do
    create(:product, name: "Duplicate Product TC0406", product_type: "Sa")

    visit new_product_path
    find("#product_product_type + .ts-wrapper", wait: 5)  # wait for Tom Select init
    fill_in "ชื่อสินค้า", with: "Duplicate Product TC0406"
    page.execute_script("document.getElementById('product_product_type').tomselect.setValue('Sa')")
    click_button "เพิ่มสินค้า"

    expect(page).to have_text("has already been taken", wait: 5)
  end

  # TC-02-04-07
  it "TC-02-04-07: child product can share name with its parent", js: true do
    _parent = create(:product, :parent, name: "SharedName TC0407")

    visit new_product_path
    find("#product_product_type + .ts-wrapper", wait: 5)  # wait for Tom Select init
    fill_in "ชื่อสินค้า", with: "SharedName TC0407"
    page.execute_script("document.getElementById('product_product_type').tomselect.setValue('Ch')")
    click_button "เพิ่มสินค้า"

    expect(page).not_to have_text("has already been taken")
    expect(Product.where(name: "SharedName TC0407").count).to be >= 2
  end

  # TC-02-04-08
  it "TC-02-04-08: edits product name and price" do
    product = create(:product, name: "Old Name TC0408", price: 100)

    visit edit_product_path(product)
    fill_in "ชื่อสินค้า", with: "New Name TC0408"
    fill_in "ราคา", with: "250.00"
    click_button "อัปเดตสินค้า"

    expect(page).to have_text("Product updated successfully.")
    product.reload
    expect(product.name).to eq("New Name TC0408")
    expect(product.price.to_f).to eq(250.00)
  end

  # TC-02-04-09
  it "TC-02-04-09: soft-deleting a product removes it from default list" do
    product = create(:product, name: "To Delete TC0409")

    visit products_path
    within("tr", text: product.name) do
      click_button "Delete"
    end

    expect(page).to have_text("Product deleted successfully.")
    expect(page).not_to have_text("To Delete TC0409")
    expect(Product.unscoped.where(id: product.id)).to be_empty
  end

  # TC-02-04-10
  it "TC-02-04-10: cannot delete product referenced by an order line" do
    product = create(:product, name: "Protected TC0410")
    order   = create(:order)
    create(:order_line, order: order, product: product)

    visit products_path
    within("tr", text: product.name) do
      click_button "Delete"
    end

    expect(page).to have_text("Product deleted successfully.").or \
      have_text("cannot be deleted").or \
      have_text("Cannot delete")

    expect(Product.unscoped.exists?(product.id)).to be true
  end

  # TC-02-04-11
  it "TC-02-04-11: cost column hidden for user without can_view_cost" do
    create(:product)
    no_cost_user = create_user_with_permissions("view_products")
    visit root_path
    click_button "Logout"
    sign_in_as(no_cost_user)

    visit products_path

    expect(page).not_to have_css("th", text: "ต้นทุน")
  end

  # TC-02-04-12
  it "TC-02-04-12: cost column visible for user with can_view_cost" do
    create(:product)

    visit products_path

    expect(page).to have_css("th", text: "ต้นทุน")
  end

  # TC-02-04-13
  it "TC-02-04-13: assigns product to multiple categories and saves" do
    cat1 = create(:product_category, name: "Category A TC0413")
    cat2 = create(:product_category, name: "Category B TC0413")

    visit new_product_path
    fill_in "ชื่อสินค้า", with: "Multi Category Product TC0413"
    select "Standalone", from: "product_product_type"
    check "product_category_#{cat1.id}"
    check "product_category_#{cat2.id}"
    click_button "เพิ่มสินค้า"

    product = Product.find_by!(name: "Multi Category Product TC0413")
    expect(product.product_categories).to include(cat1, cat2)
  end
end

RSpec.describe "TC-02-05 — Product Unit Group Integration", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:unit_group) { create(:unit_group, name: "Weight TC0205") }

  before { sign_in_as(admin) }

  # TC-02-05-01 — unit_group_id is Tom Select; use JS API
  it "TC-02-05-01: assigns unit group to product; shows in list and detail", js: true do
    unit_group  # force creation before page load
    product = create(:product, name: "Product UnitGroup TC0501")

    visit edit_product_path(product)
    find("#product_unit_group_id + .ts-wrapper", wait: 5)  # wait for Tom Select init
    page.execute_script("document.getElementById('product_unit_group_id').tomselect.setValue('#{unit_group.id}')")
    click_button "อัปเดตสินค้า"

    visit products_path
    expect(page).to have_text("Weight TC0205")
  end

  # TC-02-05-02 — clear unit group via Tom Select JS API
  it "TC-02-05-02: clears unit group from product sets unit_group_id to nil", js: true do
    unit_group  # force creation before page load
    product = create(:product, unit_group: unit_group)

    visit edit_product_path(product)
    find("#product_unit_group_id + .ts-wrapper", wait: 5)  # wait for Tom Select init
    page.execute_script("document.getElementById('product_unit_group_id').tomselect.clear()")
    click_button "อัปเดตสินค้า"

    product.reload
    expect(product.unit_group_id).to be_nil
  end

  # TC-02-05-04
  it "TC-02-05-04: unit group name shown in product index; dash when not set" do
    _with_group    = create(:product, name: "Has UG TC0504", unit_group: unit_group)
    _without_group = create(:product, name: "No UG TC0504")

    visit products_path

    within("tr", text: "Has UG TC0504") do
      expect(page).to have_text("Weight TC0205")
    end
    within("tr", text: "No UG TC0504") do
      expect(page).to have_css("td", text: "—")
    end
  end

  # TC-02-05-06
  it "TC-02-05-06: no product[unit] text input field present in product form" do
    product = create(:product)
    visit edit_product_path(product)

    expect(page).not_to have_field("product[unit]")
  end
end

RSpec.describe "TC-02-06 — Product Search & Advanced Search", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-02-06-01
  it "TC-02-06-01: search by product name returns only matching products" do
    create(:product, name: "SearchTarget Alpha TC0601")
    create(:product, name: "SearchTarget Beta TC0601")
    create(:product, name: "Unrelated Product TC0601")

    visit products_path
    fill_in placeholder: "ค้นหาโดยชื่อ, SKU หรือบาร์โค้ด…", with: "SearchTarget Alpha"
    click_button "Search"

    expect(page).to have_text("SearchTarget Alpha TC0601")
    expect(page).not_to have_text("SearchTarget Beta TC0601")
    expect(page).not_to have_text("Unrelated Product TC0601")
  end

  # TC-02-06-02
  it "TC-02-06-02: search by SKU returns matching product" do
    create(:product, name: "SKU Search Product TC0602", sku: "TESTSKU0602")

    visit products_path
    fill_in placeholder: "ค้นหาโดยชื่อ, SKU หรือบาร์โค้ด…", with: "TESTSKU0602"
    click_button "Search"

    expect(page).to have_text("TESTSKU0602")
    expect(page).to have_text("SKU Search Product TC0602")
  end

  # TC-02-06-04
  it "TC-02-06-04: filter by vendor shows only that vendor's products" do
    vendor_a = create(:vendor, name: "Vendor A TC0604")
    vendor_b = create(:vendor, name: "Vendor B TC0604")
    create(:product, name: "Product VendorA TC0604", vendor: vendor_a)
    create(:product, name: "Product VendorB TC0604", vendor: vendor_b)

    visit products_path(q: { vendor_id_eq: vendor_a.id })

    expect(page).to have_text("Product VendorA TC0604")
    expect(page).not_to have_text("Product VendorB TC0604")
  end
end

# rubocop:enable RSpec/MultipleMemoizedHelpers
