# frozen_string_literal: true

require "rails_helper"

RSpec.describe MarkDuplicateOrdersJob, type: :job do
  let(:customer) { create(:customer) }
  let(:product)  { create(:product) }

  describe "#perform" do
    context "when duplicate candidates are found" do
      let(:order)     { create(:order, customer: customer, running_date: Time.zone.today) }
      let(:candidate) { create(:order, customer: customer, running_date: 1.day.ago.to_date) }

      before do
        create(:order_line, order: order,     product: product)
        create(:order_line, order: candidate, product: product)
      end

      it "sets is_possible_duplicate to true on the subject order" do
        described_class.new.perform(order.id)
        expect(order.reload.is_possible_duplicate).to be(true)
      end

      it "sets is_possible_duplicate to true on candidate orders" do
        described_class.new.perform(order.id)
        expect(candidate.reload.is_possible_duplicate).to be(true)
      end
    end

    context "when no duplicate candidates exist" do
      let(:order) { create(:order, customer: customer, running_date: Time.zone.today) }

      before do
        create(:order_line, order: order, product: product)
      end

      it "sets is_possible_duplicate to false" do
        order.update_columns(is_possible_duplicate: true) # rubocop:disable Rails/SkipsModelValidations
        described_class.new.perform(order.id)
        expect(order.reload.is_possible_duplicate).to be(false)
      end
    end

    context "when the order no longer exists" do
      it "exits silently without raising an exception" do
        expect { described_class.new.perform(999_999_999) }.not_to raise_error
      end
    end
  end
end
