# frozen_string_literal: true

# Computes FIFO lot allocation for a given product and base quantity.
#
# Usage:
#   result = FifoLotAllocationService.new(product, 12).call(dry_run: true)
#   result = FifoLotAllocationService.new(product, 12).call(dry_run: false, order_line: ol)
#
# Result struct fields:
#   allocations       - Array of AllocationEntry (lot, qty, unit_cost)
#   weighted_avg_cost - Decimal, weighted avg unit cost across all lots consumed
#   phantom_qty       - Decimal, portion not covered by real lots (negative-stock)
class FifoLotAllocationService
  Result = Struct.new(:allocations, :weighted_avg_cost, :phantom_qty, keyword_init: true)
  AllocationEntry = Struct.new(:lot, :qty, :unit_cost, keyword_init: true)

  def initialize(product, base_quantity)
    @product       = product
    @base_quantity = base_quantity.to_d
  end

  # @param dry_run [Boolean] when true, no DB writes occur
  # @param order_line [OrderLine, nil] required when dry_run: false
  # @return [Result]
  def call(dry_run: true, order_line: nil)
    allocations = build_allocations
    phantom_qty = [@base_quantity - allocated_total(allocations), BigDecimal("0")].max
    weighted    = weighted_avg_cost(allocations, phantom_qty)

    persist_allocations!(allocations, phantom_qty, order_line) unless dry_run

    Result.new(allocations: allocations, weighted_avg_cost: weighted, phantom_qty: phantom_qty)
  end

  private

  def build_allocations
    remaining = @base_quantity
    entries   = []

    active_lots.each do |lot|
      break if remaining <= 0

      consume = [lot.remaining_quantity.to_d, remaining].min
      entries << AllocationEntry.new(lot: lot, qty: consume, unit_cost: lot.unit_cost.to_d)
      remaining -= consume
    end

    entries
  end

  def active_lots
    @product.product_lots
            .where(status: ProductLot::STATUS_ACTIVE)
            .where("remaining_quantity > 0")
            .order(:received_date, :id)
  end

  def allocated_total(allocations)
    allocations.sum(&:qty)
  end

  def weighted_avg_cost(allocations, _phantom_qty)
    return BigDecimal("0") if @base_quantity.zero?

    total_cost = allocations.sum { |e| e.qty * e.unit_cost }
    (total_cost / @base_quantity).round(2)
  end

  def persist_allocations!(allocations, phantom_qty, order_line)
    raise ArgumentError, "order_line is required when dry_run: false" if order_line.nil?

    ApplicationRecord.transaction do
      allocations.each do |entry|
        new_qty = entry.lot.remaining_quantity.to_d - entry.qty
        entry.lot.update!(remaining_quantity: new_qty)
        order_line.order_line_lot_allocations.create!(
          product_lot: entry.lot,
          allocated_quantity: entry.qty,
          unit_cost: entry.unit_cost
        )
      end

      if phantom_qty.positive?
        order_line.order_line_lot_allocations.create!(
          product_lot_id: nil,
          allocated_quantity: phantom_qty,
          unit_cost: 0
        )
      end
    end
  end
end
