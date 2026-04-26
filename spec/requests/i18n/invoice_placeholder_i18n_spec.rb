# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoices index search placeholder i18n", type: :request do
  let(:role) { create(:role, permissions: %w[view_invoices add_invoices]) }
  let(:user) { create(:user) }

  describe "TH user visiting GET /invoices" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get invoices_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai invoice search placeholder" do
      expect(response.body).to include("ค้นหาเลขที่ใบแจ้งหนี้")
    end
  end
end
