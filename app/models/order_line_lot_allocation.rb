# frozen_string_literal: true

class OrderLineLotAllocation < ApplicationRecord
  belongs_to :order_line
  belongs_to :product_lot, optional: true # nil for phantom (negative-stock) allocations

  validates :allocated_quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
