# frozen_string_literal: true

# Absorbs phantom (nil-lot) OrderLineLotAllocation records into a newly created ProductLot.
#
# When a PO is confirmed and a real lot is created, existing order lines that were
# created with no available stock (phantom allocations) can be retroactively assigned
# to the new lot (oldest order line first) up to the lot's available capacity.
#
# Usage:
#   PhantomAllocationAbsorberService.new(product, lot).call
class PhantomAllocationAbsorberService
  def initialize(product, lot)
    @product = product
    @lot     = lot
  end

  def call
    return unless @product.enable_stock?

    phantom_allocations.each do |alloc|
      break if @lot.remaining_quantity <= 0

      absorb!(alloc)
    end
  end

  private

  # Phantom allocations ordered by the creating order_line's created_at (oldest first)
  def phantom_allocations
    OrderLineLotAllocation
      .joins(:order_line)
      .where(product_lot_id: nil)
      .where(order_lines: { product_id: @product.id })
      .order("order_lines.created_at ASC")
      .includes(:order_line)
  end

  def absorb!(alloc)
    original_qty = alloc.allocated_quantity.to_d
    absorb_qty   = [original_qty, @lot.remaining_quantity.to_d].min

    ApplicationRecord.transaction do
      # Replace phantom allocation with real lot allocation
      alloc.update!(
        product_lot: @lot,
        allocated_quantity: absorb_qty,
        unit_cost: @lot.unit_cost
      )

      # Decrement the lot's remaining quantity
      @lot.update!(remaining_quantity: @lot.remaining_quantity.to_d - absorb_qty)

      # Recalculate COGS for the affected order line
      recalculate_cogs!(alloc.order_line)

      # If only partially absorbed, create a new phantom for the remainder
      remainder = original_qty - absorb_qty
      if remainder.positive?
        alloc.order_line.order_line_lot_allocations.create!(
          product_lot_id: nil,
          allocated_quantity: remainder,
          unit_cost: 0
        )
      end
    end
  end

  def recalculate_cogs!(order_line)
    allocs       = order_line.order_line_lot_allocations.reload
    total_qty    = allocs.sum { |a| a.allocated_quantity.to_d }
    total_cost   = allocs.sum { |a| a.allocated_quantity.to_d * a.unit_cost.to_d }
    new_cogs     = total_qty.zero? ? BigDecimal("0") : (total_cost / total_qty).round(2)

    order_line.update_column(:cogs, new_cogs) # rubocop:disable Rails/SkipsModelValidations
  end
end
