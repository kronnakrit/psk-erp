# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Status select option i18n", type: :request do
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

    it "renders ร่าง as Draft status select option" do
      expect(response.body).to include("ร่าง")
    end

    it "renders เสร็จสิ้น as Completed status select option" do
      expect(response.body).to include("เสร็จสิ้น")
    end
  end

  describe "EN user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_order_path
    end

    it "renders Draft as status select option" do
      expect(response.body).to include("Draft")
    end

    it "renders Completed as status select option" do
      expect(response.body).to include("Completed")
    end
  end
end
