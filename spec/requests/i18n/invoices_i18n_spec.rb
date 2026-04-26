require "rails_helper"

RSpec.describe "Invoices i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_invoices add_invoices change_invoices])
  end

  describe "Thai user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get invoices_path
    end

    it "renders ใบแจ้งหนี้ as page title" do
      expect(response.body).to include("ใบแจ้งหนี้")
    end

    it "renders Thai New Invoice CTA" do
      expect(response.body).to include("สร้างใบแจ้งหนี้")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get invoices_path
    end

    it "renders Invoices as page title" do
      expect(response.body).to include("Invoices")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
