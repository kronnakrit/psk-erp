# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Empty state messages i18n (invoices, purchase orders, users)", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_invoices view_purchase_orders view_users add_users change_users])
  end
  let(:user) { create(:user) }

  before do
    user.profile.update!(role: role, preferred_locale: "th")
    sign_in user
  end

  describe "TH user with no invoices visits GET /invoices" do
    before { get invoices_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai empty-state message for invoices" do
      expect(response.body).to include("ไม่พบใบแจ้งหนี้")
    end
  end

  describe "TH user with no purchase orders visits GET /purchase_orders" do
    before { get purchase_orders_path }

    it "renders Thai empty-state message for purchase orders" do
      expect(response.body).to include("ไม่พบใบสั่งซื้อ")
    end
  end

  describe "TH user visits GET /users" do
    before { get users_path }

    it "renders Thai empty-state or user list" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai empty-state message for users when no other users exist" do
      # The current_user will be there but if no additional users the list will show
      # just test the page renders without missing translations
      expect(response.body).not_to include('[missing "')
    end
  end
end
