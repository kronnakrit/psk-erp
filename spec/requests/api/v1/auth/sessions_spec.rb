require "rails_helper"

RSpec.describe "POST /api/v1/auth/sign_in", type: :request do
  let(:user) { create(:user, email: "test@psk.com", password: "Password1!") }

  context "with valid credentials" do
    subject(:do_request) do
      post "/api/v1/auth/sign_in",
           params: { user: { email: user.email, password: "Password1!" } },
           as: :json
    end

    it "returns 200" do
      do_request
      expect(response).to have_http_status(:ok)
    end

    it "returns user email" do
      do_request
      expect(json["user"]["email"]).to eq(user.email)
    end

    it "includes Authorization header" do
      do_request
      expect(response.headers["Authorization"]).to be_present
    end
  end

  context "with invalid credentials" do
    it "returns 401" do
      post "/api/v1/auth/sign_in",
           params: { user: { email: user.email, password: "wrongpassword" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with an inactive user" do
    let(:inactive_user) { create(:user, :inactive, email: "inactive@psk.com", password: "Password1!") }

    it "returns 401 and blocks the login" do
      post "/api/v1/auth/sign_in",
           params: { user: { email: inactive_user.email, password: "Password1!" } },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
