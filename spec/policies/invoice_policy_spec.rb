# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoicePolicy, type: :policy do
  subject(:policy) { described_class.new(user, record) }

  let(:draft_invoice)     { build(:invoice, status: "Dr") }
  let(:paid_invoice)      { build(:invoice, status: "Pd") }
  let(:cancelled_invoice) { build(:invoice, status: "Cc") }

  context "when user has view_invoices permission (AC-07 positive)" do
    let(:role) { create(:role, permissions: %w[view_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { draft_invoice }

    it { is_expected.to be_index }
    it { is_expected.to be_show }
    it { is_expected.to be_print }
    it { is_expected.not_to be_audit }
  end

  context "when user does NOT have view_invoices (AC-07 negative)" do
    let(:role) { create(:role, permissions: %w[]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { draft_invoice }

    it { is_expected.not_to be_index }
    it { is_expected.not_to be_show }
    it { is_expected.not_to be_print }
  end

  context "when user has add_invoices permission" do
    let(:role) { create(:role, permissions: %w[add_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { draft_invoice }

    it { is_expected.to be_create }
    it { is_expected.to be_new }
  end

  context "when user does NOT have add_invoices permission" do
    let(:role) { create(:role, permissions: %w[view_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { draft_invoice }

    it { is_expected.not_to be_create }
  end

  context "when user has view_invoice_audit permission" do
    let(:role) { create(:role, permissions: %w[view_invoice_audit]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { draft_invoice }

    it { is_expected.to be_audit }
  end

  context "when user does NOT have view_invoice_audit permission" do
    let(:role) { create(:role, permissions: %w[view_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { draft_invoice }

    it { is_expected.not_to be_audit }
  end

  context "mark_paid? with change_invoices permission" do
    let(:role) { create(:role, permissions: %w[change_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "returns true when invoice is Draft" do
      expect(described_class.new(user, draft_invoice)).to be_mark_paid
    end

    it "returns false when invoice is Paid (not Draft)" do
      expect(described_class.new(user, paid_invoice)).not_to be_mark_paid
    end

    it "returns false when invoice is Cancelled" do
      expect(described_class.new(user, cancelled_invoice)).not_to be_mark_paid
    end
  end

  context "mark_paid? without change_invoices permission" do
    let(:role) { create(:role, permissions: %w[view_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { draft_invoice }

    it { is_expected.not_to be_mark_paid }
  end

  context "reopen? with change_invoices permission" do
    let(:role) { create(:role, permissions: %w[change_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "returns true when invoice is Paid" do
      expect(described_class.new(user, paid_invoice)).to be_reopen
    end

    it "returns false when invoice is Draft (not Paid)" do
      expect(described_class.new(user, draft_invoice)).not_to be_reopen
    end

    it "returns false when invoice is Cancelled" do
      expect(described_class.new(user, cancelled_invoice)).not_to be_reopen
    end
  end

  context "reopen? without change_invoices permission" do
    let(:role) { create(:role, permissions: %w[view_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let(:record) { paid_invoice }

    it { is_expected.not_to be_reopen }
  end

  context "cancel? with change_invoices permission" do
    let(:role) { create(:role, permissions: %w[change_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "returns true when invoice is Draft" do
      expect(described_class.new(user, draft_invoice)).to be_cancel
    end

    it "returns false when invoice is Paid" do
      expect(described_class.new(user, paid_invoice)).not_to be_cancel
    end
  end

  context "when user has no role" do
    let(:user) { create(:user) }
    let(:record) { draft_invoice }

    it { is_expected.not_to be_index }
    it { is_expected.not_to be_create }
    it { is_expected.not_to be_audit }
  end

  describe "Scope" do
    let(:role) { create(:role, permissions: %w[view_invoices]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "returns all invoices" do
      inv1 = create(:invoice)
      inv2 = create(:invoice)
      result = described_class::Scope.new(user, Invoice).resolve
      expect(result).to include(inv1, inv2)
    end
  end
end
