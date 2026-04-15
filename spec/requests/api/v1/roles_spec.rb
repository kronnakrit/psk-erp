require "rails_helper"

RSpec.describe "API Roles", type: :request do
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

  describe "GET /api/v1/roles" do
    it "returns roles list" do
      admin_role
      get "/api/v1/roles", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["roles"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/roles" do
    it "creates a role" do
      post "/api/v1/roles",
           params: { role: { name: "Editor", permissions: %w[view_orders] } },
           headers: headers, as: :json
      expect(response).to have_http_status(:created)
      expect(json["name"]).to eq("Editor")
    end

    it "returns 422 with blank name" do
      post "/api/v1/roles",
           params: { role: { name: "" } },
           headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/roles/:id" do
    it "updates a role" do
      role = create(:role, name: "OldName")
      patch "/api/v1/roles/#{role.id}",
            params: { role: { name: "NewName" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["name"]).to eq("NewName")
    end
  end

  describe "DELETE /api/v1/roles/:id" do
    it "deletes a role" do
      role = create(:role)
      delete "/api/v1/roles/#{role.id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end
end
