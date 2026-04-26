# frozen_string_literal: true

require "rails_helper"

RSpec.describe EligibleOrdersQuery do
  let(:customer) { create(:customer) }
  let!(:eligible_order) { create(:order, customer: customer, status: "Pd") }

  describe "#call" do
    context "with no filters" do
      it "returns orders not already on an active invoice" do
        result = described_class.new({}).call
        expect(result).to include(eligible_order)
      end
    end

    context "when order is on a Draft invoice" do
      let!(:invoice) { create(:invoice, customer: customer) }
      before { create(:invoice_order, invoice: invoice, order: eligible_order) }

      it "excludes the order" do
        result = described_class.new({}).call
        expect(result).not_to include(eligible_order)
      end
    end

    context "when order is on a Cancelled invoice" do
      let!(:invoice) { create(:invoice, :cancelled, customer: customer) }
      before { create(:invoice_order, invoice: invoice, order: eligible_order) }

      it "includes the order (cancelled invoice doesn't block reuse)" do
        result = described_class.new({}).call
        expect(result).to include(eligible_order)
      end
    end

    context "with customer_id filter" do
      let(:other_order) { create(:order, status: "Pd") }

      it "returns only orders for that customer" do
        result = described_class.new(customer_id: customer.id).call
        expect(result).to include(eligible_order)
        expect(result).not_to include(other_order)
      end
    end

    context "with date range filter" do
      let!(:old_order) { create(:order, customer: customer, status: "Pd", running_date: 2.months.ago) }

      it "filters by from_date" do
        result = described_class.new(from_date: 1.week.ago.to_s).call
        expect(result).to include(eligible_order)
        expect(result).not_to include(old_order)
      end
    end
  end
end
