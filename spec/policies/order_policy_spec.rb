require "rails_helper"

RSpec.describe OrderPolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { Object.new }

  context "when user has see_sale_graph permission" do
    let(:role) { create(:role, permissions: %w[see_sale_graph view_orders]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_report }
    it { is_expected.to be_index }
    it { is_expected.to be_delivery_order }
  end

  context "when user does not have see_sale_graph permission" do
    let(:role) { create(:role, permissions: %w[view_orders]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.not_to be_report }
    it { is_expected.to be_delivery_order }
  end

  context "when user has no role" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_report }
    it { is_expected.not_to be_delivery_order }
  end
end
