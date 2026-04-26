# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase order show status badge i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_purchase_orders add_purchase_orders change_purchase_orders])
  end
  let(:user) { create(:user) }
  let!(:purchase_order) { create(:purchase_order, status: "Dr") }

  describe "TH user visiting GET /purchase_orders/:id with a Draft PO" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get purchase_order_path(purchase_order)
    end

    it "renders ร่าง as Draft status badge in the show page" do
      expect(response.body).to include("ร่าง")
    end
  end

  describe "EN user visiting GET /purchase_orders/:id with a Draft PO" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get purchase_order_path(purchase_order)
    end

    it "renders Draft as status badge label in the show page" do
      expect(response.body).to include("Draft")
    end
  end
end
