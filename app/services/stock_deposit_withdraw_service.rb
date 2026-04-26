# frozen_string_literal: true

# Converts a quantity expressed in a chosen UnitDefinition to base units,
# then delegates to ProductStock#deposit! or ProductStock#withdraw!
#
# Usage:
#   result = StockDepositWithdrawService.call(
#     stock: product_stock,
#     quantity: 2,
#     unit_definition_id: dozen.id,
#     action: :deposit,
#     reason: "purchase",
#     adjuster: current_user
#   )
#   result.success? # => true
#   result.base_amount # => 24
class StockDepositWithdrawService
  Result = Struct.new(:success, :base_amount, :error, keyword_init: true) do
    def success? = success
  end

  def self.call(...)
    new(...).call
  end

  def initialize(stock:, quantity:, unit_definition_id:, action:, reason: nil, adjuster: nil) # rubocop:disable Metrics/ParameterLists
    @stock              = stock
    @quantity           = quantity.to_d
    @unit_definition_id = unit_definition_id.to_i
    @action             = action.to_sym
    @reason             = reason.presence
    @adjuster           = adjuster
  end

  def call
    return Result.new(success: false, error: "Quantity must be greater than 0.") unless @quantity.positive?

    unit_def = find_unit_definition
    return Result.new(success: false, error: "Invalid unit for this product.") unless unit_def

    base_amount = (@quantity * unit_def.ratio).to_d

    case @action
    when :deposit
      @stock.deposit!(amount: base_amount, reason: @reason, adjuster: @adjuster)
    when :withdraw
      @stock.withdraw!(amount: base_amount, reason: @reason, adjuster: @adjuster)
    else
      return Result.new(success: false, error: "Unknown action.")
    end

    Result.new(success: true, base_amount: base_amount)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success: false, error: e.message)
  end

  private

  def find_unit_definition
    effective_group = @stock.product.effective_unit_group
    return nil unless effective_group

    effective_group.unit_definitions.find_by(id: @unit_definition_id)
  end
end
