# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users index search placeholder i18n", type: :request do
  let(:role) { create(:role, permissions: %w[view_users add_users change_users]) }
  let(:user) { create(:user) }

  describe "TH user visiting GET /users" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get users_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai user search placeholder" do
      expect(response.body).to include("ค้นหาชื่อผู้ใช้")
    end
  end
end
