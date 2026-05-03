# frozen_string_literal: true
# E2E System Spec — TC-07-01 / TC-07-02: Unit Groups & Unit Definitions
# Based on: testcases/TC-07-unit-groups.md

require "rails_helper"

RSpec.describe "TC-07-01 — Unit Group CRUD", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in_as(admin) }

  # TC-07-01-01
  it "TC-07-01-01: creates a unit group" do
    visit new_unit_group_path
    fill_in "Name", with: "Weight TC0701"
    click_button "Create Unit group"

    expect(page).to have_text("Unit group created.")
    expect(page).to have_text("Weight TC0701")
  end

  # TC-07-01-02
  it "TC-07-01-02: edits unit group name" do
    group = create(:unit_group, name: "Old Name TC0702")

    visit edit_unit_group_path(group)
    fill_in "Name", with: "New Name TC0702"
    click_button "Update Unit group"

    expect(page).to have_text("Unit group updated.")
    expect(page).to have_text("New Name TC0702")
  end

  # TC-07-01-03
  it "TC-07-01-03: deletes unit group not assigned to products" do
    group = create(:unit_group, name: "Delete Me TC0703")

    visit unit_groups_path
    within("tr", text: group.name) do
      click_button "Delete"
    end

    expect(page).to have_text("Unit group deleted.")
    expect(page).not_to have_text("Delete Me TC0703")
  end

  # TC-07-01-04
  it "TC-07-01-04: cannot delete unit group assigned to a product" do
    group    = create(:unit_group, name: "Protected TC0704")
    _product = create(:product, unit_group: group)

    visit unit_groups_path
    within("tr", text: group.name) do
      click_button "Delete"
    end

    # Controller sends 409 (rack_test doesn't follow) — verify group still in DB
    expect(UnitGroup.exists?(group.id)).to be true
  end

  # TC-07-01-05
  it "TC-07-01-05: unit groups list sorted alphabetically" do
    create(:unit_group, name: "Zebra Group")
    create(:unit_group, name: "Alpha Group")
    create(:unit_group, name: "Middle Group")

    visit unit_groups_path

    names = all("td", text: /Group/).map(&:text)
    expect(names).to eq(names.sort)
  end
end

RSpec.describe "TC-07-02 — Unit Definition CRUD", type: :system do
  let(:admin_role) { create(:role, :admin) }
  let(:admin)      { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:unit_group) { create(:unit_group, name: "Weight TC0702") }

  before { sign_in_as(admin) }

  # TC-07-02-01
  it "TC-07-02-01: adds unit definition to group" do
    visit unit_group_path(unit_group)
    fill_in "Name", with: "กก."
    fill_in "Ratio (to base unit)", with: "1"
    click_button "Add Unit"

    expect(page).to have_text("Unit definition added.")
    expect(page).to have_text("กก.")
  end

  # TC-07-02-02
  it "TC-07-02-02: adds second unit definition with higher ratio" do
    create(:unit_definition, unit_group: unit_group, name: "กก.", ratio: 1)

    visit unit_group_path(unit_group)
    fill_in "Name", with: "ตัน"
    fill_in "Ratio (to base unit)", with: "1000"
    click_button "Add Unit"

    expect(page).to have_text("Unit definition added.")
    ud = UnitDefinition.find_by!(name: "ตัน")
    expect(ud.ratio).to eq(1000)
  end

  # TC-07-02-03
  it "TC-07-02-03: ratio must be positive (zero rejected)" do
    visit unit_group_path(unit_group)
    fill_in "Name", with: "Invalid TC0703"
    fill_in "Ratio (to base unit)", with: "0"
    click_button "Add Unit"

    expect(page).to have_text("Ratio").and have_text("greater than").or have_text("must be")
  end

  # TC-07-02-05
  it "TC-07-02-05: deletes unit definition not used by order lines" do
    ud = create(:unit_definition, unit_group: unit_group, name: "Delete Def TC0705", ratio: 1)

    visit unit_group_path(unit_group)
    within("#unit_definition_#{ud.id}") do
      click_button "Delete"
    end

    expect(page).to have_text("Unit definition removed.")
    expect(UnitDefinition.exists?(ud.id)).to be false
  end
end
