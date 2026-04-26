# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Status badge i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders view_all_orders view_users view_purchase_orders
      view_invoices view_customers
    ])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders with a draft order" do
    let!(:order) { create(:order, status: "Dr") }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get orders_path
    end

    it "renders ร่าง as Draft status badge" do
      expect(response.body).to include("ร่าง")
    end
  end

  describe "EN user visiting GET /orders with a draft order" do
    let!(:order) { create(:order, status: "Dr") }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get orders_path
    end

    it "renders Draft as status badge label" do
      expect(response.body).to include("Draft")
    end
  end

  describe "TH user visiting GET /users with an active user" do
    let!(:active_user) { create(:user, is_active: true) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get users_path
    end

    it "renders ใช้งาน as active status badge" do
      expect(response.body).to include("ใช้งาน")
    end
  end

  describe "TH user visiting GET /purchase_orders with a draft PO" do
    let!(:purchase_order) { create(:purchase_order, status: "Dr") }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get purchase_orders_path
    end

    it "renders ร่าง as Draft PO status badge" do
      expect(response.body).to include("ร่าง")
    end
  end
end
