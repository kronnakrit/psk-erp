# frozen_string_literal: true

require "rails_helper"

RSpec.describe PriceMonitorService do
  subject(:service) { described_class.new }

  let(:customer) { create(:customer) }
  let(:product)  { create(:product) }

  describe "#call" do
    context "when no order lines exist within the window" do
      it "returns an empty array" do
        expect(service.call).to be_empty
      end
    end

    context "when price change is less than 10%" do
      before do
        order1 = create(:order, customer: customer, running_date: 30.days.ago.to_date, status: "Dr")
        order2 = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Dr")
        create(:order_line, order: order1, product: product, unit_price: 100.00)
        create(:order_line, order: order2, product: product, unit_price: 108.00) # +8%
      end

      it "returns no entry" do
        expect(service.call).to be_empty
      end
    end

    context "when price decreases by >= 10%" do
      before do
        order1 = create(:order, customer: customer, running_date: 30.days.ago.to_date, status: "Dr")
        order2 = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Dr")
        create(:order_line, order: order1, product: product, unit_price: 100.00)
        create(:order_line, order: order2, product: product, unit_price: 85.00) # -15%
      end

      it "returns one entry with correct change_pct" do
        results = service.call
        expect(results.size).to eq(1)
        expect(results.first.change_pct).to be_within(0.01).of(-15.0)
        expect(results.first.customer).to eq(customer)
        expect(results.first.product).to eq(product)
      end
    end

    context "when price increases by >= 10%" do
      before do
        order1 = create(:order, customer: customer, running_date: 30.days.ago.to_date, status: "Dr")
        order2 = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Dr")
        create(:order_line, order: order1, product: product, unit_price: 100.00)
        create(:order_line, order: order2, product: product, unit_price: 120.00) # +20%
      end

      it "returns one entry with correct positive change_pct" do
        results = service.call
        expect(results.size).to eq(1)
        expect(results.first.change_pct).to be_within(0.01).of(20.0)
      end
    end

    context "when order is cancelled" do
      before do
        order1 = create(:order, customer: customer, running_date: 30.days.ago.to_date, status: "Cc")
        order2 = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Dr")
        create(:order_line, order: order1, product: product, unit_price: 100.00)
        create(:order_line, order: order2, product: product, unit_price: 50.00) # -50% but first is cancelled
      end

      it "excludes cancelled orders from the dataset" do
        # Only one non-cancelled order line exists → no comparison possible → empty result
        expect(service.call).to be_empty
      end
    end

    context "when first_price is zero" do
      before do
        order1 = create(:order, customer: customer, running_date: 30.days.ago.to_date, status: "Dr")
        order2 = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Dr")
        create(:order_line, order: order1, product: product, unit_price: 0.00)
        create(:order_line, order: order2, product: product, unit_price: 100.00)
      end

      it "skips the pair to prevent division by zero" do
        expect(service.call).to be_empty
      end
    end

    context "when there is only one distinct running_date for a pair" do
      before do
        order1 = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Dr")
        order2 = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Pd")
        create(:order_line, order: order1, product: product, unit_price: 100.00)
        create(:order_line, order: order2, product: product, unit_price: 50.00)
      end

      it "skips the pair since no comparison is possible" do
        expect(service.call).to be_empty
      end
    end

    context "when there are orders outside the 365-day window" do
      before do
        old_order = create(:order, customer: customer, running_date: 400.days.ago.to_date, status: "Dr")
        new_order = create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Dr")
        create(:order_line, order: old_order, product: product, unit_price: 100.00)
        create(:order_line, order: new_order, product: product, unit_price: 50.00)
      end

      it "excludes orders older than 365 days from the computation" do
        # Only one order within window → no comparison → empty
        expect(service.call).to be_empty
      end
    end
  end
end
