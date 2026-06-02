# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customer telephones list JS", type: :system, js: true do
  let(:admin) { create(:user).tap { |u| u.profile.update!(role: create(:role, :admin)) } }

  before { sign_in_as(admin) }

  it "adds and removes telephone rows" do
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
end
