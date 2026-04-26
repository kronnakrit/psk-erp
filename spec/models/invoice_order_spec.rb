# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceOrder, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:invoice) }
    it { is_expected.to belong_to(:order) }
  end

  describe "custom validation: order_not_on_active_invoice" do
    let(:order)         { create(:order) }
    let(:active_invoice) { create(:invoice, status: "Dr") }

    before do
      create(:invoice_order, invoice: active_invoice, order: order)
    end

    context "when the same order is already on a non-cancelled (Draft) invoice" do
      it "is invalid" do
        new_invoice = create(:invoice, status: "Dr")
        duplicate   = build(:invoice_order, invoice: new_invoice, order: order)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:order_id]).to be_present
      end
    end

    context "when the same order is already on a non-cancelled (Paid) invoice" do
      before { active_invoice.update_columns(status: "Pd") } # rubocop:disable Rails/SkipsModelValidations

      it "is invalid" do
        new_invoice = create(:invoice, status: "Dr")
        duplicate   = build(:invoice_order, invoice: new_invoice, order: order)
        expect(duplicate).not_to be_valid
      end
    end

    context "when the prior invoice is Cancelled" do
      before { active_invoice.update_columns(status: "Cc") } # rubocop:disable Rails/SkipsModelValidations

      it "is valid to add the same order to a new invoice" do
        new_invoice    = create(:invoice, status: "Dr")
        invoice_order  = build(:invoice_order, invoice: new_invoice, order: order)
        expect(invoice_order).to be_valid
      end
    end
  end
end
