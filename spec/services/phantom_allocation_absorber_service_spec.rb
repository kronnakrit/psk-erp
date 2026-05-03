# frozen_string_literal: true

require "rails_helper"

RSpec.describe PhantomAllocationAbsorberService do
  before { create(:branch, :main) }

  let(:product) { create(:product, enable_stock: true) }
  let(:order)   { create(:order) }

  def make_lot(remaining:, cost:, received_date: Date.current)
    po = create(:purchase_order)
    create(:product_lot,
           product:            product,
           purchase_order:     po,
           original_quantity:  remaining,
           remaining_quantity: remaining,
           unit_cost:          cost,
           status:             ProductLot::STATUS_ACTIVE,
           received_date:      received_date)
  end

  def stock
    ProductStock.find_or_create_for!(product: product)
  end

  before { stock } # ensure stock exists

  # AC-05: phantom absorption
  describe "#call" do
    context "when phantom allocations exist" do
      let!(:order_line) { create(:order_line, order: order, product: product, quantity: 5) }
      let!(:new_lot)    { make_lot(remaining: 20, cost: 40) }

      before do
        # Create phantom allocation (nil lot) as would be created by FifoLotAllocationService
        order_line.order_line_lot_allocations.create!(
          product_lot_id: nil, allocated_quantity: 5, unit_cost: 0
        )
      end

      it "replaces phantom allocation with real lot allocation" do
        described_class.new(product, new_lot).call
        phantom = order_line.order_line_lot_allocations.reload.where(product_lot_id: nil)
        expect(phantom).to be_empty
      end

      it "creates a real lot allocation for the absorbed quantity" do
        described_class.new(product, new_lot).call
        real_alloc = order_line.order_line_lot_allocations.reload.where(product_lot: new_lot).first
        expect(real_alloc).to be_present
        expect(real_alloc.allocated_quantity).to eq(5)
      end

      it "decrements lot remaining_quantity by absorbed amount" do
        described_class.new(product, new_lot).call
        expect(new_lot.reload.remaining_quantity).to eq(15)
      end

      it "recalculates cogs on order_line to new lot's unit_cost" do
        described_class.new(product, new_lot).call
        expect(order_line.reload.cogs).to eq(BigDecimal("40.0"))
      end
    end

    context "when lot capacity is less than phantom quantity" do
      let!(:order_line) { create(:order_line, order: order, product: product, quantity: 10) }
      let!(:small_lot)  { make_lot(remaining: 3, cost: 50) }

      before do
        # Create phantom allocation representing 10 qty with no lot
        order_line.order_line_lot_allocations.create!(
          product_lot_id: nil, allocated_quantity: 10, unit_cost: 0
        )
        described_class.new(product, small_lot).call
      end

      it "absorbs up to lot capacity" do
        real_alloc = order_line.order_line_lot_allocations.reload.where(product_lot: small_lot).first
        expect(real_alloc.allocated_quantity).to eq(3)
      end

      it "leaves a remaining phantom for the remainder" do
        phantom = order_line.order_line_lot_allocations.reload.where(product_lot_id: nil).first
        expect(phantom.allocated_quantity).to eq(7)
      end

      it "depletes the lot" do
        expect(small_lot.reload.remaining_quantity).to eq(0)
      end
    end

    context "when no phantom allocations exist" do
      let!(:lot_a)      { make_lot(remaining: 10, cost: 20) }
      let!(:order_line) { create(:order_line, order: order, product: product, quantity: 5) }
      let!(:new_lot)    { make_lot(remaining: 20, cost: 40) }

      it "does not modify existing allocations" do
        expect do
          described_class.new(product, new_lot).call
        end.not_to change { order_line.order_line_lot_allocations.count }
      end
    end

    context "when product does not track stock" do
      let(:non_stock) { create(:product, enable_stock: false) }
      let!(:new_lot)  { make_lot(remaining: 20, cost: 40) }

      it "does nothing" do
        expect do
          described_class.new(non_stock, new_lot).call
        end.not_to change(OrderLineLotAllocation, :count)
      end
    end
  end
end
