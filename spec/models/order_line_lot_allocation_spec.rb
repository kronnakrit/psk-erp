# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderLineLotAllocation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:order_line) }
    it { is_expected.to belong_to(:product_lot).optional(true) }
  end

  describe "validations" do
    subject(:allocation) { build(:order_line_lot_allocation) }

    it { is_expected.to validate_numericality_of(:allocated_quantity).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:unit_cost).is_greater_than_or_equal_to(0) }
  end

  describe "phantom allocation (product_lot_id nil)" do
    it "is valid with product_lot nil" do
      alloc = build(:order_line_lot_allocation, :phantom)
      expect(alloc).to be_valid
    end

    it "saves to DB with product_lot nil" do
      expect do
        create(:order_line_lot_allocation, :phantom)
      end.to change(described_class, :count).by(1)
    end
  end

  describe "factory" do
    it "creates a valid allocation" do
      expect(create(:order_line_lot_allocation)).to be_persisted
    end
  end
end
