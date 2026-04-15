# frozen_string_literal: true

require "rails_helper"

RSpec.describe RolePolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:role) }

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
  end

  describe "Scope" do
    let(:role) { create(:role, permissions: Permissions::ALL) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "resolves all roles" do
      scope = RolePolicy::Scope.new(user, Role).resolve
      expect(scope).to eq(Role.all)
    end
  end
end
