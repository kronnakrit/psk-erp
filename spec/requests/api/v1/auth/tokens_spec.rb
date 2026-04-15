# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Auth Tokens", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:token) do
    post "/api/v1/auth/sign_in",
         params: { user: { email: user.email, password: "Password1!" } },
         as: :json
    response.headers["Authorization"]
  end
  let(:headers) { { "Authorization" => token } }

  describe "POST /api/v1/auth/refresh" do
    it "returns user info when token is valid" do
      post "/api/v1/auth/refresh", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["user"]["email"]).to eq(user.email)
    end

    it "returns 401 without a token" do
      post "/api/v1/auth/refresh", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/verify" do
    it "returns valid true when token is good" do
      post "/api/v1/auth/verify", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["valid"]).to be true
    end
  end
end
