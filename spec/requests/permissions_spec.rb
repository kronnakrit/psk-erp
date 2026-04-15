# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Permissions (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in admin_user }

  describe "GET /permissions" do
    it "returns 200 and lists all permissions" do
      get permissions_path
      expect(response).to have_http_status(:ok)
    end
  end
end
