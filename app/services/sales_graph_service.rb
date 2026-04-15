# frozen_string_literal: true

# Aggregates orders by month and status for charting.
# Returns JSON-ready hash with keys :draft, :paid, :completed, :cancelled,
# each an array of { year:, month:, grand_total__sum: }.
class SalesGraphService
  STATUS_KEYS = {
    "Dr" => :draft,
    "Pd" => :paid,
    "Cp" => :completed,
    "Cc" => :cancelled
  }.freeze

  def initialize(start_date:, end_date:)
    @start_date = start_date
    @end_date   = end_date
  end

  def call
    result = STATUS_KEYS.values.index_with { [] }

    STATUS_KEYS.each do |status_code, key|
      grouped = Order.where(status: status_code, running_date: @start_date..@end_date)
                     .group_by_month(:running_date, range: @start_date..@end_date)
                     .sum(:grand_total)

      result[key] = grouped.map do |date, total|
        { year: date.year, month: date.month, grand_total__sum: total.to_f }
      end
    end

    result
  end
end
