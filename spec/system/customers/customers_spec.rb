# frozen_string_literal: true
# E2E System Spec — TC-05-01 / TC-05-02: Customers & Logistic Companies
# Based on: testcases/TC-05-customers-logistics.md

require "rails_helper"

# rubocop:disable RSpec/MultipleMemoizedHelpers

RSpec.describe "TC-05-01 — Customer CRUD", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-05-01-01
  it "TC-05-01-01: creates customer with name, telephone, address" do
    visit new_customer_path
    fill_in "ชื่อ", with: "Alpha"
    fill_in "นามสกุล", with: "Customer TC0501"
    fill_in "เบอร์โทรศัพท์", with: "0812340501"
    fill_in "ที่อยู่", with: "99 Test Road TC0501"
    click_button "เพิ่มลูกค้า"

    expect(page).to have_text("Customer created successfully.")
    expect(page).to have_text("Alpha")
  end

  # TC-05-01-03
  it "TC-05-01-03: edits customer telephone", js: true do
    customer = create(:customer, first_name: "Edit", last_name: "Customer TC0503", telephones: ["0812340503"])

    visit edit_customer_path(customer)
    fill_in "customer_telephone", with: "0899990503"
    click_button "อัปเดตลูกค้า"

    expect(page).to have_current_path(customers_path)
    customer.reload
    expect(customer.telephones_list).to eq(["0899990503"])
  end

  it "adds and removes telephone rows", js: true do
    customer = create(:customer, telephones: ["0812345678"])

    visit edit_customer_path(customer)
    expect(page).to have_css(".js-telephone-row", count: 1)

    find("[data-telephones-list-add]").click
    expect(page).to have_css(".js-telephone-row", count: 2)

    all(".js-telephone-row").last.find("input").set("0899999999")
    all(".js-telephone-row").last.find("[data-telephones-list-remove]").click
    expect(page).to have_css(".js-telephone-row", count: 1)

    click_button "อัปเดตลูกค้า"
    expect(customer.reload.telephones).to eq(["0812345678"])
  end

  it "saves multiple telephone numbers and shows them on index", js: true do
    customer = create(:customer, first_name: "Multi", last_name: "Phone", telephones: ["0811111111"])

    visit edit_customer_path(customer)
    find("[data-telephones-list-add]").click
    all(".js-telephone-row")[1].find("input").set("0822222222")

    click_button "อัปเดตลูกค้า"
    expect(page).to have_current_path(customers_path)
    expect(customer.reload.telephones_list).to contain_exactly("0811111111", "0822222222")
    expect(page).to have_text("0811111111, 0822222222")
  end

  # TC-05-01-04
  it "TC-05-01-04: soft-deletes customer with no orders" do
    customer = create(:customer, first_name: "Delete", last_name: "Customer TC0504")

    visit customers_path
    within("tr", text: customer.first_name) do
      click_button "Delete"
    end

    expect(page).to have_text("Customer deleted.")
    # Customer model uses soft_delete! — record still in DB with deleted_at set
    expect(Customer.unscoped.exists?(customer.id)).to be true
    expect(Customer.unscoped.find(customer.id).deleted_at).to be_present
  end

  # TC-05-01-05
  it "TC-05-01-05: soft-deletes customer linked to orders (soft delete always succeeds)" do
    customer = create(:customer, first_name: "Linked", last_name: "Customer TC0505")
    create(:order, customer: customer)

    visit customers_path
    within("tr", text: customer.first_name) do
      click_button "Delete"
    end

    # Customer uses soft_delete! regardless of associations
    expect(page).to have_text("Customer deleted.")
    expect(Customer.unscoped.find(customer.id).deleted_at).to be_present
  end

  # TC-05-01-08
  it "TC-05-01-08: search customers by name" do
    create(:customer, first_name: "SearchAlpha", last_name: "TC0508")
    create(:customer, first_name: "SearchBeta", last_name: "TC0508")
    create(:customer, first_name: "Unrelated", last_name: "TC0508")

    visit customers_path
    fill_in placeholder: "ค้นหาโดยชื่อ, ที่อยู่, เบอร์โทรศัพท์ หรือบริษัทขนส่ง…", with: "SearchAlpha"
    click_button "Search"

    expect(page).to have_text("SearchAlpha")
    expect(page).not_to have_text("SearchBeta")
    expect(page).not_to have_text("Unrelated")
  end
end

RSpec.describe "TC-05-02 — Logistic Company Management", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-05-02-01
  it "TC-05-02-01: creates logistic company" do
    visit new_logistic_company_path
    fill_in "Name", with: "Fast Delivery TC0502"
    click_button "Create Logistic Company"

    expect(page).to have_text("Logistic company created successfully.")
    expect(page).to have_text("Fast Delivery TC0502")
  end

  # TC-05-02-02
  it "TC-05-02-02: edits logistic company name" do
    company = create(:logistic_company, name: "Old Company TC0502")

    visit edit_logistic_company_path(company)
    fill_in "Name", with: "New Company TC0502"
    click_button "Update Logistic Company"

    expect(page).to have_text("Logistic company updated successfully.")
    company.reload
    expect(company.name).to eq("New Company TC0502")
  end

  # TC-05-02-03 — logistic_company_id field is Tom Select
  it "TC-05-02-03: assigns logistic company to customer", js: true do
    company  = create(:logistic_company, name: "Assign Co TC0503")
    customer = create(:customer, first_name: "Assign", last_name: "Customer TC0503")

    visit edit_customer_path(customer)
    find("#customer_logistic_company_id + .ts-wrapper", wait: 5)
    page.execute_script("document.getElementById('customer_logistic_company_id').tomselect.setValue('#{company.id}')")
    click_button "อัปเดตลูกค้า"

    # Assert the update took effect (flash auto-dismissed in JS mode — check page content)
    expect(page).to have_text("Assign Co TC0503", wait: 5)
    customer.reload
    expect(customer.logistic_company_id).to eq(company.id)
  end

  # TC-05-02-06
  it "TC-05-02-06: deletes logistic company" do
    company = create(:logistic_company, name: "Delete Co TC0502")

    visit logistic_companies_path
    within("tr", text: company.name) do
      click_button "Delete"
    end

    expect(page).to have_text("Logistic company deleted.")
    expect(LogisticCompany.exists?(company.id)).to be false
  end
end

# rubocop:enable RSpec/MultipleMemoizedHelpers
