# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoice status badge i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_invoices view_all_invoices])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /invoices with a draft invoice" do
    let!(:invoice) { create(:invoice, status: "Dr") }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get invoices_path
    end

    it "renders ร่าง as Draft invoice status badge" do
      expect(response.body).to include("ร่าง")
    end
  end

  describe "EN user visiting GET /invoices with a draft invoice" do
    let!(:invoice) { create(:invoice, status: "Dr") }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get invoices_path
    end

    it "renders Draft as invoice status badge label" do
      expect(response.body).to include("Draft")
    end
  end
end
