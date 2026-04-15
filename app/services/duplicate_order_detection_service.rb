# frozen_string_literal: true

# DuplicateOrderDetectionService determines whether an order is a probable duplicate
# of another recent non-cancelled order for the same customer.
#
# Two orders are considered duplicates if:
# - Same customer_id
# - running_dates are within 7 days of each other
# - At least one shared product_id across their order_lines
# - Neither order has status "Cc" (Cancelled)
#
# Usage:
#   DuplicateOrderDetectionService.new.call(order: order)
#   => Array of matching Order records (candidates)
class DuplicateOrderDetectionService
  WINDOW_DAYS = 7

  def call(order:)
    return [] if order.status == "Cc"
    return [] if order.order_lines.empty?

    product_ids    = order.order_lines.pluck(:product_id)
    date_range     = (order.running_date - WINDOW_DAYS.days)..(order.running_date + WINDOW_DAYS.days)

    candidates = Order
                 .where(customer_id: order.customer_id)
                 .where.not(id: order.id)
                 .where.not(status: "Cc")
                 .where(running_date: date_range)

    candidates.select do |candidate|
      candidate.order_lines.pluck(:product_id).intersect?(product_ids)
    end
  end
end
