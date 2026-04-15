# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in admin_user }

  describe "GET /users" do
    it "returns 200" do
      get users_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /users/new" do
    it "returns 200" do
      get new_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users" do
    it "creates a user and redirects" do
      post users_path, params: {
        user: { email: "web_new@psk.com", username: "webnew", password: "Password1!",
                password_confirmation: "Password1!", is_active: true }
      }
      expect(response).to redirect_to(users_path)
      expect(User.find_by(email: "web_new@psk.com")).to be_present
    end

    it "renders new on invalid params" do
      post users_path, params: { user: { email: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /users/:id/edit" do
    let(:target) { create(:user) }

    it "returns 200" do
      get edit_user_path(target)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /users/:id" do
    let(:target) { create(:user) }

    it "updates and redirects" do
      patch user_path(target), params: { user: { username: "updated_web" } }
      expect(response).to redirect_to(users_path)
      expect(target.reload.username).to eq("updated_web")
    end
  end

  describe "DELETE /users/:id" do
    let(:target) { create(:user) }

    it "destroys and redirects" do
      delete user_path(target)
      expect(response).to redirect_to(users_path)
      expect(User.find_by(id: target.id)).to be_nil
    end
  end

  describe "PATCH /users/:id/activate" do
    let(:target) { create(:user, is_active: false) }

    it "activates user and redirects" do
      patch activate_user_path(target)
      expect(target.reload.is_active).to be true
    end
  end

  describe "PATCH /users/:id/deactivate" do
    let(:target) { create(:user) }

    it "deactivates user and redirects" do
      patch deactivate_user_path(target)
      expect(target.reload.is_active).to be false
    end
  end
end
