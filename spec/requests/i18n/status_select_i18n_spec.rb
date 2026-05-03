# frozen_string_literal: true

require "rails_helper"

# NOTE: The status dropdown was removed from the order create/edit form.
# This spec now verifies locale-appropriate labels appear on the new order page.
RSpec.describe "Order form i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders add_orders change_orders view_all_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_order_path
    end

    it "renders the new order form successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai locale customer label" do
      expect(response.body).to include("ลูกค้า")
    end
  end

  describe "EN user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_order_path
    end

    it "renders the new order form successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "renders English locale label" do
      expect(response.body).to include("Customer")
    end
  end
end
