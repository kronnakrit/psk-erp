# frozen_string_literal: true

# MarkDuplicateOrdersJob evaluates whether an order is a probable duplicate
# of another recent non-cancelled order for the same customer and persists
# the result as is_possible_duplicate on both the subject and candidate orders.
class MarkDuplicateOrdersJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.includes(:order_lines).find(order_id)
    candidates = DuplicateOrderDetectionService.new.call(order: order)

    if candidates.any?
      order.update_columns(is_possible_duplicate: true) # rubocop:disable Rails/SkipsModelValidations
      Order.where(id: candidates.map(&:id))
           .update_all(is_possible_duplicate: true) # rubocop:disable Rails/SkipsModelValidations
    else
      order.update_columns(is_possible_duplicate: false) # rubocop:disable Rails/SkipsModelValidations
    end
  rescue ActiveRecord::RecordNotFound
    # Order was deleted between enqueue and execution; nothing to do
    nil
  end
end
