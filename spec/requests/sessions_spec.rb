# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Devise Sessions (username auth)", type: :request do
  let(:password) { "Password1!" }
  let!(:user)          { create(:user, username: "testuser", password: password, password_confirmation: password) }
  let!(:inactive_user) { create(:user, :inactive, username: "inactive_user", password: password, password_confirmation: password) }

  describe "GET /login" do
    it "returns 200" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end

    it "renders a username text input (AC-01)" do
      get new_user_session_path
      expect(response.body).to include('name="user[username]"')
    end

    it "does not render an email input (AC-02)" do
      get new_user_session_path
      expect(response.body).not_to include('name="user[email]"')
      expect(response.body).not_to include('type="email"')
    end

    it "renders the label 'Username' (AC-03)" do
      get new_user_session_path
      expect(response.body).to include("Username")
    end

    it "renders placeholder 'your_username' (AC-04)" do
      get new_user_session_path
      expect(response.body).to include("your_username")
    end
  end

  describe "POST /login" do
    context "with valid username and password (AC-05)" do
      it "redirects on success" do
        post user_session_path, params: { user: { username: "testuser", password: password } }
        expect(response).to be_redirect
      end
    end

    context "with wrong password" do
      it "re-renders login with non-redirect" do
        post user_session_path, params: { user: { username: "testuser", password: "wrongpassword!" } }
        expect(response).not_to have_http_status(:found)
      end
    end

    context "with inactive user" do
      it "does not redirect to root (login fails)" do
        post user_session_path, params: { user: { username: "inactive_user", password: password } }
        expect(response).not_to redirect_to(root_path)
      end
    end

    context "with unknown username" do
      it "re-renders login (not a redirect to root)" do
        post user_session_path, params: { user: { username: "nobody", password: password } }
        expect(response).not_to redirect_to(root_path)
      end
    end
  end
end
