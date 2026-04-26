# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users form labels i18n", type: :request do
  let(:role) { create(:role, permissions: %w[view_users add_users change_users]) }
  let(:user) { create(:user) }

  describe "TH user visiting GET /users/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_user_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ชื่อผู้ใช้ as Username label" do
      expect(response.body).to include("ชื่อผู้ใช้")
    end

    it "renders ข้อมูลบัญชี as Account Details section heading" do
      expect(response.body).to include("ข้อมูลบัญชี")
    end

    it "renders โปรไฟล์ as Profile section heading" do
      expect(response.body).to include("โปรไฟล์")
    end

    it "renders สร้างผู้ใช้ as submit button" do
      expect(response.body).to include("สร้างผู้ใช้")
    end
  end

  describe "EN user visiting GET /users/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_user_path
    end

    it "renders Username as username label" do
      expect(response.body).to include("Username")
    end

    it "renders Account Details as section heading" do
      expect(response.body).to include("Account Details")
    end

    it "renders Create User as submit button" do
      expect(response.body).to include("Create User")
    end
  end
end
