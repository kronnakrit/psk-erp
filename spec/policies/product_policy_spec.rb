require "rails_helper"

RSpec.describe ProductPolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { Object.new }

  context "when user has can_view_cost permission" do
    let(:role) { create(:role, permissions: %w[can_view_cost view_products]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_can_view_cost }
    it { is_expected.to be_index }
  end

  context "when user does not have can_view_cost permission" do
    let(:role) { create(:role, permissions: %w[view_products]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.not_to be_can_view_cost }
  end

  context "when user has no role" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_can_view_cost }
  end
end
