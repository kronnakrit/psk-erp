# frozen_string_literal: true

FactoryBot.define do
  factory :product_lot do
    association :product
    association :purchase_order
    sequence(:lot_number) { |n| "LOT-PO-#{n.to_s.rjust(4, '0')}-1" }
    received_date      { Date.current }
    original_quantity  { 100 }
    remaining_quantity { 100 }
    unit_cost          { 25.00 }
    status             { ProductLot::STATUS_ACTIVE }
  end
end
