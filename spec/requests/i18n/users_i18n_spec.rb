require "rails_helper"

RSpec.describe "Users i18n", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[view_users add_users change_users delete_users])
  end

  describe "Thai user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: admin_role, preferred_locale: "th")
      sign_in user
      get users_path
    end

    it "renders ผู้ใช้งาน as page title" do
      expect(response.body).to include("ผู้ใช้งาน")
    end

    it "renders Thai New User CTA" do
      expect(response.body).to include("เพิ่มผู้ใช้งาน")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: admin_role, preferred_locale: "en")
      sign_in user
      get users_path
    end

    it "renders Users as page title" do
      expect(response.body).to include("Users")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
