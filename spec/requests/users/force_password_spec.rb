# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users Force Password (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:target_user) { create(:user) }

  before { sign_in admin_user }

  describe "PATCH /users/:user_id/force_password" do
    it "updates password when both passwords match" do
      patch user_force_password_path(target_user),
            params: { password1: "NewPass@1", password2: "NewPass@1" }
      expect(response).to redirect_to(users_path)
    end

    it "redirects back with alert when passwords don't match" do
      patch user_force_password_path(target_user),
            params: { password1: "NewPass@1", password2: "Different@1" }
      expect(response).to redirect_to(edit_user_path(target_user))
    end

    it "redirects with alert when password update fails validation" do
      # Force a validation error by providing a weak password
      patch user_force_password_path(target_user),
            params: { password1: "abc", password2: "abc" }
      expect(response).to redirect_to(edit_user_path(target_user))
      expect(flash[:alert]).to be_present
    end
  end
end
