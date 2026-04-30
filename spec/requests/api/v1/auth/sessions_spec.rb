require "rails_helper"

RSpec.describe "POST /api/v1/auth/sign_in", type: :request do
  let(:user) { create(:user, username: "testapi", email: "test@psk.com", password: "Password1!") }

  context "with valid username and password (AC-01)" do
    subject(:do_request) do
      post "/api/v1/auth/sign_in",
           params: { user: { username: user.username, password: "Password1!" } },
           as: :json
    end

    it "returns 200" do
      do_request
      expect(response).to have_http_status(:ok)
    end

    it "returns user id, email, and username" do
      do_request
      expect(json["user"]["email"]).to eq(user.email)
      expect(json["user"]["username"]).to eq(user.username)
      expect(json["user"]["id"]).to eq(user.id)
    end

    it "includes Authorization header with JWT (AC-01)" do
      do_request
      expect(response.headers["Authorization"]).to be_present
    end
  end

  context "with unknown username (AC-02)" do
    it "returns 401" do
      post "/api/v1/auth/sign_in",
           params: { user: { username: "ghost", password: "Password1!" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with an inactive user (AC-03)" do
    let(:inactive_user) { create(:user, :inactive, username: "inactive_api", password: "Password1!") }

    it "returns 401" do
      post "/api/v1/auth/sign_in",
           params: { user: { username: inactive_user.username, password: "Password1!" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with email param instead of username (AC-04)" do
    it "returns 401 (email is not the auth key)" do
      post "/api/v1/auth/sign_in",
           params: { user: { email: user.email, password: "Password1!" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end

