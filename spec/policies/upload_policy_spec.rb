# frozen_string_literal: true

require "rails_helper"

RSpec.describe UploadPolicy, type: :policy do
  subject(:policy) do
    upload = Upload.new(user: user, status: "pending")
    described_class.new(user, upload)
  end

  let(:user) { create(:user) }

  context "when user has upload permissions" do
    let(:role) { create(:role, permissions: %w[view_uploads add_uploads]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
    it { is_expected.to be_create }
  end

  context "when user has no upload permissions" do
    it { is_expected.not_to be_index }
    it { is_expected.not_to be_create }
  end

  describe "Scope" do
    let(:role)       { create(:role, permissions: Permissions::ALL) }
    let(:user)       { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:other_user) { create(:user) }

    it "returns only the current user's uploads" do
      scope = UploadPolicy::Scope.new(user, Upload).resolve
      expect(scope.to_sql).to include(user.id.to_s)
    end
  end
end
