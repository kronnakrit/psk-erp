# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Roles (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in admin_user }

  describe "GET /roles" do
    it "returns 200" do
      get roles_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /roles/new" do
    it "returns 200" do
      get new_role_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /roles" do
    it "creates a role and redirects" do
      post roles_path, params: { role: { name: "Editor", permissions: [] } }
      expect(response).to redirect_to(roles_path)
      expect(Role.find_by(name: "Editor")).to be_present
    end

    it "renders new on invalid params" do
      post roles_path, params: { role: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /roles/:id/edit" do
    let(:role) { create(:role, name: "Viewer") }

    it "returns 200" do
      get edit_role_path(role)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /roles/:id" do
    let(:role) { create(:role, name: "OldName") }

    it "updates and redirects" do
      patch role_path(role), params: { role: { name: "NewName", permissions: [] } }
      expect(response).to redirect_to(roles_path)
      expect(role.reload.name).to eq("NewName")
    end
  end

  describe "DELETE /roles/:id" do
    let(:role) { create(:role, name: "ToDelete") }

    it "destroys and redirects" do
      delete role_path(role)
      expect(response).to redirect_to(roles_path)
      expect(Role.find_by(name: "ToDelete")).to be_nil
    end
  end
end
