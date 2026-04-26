require "rails_helper"

RSpec.describe "Flash not_authorized i18n", type: :request do
  let(:view_only_role) do
    create(:role, permissions: %w[view_orders])
  end

  describe "English user triggers not-authorized" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: view_only_role, preferred_locale: "en")
      sign_in user
      # Try to access an action not permitted (e.g. new order without add_orders)
      get new_order_path
      follow_redirect!
    end

    it "flash alert is in English" do
      expect(response.body).to include("not authorized").or include("authorized")
    end
  end

  describe "Thai user triggers not-authorized" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: view_only_role, preferred_locale: "th")
      sign_in user
      get new_order_path
      follow_redirect!
    end

    it "flash alert is in Thai" do
      expect(response.body).to include("ไม่มีสิทธิ์").or include("สิทธิ์")
    end
  end
end
