# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceImagePolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:admin_role)  { create(:role, :admin) }
  let(:admin_user)  { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:basic_role)  { create(:role) }
  let(:basic_user)  { create(:user).tap { |u| u.profile.update!(role: basic_role) } }
  let(:invoice)     { create(:invoice) }
  let(:record)      { create(:invoice_image, invoice: invoice) }

  describe "#create?" do
    context "with admin user (has change_invoices permission)" do
      let(:user) { admin_user }

      it { is_expected.to be_create }
    end

    context "with basic user (no permissions)" do
      let(:user) { basic_user }

      it { is_expected.not_to be_create }
    end
  end

  describe "#destroy?" do
    context "with admin user" do
      let(:user) { admin_user }

      it { is_expected.to be_destroy }
    end

    context "with basic user" do
      let(:user) { basic_user }

      it { is_expected.not_to be_destroy }
    end
  end

  describe "Scope" do
    let(:user) { admin_user }

    it "resolves to all" do
      expect(described_class::Scope.new(user, InvoiceImage.all).resolve).to eq(InvoiceImage.all)
    end
  end
end

