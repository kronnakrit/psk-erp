# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders form customer typeahead placeholder i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders add_orders view_all_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_order_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai customer typeahead placeholder" do
      expect(response.body).to include("พิมพ์ชื่อหรือเบอร์โทรศัพท์")
    end
  end

  describe "EN user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_order_path
    end

    it "renders English customer typeahead placeholder" do
      expect(response.body).to include("Type name or phone")
    end
  end
end
