# frozen_string_literal: true

require "rails_helper"

RSpec.describe "OrderLine lot quantity enforcement", type: :model do # rubocop:disable RSpec/MultipleMemoizedHelpers
  before { create(:branch, :main) }

  let(:unit_group)   { create(:unit_group, :default) }
  let!(:pcs)         do
    unit_group.unit_definitions.find_by(ratio: 1) || create(:unit_definition, unit_group: unit_group, name: "pcs",
                                                                              ratio: 1)
  end
  let(:product)      { create(:product, unit_group: unit_group, enable_stock: true) }
  let(:po)           { create(:purchase_order) }
  let(:lot)          do
    create(:product_lot, product: product, purchase_order: po, remaining_quantity: 10, original_quantity: 10)
  end
  let(:order)        { create(:order, customer: create(:customer)) }

  describe "validate lot_quantity_not_exceeded" do
    it "is valid when quantity does not exceed lot remaining" do
      line = build(:order_line, order: order, product: product, unit_definition: pcs,
                                quantity: 10, unit_price: 50, product_lot: lot)
      expect(line).to be_valid
    end

    it "is invalid when quantity exceeds lot remaining" do
      line = build(:order_line, order: order, product: product, unit_definition: pcs,
                                quantity: 11, unit_price: 50, product_lot: lot)
      expect(line).not_to be_valid
      expect(line.errors[:quantity]).to be_present
    end

    it "is valid on update when quantity <= remaining + previously_allocated" do
      line = create(:order_line, order: order, product: product, unit_definition: pcs,
                                 quantity: 5, unit_price: 50, product_lot: lot)
      lot.reload # remaining should be 5 after create callback
      line.quantity = 8 # remaining 5 + already allocated 5 = 10
      expect(line).to be_valid
    end

    it "is invalid on update when quantity exceeds remaining + previously_allocated" do
      line = create(:order_line, order: order, product: product, unit_definition: pcs,
                                 quantity: 5, unit_price: 50, product_lot: lot)
      lot.reload
      line.quantity = 11 # remaining 5 + allocated 5 = 10, 11 > 10
      expect(line).not_to be_valid
    end
  end

  describe "lot quantity callbacks" do
    it "decrements lot remaining_quantity on create" do
      create(:order_line, order: order, product: product, unit_definition: pcs,
                          quantity: 3, unit_price: 50, product_lot: lot)
      expect(lot.reload.remaining_quantity).to eq(7)
    end

    it "restores lot remaining_quantity on destroy" do
      line = create(:order_line, order: order, product: product, unit_definition: pcs,
                                 quantity: 5, unit_price: 50, product_lot: lot)
      expect { line.destroy }.to change { lot.reload.remaining_quantity }.from(5).to(10)
    end

    it "adjusts lot on quantity update" do
      line = create(:order_line, order: order, product: product, unit_definition: pcs,
                                 quantity: 5, unit_price: 50, product_lot: lot)
      lot.reload
      line.update!(quantity: 8)
      expect(lot.reload.remaining_quantity).to eq(2)
    end

    it "marks lot depleted when remaining_quantity reaches 0" do
      create(:order_line, order: order, product: product, unit_definition: pcs,
                          quantity: 10, unit_price: 50, product_lot: lot)
      expect(lot.reload.status).to eq(ProductLot::STATUS_DEPLETED)
    end

    it "restores lot when order is cancelled" do
      create(:order_line, order: order, product: product, unit_definition: pcs,
                          quantity: 10, unit_price: 50, product_lot: lot)
      expect(lot.reload.status).to eq(ProductLot::STATUS_DEPLETED)
      order.update!(status: "Cc")
      expect(lot.reload.remaining_quantity).to eq(10)
      expect(lot.reload.status).to eq(ProductLot::STATUS_ACTIVE)
    end
  end
end
