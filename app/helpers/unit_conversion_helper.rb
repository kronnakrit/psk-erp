# frozen_string_literal: true

module UnitConversionHelper
  # Converts a raw base-unit amount into a human-readable biggest-unit-first string.
  #
  # Examples:
  #   format_stock_amount(37, unit_group)  # => "3 dozen 1 pcs"  (dozen=×12, pcs=×1)
  #   format_stock_amount(24, unit_group)  # => "2 dozen"
  #   format_stock_amount(200, unit_group) # => "1 gross 4 dozen 8 pcs"  (gross=×144)
  #
  # @param amount     [Numeric]         raw base-unit amount (can be decimal)
  # @param unit_group [UnitGroup, nil]  the product's effective unit group
  # @param legacy_unit_name [String, nil] fallback label when no unit_group is set
  # @return [String]
  def format_stock_amount(amount, unit_group, legacy_unit_name: nil)
    amount = amount.to_d

    unless unit_group&.unit_definitions&.any?
      # No unit group — fall back to raw number with legacy label
      label = legacy_unit_name.presence || ""
      return "#{number_with_precision(amount, precision: 2, strip_insignificant_zeros: true)} #{label}".strip +
             " ⚠️ No unit group"
    end

    definitions = unit_group.unit_definitions.sort_by { |ud| -ud.ratio }

    negative = amount < 0
    abs_amount = amount.abs
    integer_amount = abs_amount.to_i
    fractional     = abs_amount - integer_amount

    parts = []
    remaining = integer_amount

    definitions.each do |ud|
      next if ud.ratio <= 0

      count = remaining / ud.ratio
      remaining %= ud.ratio
      parts << "#{count} #{ud.name}" if count > 0
    end

    # Handle fractional sub-unit remainder to avoid silent data loss
    if fractional > 0
      base_unit = definitions.min_by(&:ratio)
      parts << "+#{number_with_precision(fractional, precision: 2, strip_insignificant_zeros: true)} #{base_unit&.name}"
    end

    # If everything is zero
    result = parts.empty? ? "0 #{definitions.min_by(&:ratio)&.name}" : parts.join(" ")
    negative ? "-#{result}" : result
  end
end
