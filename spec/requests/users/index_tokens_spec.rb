require "rails_helper"

RSpec.describe "Users index design tokens", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
      view_users add_users change_users delete_users
    ])
  end
  let(:user) { create(:user) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /users" do
    before { get users_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders btn-primary on New User button" do
      expect(response.body).to include("btn-primary")
    end

    it "renders row-action-primary on Edit link" do
      expect(response.body).to include("row-action-primary")
    end

    it "renders row-action-danger on Delete button" do
      expect(response.body).to include("row-action-danger")
    end
  end
end
