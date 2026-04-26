# frozen_string_literal: true

FactoryBot.define do
  factory :order_line_lot_allocation do
    association :order_line
    association :product_lot

    allocated_quantity { 5.0 }
    unit_cost          { 25.00 }

    trait :phantom do
      product_lot { nil }
      unit_cost   { 0 }
    end
  end
end
