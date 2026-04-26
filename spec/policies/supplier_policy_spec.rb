# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupplierPolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:record) { create(:supplier) }

  context "when user has all supplier permissions" do
    let(:role) { create(:role, permissions: %w[view_suppliers add_suppliers change_suppliers delete_suppliers]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_index }
    it { is_expected.to be_show }
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
    let(:role) { create(:role, permissions: %w[view_suppliers]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "resolves all suppliers" do
      create_list(:supplier, 2)
      scope = SupplierPolicy::Scope.new(user, Supplier).resolve
      expect(scope.count).to eq(Supplier.count)
    end
  end
end
