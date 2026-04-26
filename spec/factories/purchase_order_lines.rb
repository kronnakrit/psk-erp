# frozen_string_literal: true

FactoryBot.define do
  factory :purchase_order_line do
    association :purchase_order
    association :product
    association :unit_definition
    quantity  { 10 }
    unit_cost { 25.00 }
  end
end
