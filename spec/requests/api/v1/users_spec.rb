require "rails_helper"

RSpec.describe "API Users", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) do
    create(:user).tap { |u| u.profile.update!(role: admin_role) }
  end
  let(:headers) do
    post "/api/v1/auth/sign_in",
         params: { user: { email: admin_user.email, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end
  let(:target_user) { create(:user) }

  describe "GET /api/v1/users" do
    it "returns user list for admin" do
      target_user
      get "/api/v1/users", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["users"]).to be_an(Array)
    end

    it "returns 401 without authentication" do
      get "/api/v1/users", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/users" do
    let(:valid_params) do
      { user: { email: "new@psk.com", username: "newuser", password: "Password1!", is_active: true } }
    end

    it "creates a user" do
      post "/api/v1/users", params: valid_params, headers: headers, as: :json
      expect(response).to have_http_status(:created)
      expect(json["user"]["email"]).to eq("new@psk.com")
    end

    it "returns 422 with invalid params" do
      post "/api/v1/users", params: { user: { email: "" } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/users/:id" do
    it "updates a user" do
      patch "/api/v1/users/#{target_user.id}",
            params: { user: { username: "updated_name" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["user"]["username"]).to eq("updated_name")
    end
  end

  describe "DELETE /api/v1/users/:id" do
    it "deletes a user" do
      delete "/api/v1/users/#{target_user.id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "PATCH /api/v1/users/:id/activate" do
    it "activates an inactive user" do
      target_user.update!(is_active: false)
      patch "/api/v1/users/#{target_user.id}/activate", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["user"]["is_active"]).to be true
    end
  end

  describe "PATCH /api/v1/users/:id/deactivate" do
    it "deactivates an active user" do
      patch "/api/v1/users/#{target_user.id}/deactivate", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["user"]["is_active"]).to be false
    end
  end
end
