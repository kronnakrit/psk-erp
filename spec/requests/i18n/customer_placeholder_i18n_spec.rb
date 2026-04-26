# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customers index search placeholder i18n", type: :request do
  let(:role) { create(:role, permissions: %w[view_customers add_customers]) }
  let(:user) { create(:user) }

  describe "TH user visiting GET /customers" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get customers_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai customer search placeholder" do
      expect(response.body).to include("ค้นหาโดยชื่อ, ที่อยู่")
    end
  end
end
