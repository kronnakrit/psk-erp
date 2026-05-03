# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Profile", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:headers) do
    post "/api/v1/auth/sign_in",
         params: { user: { username: admin_user.username, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end

  describe "GET /api/v1/profile" do
    it "returns the current user profile" do
      get "/api/v1/profile", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["role"]).to be_present
    end
  end

  describe "PATCH /api/v1/profile" do
    it "updates the profile" do
      patch "/api/v1/profile",
            params: { profile: { first_name: "API", last_name: "User" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["first_name"]).to eq("API")
    end

    it "returns 422 on invalid update" do
      allow_any_instance_of(Profile).to receive(:update).and_return(false)
      patch "/api/v1/profile",
            params: { profile: { first_name: "" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
