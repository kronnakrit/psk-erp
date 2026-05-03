# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderImagePolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:order) { create(:order) }
  let(:record) { OrderImage.new(order: order) }

  context "with admin user" do
    let(:user) { admin_user }

    it { is_expected.to be_create }
    it { is_expected.to be_destroy }
  end

  context "with user without permissions" do
    let(:user) { create(:user) }

    it { is_expected.not_to be_create }
    it { is_expected.not_to be_destroy }
  end

  describe "Scope" do
    let(:user) { admin_user }

    it "resolves to all" do
      expect(described_class::Scope.new(user, OrderImage.all).resolve).to eq(OrderImage.all)
    end
  end
end
