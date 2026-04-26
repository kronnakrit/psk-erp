require "rails_helper"

RSpec.describe "Customers i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_customers add_customers change_customers delete_customers])
  end

  describe "Thai user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get customers_path
    end

    it "renders ลูกค้า as page title" do
      expect(response.body).to include("ลูกค้า")
    end

    it "renders Thai New Customer CTA" do
      expect(response.body).to include("เพิ่มลูกค้า")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get customers_path
    end

    it "renders Customers as page title" do
      expect(response.body).to include("Customers")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
