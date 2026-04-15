# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Permissions", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:headers) do
    post "/api/v1/auth/sign_in",
         params: { user: { email: admin_user.email, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/permissions" do
    it "returns all permissions" do
      get "/api/v1/permissions", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["permissions"]).to be_an(Array)
    end
  end
end
