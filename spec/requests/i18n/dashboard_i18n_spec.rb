require "rails_helper"

RSpec.describe "Dashboard i18n", type: :request do
  describe "Thai user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(preferred_locale: "th")
      sign_in user
      get root_path
    end

    it "renders แดชบอร์ด as page title" do
      expect(response.body).to include("แดชบอร์ด")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(preferred_locale: "en")
      sign_in user
      get root_path
    end

    it "renders Dashboard as page title" do
      expect(response.body).to include("Dashboard")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
