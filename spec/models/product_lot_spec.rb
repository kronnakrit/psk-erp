# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductLot, type: :model do
  subject { create(:product_lot) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:lot_number) }
    it { is_expected.to validate_uniqueness_of(:lot_number) }
    it { is_expected.to validate_presence_of(:received_date) }
    it { is_expected.to validate_numericality_of(:original_quantity).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:remaining_quantity).is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:unit_cost).is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:product) }
    it { is_expected.to belong_to(:purchase_order) }
  end

  describe "#update_status_if_depleted" do
    context "when remaining_quantity reaches 0" do
      it "sets status to depleted" do
        lot = create(:product_lot, remaining_quantity: 10)
        lot.update!(remaining_quantity: 0)
        expect(lot.reload.status).to eq(ProductLot::STATUS_DEPLETED)
      end
    end

    context "when remaining_quantity is restored above 0" do
      it "re-activates the lot" do
        lot = create(:product_lot, remaining_quantity: 0, status: ProductLot::STATUS_DEPLETED)
        lot.update!(remaining_quantity: 5)
        expect(lot.reload.status).to eq(ProductLot::STATUS_ACTIVE)
      end
    end
  end
end
