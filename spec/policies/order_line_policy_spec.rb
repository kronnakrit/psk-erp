# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderLinePolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:basic_user) { create(:user) }
  let(:customer)   { create(:customer) }
  let(:order)      { create(:order, customer: customer, created_by: admin_user) }
  let(:record)     { build(:order_line, order: order) }

  describe "#create?" do
    context "with admin user on draft order" do
      let(:user) { admin_user }

      it { is_expected.to be_create }
    end

    context "with basic user without permissions" do
      let(:user) { basic_user }

      it { is_expected.not_to be_create }
    end
  end

  describe "#update?" do
    context "with admin user on draft order" do
      let(:user) { admin_user }

      it { is_expected.to be_update }
    end
  end

  describe "#destroy?" do
    context "with admin user on draft order" do
      let(:user) { admin_user }

      it { is_expected.to be_destroy }
    end

    context "with admin user on non-draft order" do
      let(:user) { admin_user }
      let(:paid_order) { create(:order, :paid, customer: customer, created_by: admin_user) }
      let(:record)     { build(:order_line, order: paid_order) }

      it { is_expected.not_to be_destroy }
    end
  end

  describe "Scope" do
    let(:user) { admin_user }

    it "resolves to all" do
      expect(described_class::Scope.new(user, OrderLine.all).resolve).to eq(OrderLine.all)
    end
  end
end
