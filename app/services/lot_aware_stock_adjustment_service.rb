# frozen_string_literal: true

# Adjusts aggregate ProductStock and a specific ProductLot in one transaction.
#
# Usage:
#   result = LotAwareStockAdjustmentService.call(
#     stock: product_stock,
#     product_lot: lot,
#     amount: 10,
#     action: :deposit,
#     reason: "restock",
#     adjuster: current_user
#   )
class LotAwareStockAdjustmentService
  Result = Struct.new(:success, :error, keyword_init: true) do
    def success? = success
  end

  def self.call(...)
    new(...).call
  end

  def initialize(stock:, product_lot:, amount:, action:, reason: nil, adjuster: nil) # rubocop:disable Metrics/ParameterLists
    @stock        = stock
    @product_lot  = product_lot
    @amount       = amount.to_d
    @action       = action.to_sym
    @reason       = reason.presence
    @adjuster     = adjuster
  end

  def call
    return failure(I18n.t("stocks.adjustment.amount_must_be_positive")) unless @amount.positive?
    return failure(I18n.t("stocks.adjustment.lot_product_mismatch")) unless @product_lot.product_id == @stock.product_id

    withdraw_error = withdraw_validation_error
    return failure(withdraw_error) if withdraw_error

    ActiveRecord::Base.transaction do
      adjust_lot_remaining!
      adjust_stock!
    end

    Result.new(success: true)
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def withdraw_validation_error
    return nil unless @action == :withdraw

    if @amount > @product_lot.remaining_quantity
      return I18n.t("stocks.adjustment.insufficient_lot_quantity",
                    amount: @amount,
                    available: @product_lot.remaining_quantity)
    end

    return nil if @amount <= @stock.total_amount

    I18n.t("stocks.adjustment.insufficient_available_stock",
           amount: @amount,
           available: @stock.total_amount)
  end

  def adjust_lot_remaining!
    @product_lot.with_lock do
      delta = @action == :deposit ? @amount : -@amount
      new_qty = @product_lot.remaining_quantity + delta
      @product_lot.update!(remaining_quantity: new_qty)
    end
  end

  def adjust_stock!
    case @action
    when :deposit
      @stock.deposit!(amount: @amount, reason: @reason, related_object: @product_lot, adjuster: @adjuster)
    when :withdraw
      @stock.withdraw!(amount: @amount, reason: @reason, related_object: @product_lot, adjuster: @adjuster)
    end
  end

  def failure(message)
    Result.new(success: false, error: message)
  end
end
