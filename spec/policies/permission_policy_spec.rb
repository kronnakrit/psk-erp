# frozen_string_literal: true

require "rails_helper"

RSpec.describe PermissionPolicy, type: :policy do
  subject(:policy) { described_class.new(user, :permission) }

  context "when user has view_roles permission" do
    let(:role) { create(:role, permissions: %w[view_roles]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
  end

  context "when user has change_roles permission" do
    let(:role) { create(:role, permissions: %w[change_roles]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
  end

  context "when user has add_roles permission" do
    let(:role) { create(:role, permissions: %w[add_roles]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
  end

  context "when user has no role-related permissions" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_index }
  end

  describe "Scope" do
    let(:user) { create(:user) }

    it "resolves and returns the scope" do
      scope = PermissionPolicy::Scope.new(user, :permission)
      expect(scope.resolve).to eq(:permission)
    end
  end
end
