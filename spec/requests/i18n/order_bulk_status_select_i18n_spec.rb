# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Order bulk-status select option i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders view_all_orders change_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get orders_path
    end

    it "renders ร่าง as Draft bulk-status select option" do
      expect(response.body).to include("ร่าง")
    end

    it "renders เสร็จสิ้น as Completed bulk-status select option" do
      expect(response.body).to include("เสร็จสิ้น")
    end
  end

  describe "EN user visiting GET /orders" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get orders_path
    end

    it "renders Draft as bulk-status select option" do
      expect(response.body).to include("Draft")
    end

    it "renders Completed as bulk-status select option" do
      expect(response.body).to include("Completed")
    end
  end
end
