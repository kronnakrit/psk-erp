# frozen_string_literal: true

require "rails_helper"

RSpec.describe FifoLotAllocationService do
  before { create(:branch, :main) }

  let(:product) { create(:product, enable_stock: true) }

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

  # AC-01: Lot A (qty 10, cost 20) + Lot B (qty 5, cost 30), request 12
  describe "#call (AC-01) — multi-lot FIFO with full coverage" do
    let!(:lot_a) { make_lot(remaining: 10, cost: 20, received_date: 3.days.ago) }
    let!(:lot_b) { make_lot(remaining: 5,  cost: 30, received_date: 1.day.ago) }

    subject(:result) { described_class.new(product, 12).call(dry_run: true) }

    it "returns two allocations in FIFO order" do
      expect(result.allocations.map(&:lot)).to eq([lot_a, lot_b])
    end

    it "allocates all of lot_a and 2 from lot_b" do
      qtys = result.allocations.map(&:qty)
      expect(qtys).to eq([BigDecimal("10"), BigDecimal("2")])
    end

    it "computes weighted_avg_cost correctly" do
      # (10*20 + 2*30) / 12 = 260 / 12 = 21.67
      expect(result.weighted_avg_cost).to eq(BigDecimal("21.67"))
    end

    it "has zero phantom_qty" do
      expect(result.phantom_qty).to eq(0)
    end

    it "does not modify lots on dry_run: true" do
      expect { result }.not_to change { lot_a.reload.remaining_quantity }
    end
  end

  # AC-02: No active lots, request 5 → all phantom
  describe "#call (AC-02) — no lots, all phantom" do
    subject(:result) { described_class.new(product, 5).call(dry_run: true) }

    it "returns an empty allocations array" do
      expect(result.allocations).to be_empty
    end

    it "returns weighted_avg_cost of 0" do
      expect(result.weighted_avg_cost).to eq(0)
    end

    it "sets phantom_qty to the full requested quantity" do
      expect(result.phantom_qty).to eq(5)
    end
  end

  # AC-03: Lot A (qty 3, cost 50), request 8 → partial + phantom
  describe "#call (AC-03) — partial lot + phantom" do
    let!(:lot_a) { make_lot(remaining: 3, cost: 50) }

    subject(:result) { described_class.new(product, 8).call(dry_run: true) }

    it "allocates 3 from lot_a" do
      expect(result.allocations.first.qty).to eq(3)
    end

    it "sets phantom_qty to 5" do
      expect(result.phantom_qty).to eq(5)
    end

    it "computes weighted_avg_cost correctly" do
      # (3*50) / 8 = 150 / 8 = 18.75
      expect(result.weighted_avg_cost).to eq(BigDecimal("18.75"))
    end
  end

  # AC-04: dry_run false — persists allocations and decrements lots
  describe "#call (AC-04) — dry_run: false persists records" do
    let!(:lot_a)     { make_lot(remaining: 10, cost: 20, received_date: 3.days.ago) }
    let!(:lot_b)     { make_lot(remaining: 5,  cost: 30, received_date: 1.day.ago) }
    # Use a non-stock product for order_line so the after_create callback doesn't allocate lots
    let(:non_stock_product) { create(:product, enable_stock: false) }
    let(:order_line) { create(:order_line, product: non_stock_product) }

    before do
      stock = instance_double(ProductStock)
      allow(ProductStock).to receive(:find_or_create_for!).and_return(stock)
      allow(stock).to receive(:withdraw!)
      allow(stock).to receive(:deposit!)
      # Reset lot quantities that may be affected by other test isolation
      lot_a.update_columns(remaining_quantity: 10) # rubocop:disable Rails/SkipsModelValidations
      lot_b.update_columns(remaining_quantity: 5)  # rubocop:disable Rails/SkipsModelValidations
    end

    it "decrements lot_a remaining_quantity by 10" do
      described_class.new(product, 12).call(dry_run: false, order_line: order_line)
      expect(lot_a.reload.remaining_quantity).to eq(0)
    end

    it "decrements lot_b remaining_quantity by 2" do
      described_class.new(product, 12).call(dry_run: false, order_line: order_line)
      expect(lot_b.reload.remaining_quantity).to eq(3)
    end

    it "creates two OrderLineLotAllocation records" do
      expect do
        described_class.new(product, 12).call(dry_run: false, order_line: order_line)
      end.to change(OrderLineLotAllocation, :count).by(2)
    end

    it "creates a phantom allocation when quantity exceeds available lots" do
      # lot_a has 10, lot_b has 5; total = 15; request 20 → phantom of 5
      expect do
        described_class.new(product, 20).call(dry_run: false, order_line: order_line)
      end.to change { order_line.order_line_lot_allocations.where(product_lot_id: nil).count }.by(1)
    end

    it "raises ArgumentError when order_line is nil" do
      expect do
        described_class.new(product, 5).call(dry_run: false, order_line: nil)
      end.to raise_error(ArgumentError, /order_line is required/)
    end
  end

  # AC-05: rollback safety
  describe "#call (AC-05) — rollback safety" do
    let!(:lot_a)     { make_lot(remaining: 10, cost: 20) }
    let(:non_stock_product) { create(:product, enable_stock: false) }
    let(:order_line) { create(:order_line, product: non_stock_product) }

    before do
      stock = instance_double(ProductStock)
      allow(ProductStock).to receive(:find_or_create_for!).and_return(stock)
      allow(stock).to receive(:withdraw!)
      allow(stock).to receive(:deposit!)
    end

    it "leaves lots and allocations unchanged when outer transaction rolls back" do
      initial_remaining = lot_a.remaining_quantity
      initial_alloc_count = OrderLineLotAllocation.count

      ApplicationRecord.transaction do
        described_class.new(product, 5).call(dry_run: false, order_line: order_line)
        raise ActiveRecord::Rollback
      end

      expect(lot_a.reload.remaining_quantity).to eq(initial_remaining)
      expect(OrderLineLotAllocation.count).to eq(initial_alloc_count)
    end
  end
end
