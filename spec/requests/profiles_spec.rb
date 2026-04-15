# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profiles (web)", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }

  before { sign_in admin_user }

  describe "GET /profile" do
    it "returns 200" do
      get profile_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /profile" do
    it "updates the profile and redirects" do
      patch profile_path, params: { profile: { first_name: "John", last_name: "Doe" } }
      expect(response).to redirect_to(profile_path)
      expect(admin_user.profile.reload.first_name).to eq("John")
    end

    it "re-renders show on invalid params" do
      allow_any_instance_of(Profile).to receive(:update).and_return(false) # rubocop:disable RSpec/AnyInstance
      patch profile_path, params: { profile: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
