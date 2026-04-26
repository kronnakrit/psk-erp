# frozen_string_literal: true

class ConfirmPurchaseOrderService
  class Error < StandardError
  end

  def initialize(purchase_order)
    @purchase_order = purchase_order
  end

  # Returns number of lots created on success.
  # Raises ConfirmPurchaseOrderService::Error on business-rule violation.
  def call!
    validate_state!

    lots_count = 0
    ApplicationRecord.transaction do
      @purchase_order.purchase_order_lines.includes(:product, :unit_definition).each_with_index do |line, idx|
        lot = create_lot!(line, idx + 1)
        deposit_stock!(line, lot)
        PhantomAllocationAbsorberService.new(line.product, lot).call if line.product.enable_stock?
        lots_count += 1
      end
      @purchase_order.update!(status: "Cf")
    end
    lots_count
  end

  private

  def validate_state!
    raise Error, "Purchase order is already confirmed." if @purchase_order.confirmed?
    raise Error, "Cannot confirm a cancelled purchase order." if @purchase_order.cancelled?
    return unless @purchase_order.purchase_order_lines.empty?

    raise Error, "Cannot confirm a purchase order with no lines."
  end

  def create_lot!(line, index)
    base_quantity = line.quantity * line.unit_definition.ratio
    ProductLot.create!(
      product: line.product,
      purchase_order: @purchase_order,
      lot_number: "LOT-#{@purchase_order.po_number}-#{index}",
      received_date: Date.current,
      original_quantity: base_quantity,
      remaining_quantity: base_quantity,
      unit_cost: line.unit_cost,
      status: ProductLot::STATUS_ACTIVE
    )
  end

  def deposit_stock!(line, lot)
    return unless line.product.enable_stock?

    stock = ProductStock.find_or_create_for!(product: line.product)
    stock.deposit!(
      amount: lot.original_quantity,
      reason: "PO #{@purchase_order.po_number}",
      related_object: lot
    )
  end
end
