# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:user) }

  context "when user has admin permissions" do
    let(:role) { create(:role, permissions: Permissions::ALL) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
    it { is_expected.to be_create }
    it { is_expected.to be_update }
    it { is_expected.to be_destroy }
  end

  context "when user has no permissions" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_index }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_destroy }
  end

  describe "Scope" do
    let(:role) { create(:role, permissions: Permissions::ALL) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "resolves all users" do
      scope = UserPolicy::Scope.new(user, User).resolve
      expect(scope).to eq(User.all)
    end
  end
end
