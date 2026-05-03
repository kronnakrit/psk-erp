# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseOrderLine, type: :model do
  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, ratio: 1) }
  let(:product)    { create(:product, unit_group: unit_group) }
  let(:po)         { create(:purchase_order) }

  subject do
    build(:purchase_order_line,
          purchase_order: po, product: product, unit_definition: unit_def)
  end

  describe "validations" do
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:unit_cost).is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:purchase_order) }
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:unit_definition) }
  end

  describe "unit_definition_belongs_to_product_group" do
    context "when unit_definition belongs to the product's group" do
      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "when unit_definition belongs to a different group" do
      it "is invalid" do
        other_group  = create(:unit_group)
        other_unit   = create(:unit_definition, unit_group: other_group, ratio: 1)
        line = build(:purchase_order_line,
                     purchase_order: po, product: product, unit_definition: other_unit)
        expect(line).not_to be_valid
        expect(line.errors[:unit_definition]).to be_present
      end
    end
  end

  describe "#line_total" do
    it "returns quantity * unit_cost" do
      line = build(:purchase_order_line, quantity: 5, unit_cost: 20.00)
      expect(line.line_total).to eq(100.00)
    end
  end

  describe ".ransackable_attributes" do
    it "includes expected attributes" do
      expect(PurchaseOrderLine.ransackable_attributes).to include("purchase_order_id", "product_id")
    end
  end

  describe ".ransackable_associations" do
    it "includes expected associations" do
      expect(PurchaseOrderLine.ransackable_associations).to include("purchase_order", "product")
    end
  end
end
