# frozen_string_literal: true

require "rails_helper"

RSpec.describe DuplicateOrderDetectionService do
  subject(:service) { described_class.new }

  let(:customer)  { create(:customer) }
  let(:product1)  { create(:product) }
  let(:product2)  { create(:product) }

  describe "#call" do
    context "when the order is cancelled" do
      let(:order) { create(:order, customer: customer, status: "Cc", running_date: Time.zone.today) }

      before { create(:order_line, order: order, product: product1) }

      it "returns an empty array" do
        expect(service.call(order: order)).to be_empty
      end
    end

    context "when the order has no lines" do
      let(:order) { create(:order, customer: customer, running_date: Time.zone.today) }

      it "returns an empty array" do
        expect(service.call(order: order)).to be_empty
      end
    end

    context "when no other order exists within 7 days for same customer with shared product" do
      let(:order) { create(:order, customer: customer, running_date: Time.zone.today) }

      before do
        create(:order_line, order: order, product: product1)
        # Different customer
        other_customer = create(:customer)
        other_order = create(:order, customer: other_customer, running_date: Time.zone.today)
        create(:order_line, order: other_order, product: product1)
      end

      it "returns an empty array" do
        expect(service.call(order: order)).to be_empty
      end
    end

    context "when another order has shared product within 7-day window" do
      let(:order)   { create(:order, customer: customer, running_date: Time.zone.today) }
      let(:similar) { create(:order, customer: customer, running_date: 3.days.ago.to_date, status: "Dr") }

      before do
        create(:order_line, order: order,   product: product1)
        create(:order_line, order: similar, product: product1)
        create(:order_line, order: similar, product: product2)
      end

      it "returns the matching candidate order" do
        candidates = service.call(order: order)
        expect(candidates).to contain_exactly(similar)
      end
    end

    context "when another order exists outside the 7-day window" do
      let(:order) { create(:order, customer: customer, running_date: Time.zone.today) }
      let(:far_order) { create(:order, customer: customer, running_date: 10.days.ago.to_date) }

      before do
        create(:order_line, order: order,     product: product1)
        create(:order_line, order: far_order, product: product1)
      end

      it "returns an empty array (outside window)" do
        expect(service.call(order: order)).to be_empty
      end
    end

    context "when the only candidate is the subject order itself" do
      let(:order) { create(:order, customer: customer, running_date: Time.zone.today) }

      before { create(:order_line, order: order, product: product1) }

      it "does not match the subject order itself" do
        expect(service.call(order: order)).to be_empty
      end
    end

    context "when candidate order is cancelled" do
      let(:order)    { create(:order, customer: customer, running_date: Time.zone.today) }
      let(:cc_order) { create(:order, customer: customer, running_date: 1.day.ago.to_date, status: "Cc") }

      before do
        create(:order_line, order: order,    product: product1)
        create(:order_line, order: cc_order, product: product1)
      end

      it "excludes cancelled candidate orders" do
        expect(service.call(order: order)).to be_empty
      end
    end

    context "when no products are shared between orders" do
      let(:order)  { create(:order, customer: customer, running_date: Time.zone.today) }
      let(:order2) { create(:order, customer: customer, running_date: 1.day.ago.to_date) }

      before do
        create(:order_line, order: order,  product: product1)
        create(:order_line, order: order2, product: product2)
      end

      it "returns an empty array" do
        expect(service.call(order: order)).to be_empty
      end
    end
  end
end
