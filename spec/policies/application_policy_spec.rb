require "rails_helper"

RSpec.describe ApplicationPolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { Object.new }

  context "when user has no profile/role" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_index }
    it { is_expected.not_to be_show }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_destroy }
  end

  context "when user has a role with view permissions" do
    let(:role) { create(:role, permissions: %w[view_applications]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
    it { is_expected.to be_show }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_update }
    it { is_expected.not_to be_destroy }
  end

  context "when user has full permissions" do
    let(:role) do
      create(:role, permissions: %w[view_applications add_applications change_applications delete_applications])
    end
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_create }
    it { is_expected.to be_update }
    it { is_expected.to be_destroy }
  end

  context "when user is nil" do
    let(:user) { nil }

    it { is_expected.not_to be_index }
    it { is_expected.not_to be_create }
  end
end
