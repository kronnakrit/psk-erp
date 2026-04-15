FactoryBot.define do
  factory :order_line do
    association :order
    association :product

    unit        { "Pc" }
    quantity    { 2 }
    unit_price  { 100.00 }
    discount_price { 0 }
    idx { 0 }

    trait :with_discount do
      discount_price { 20.00 }
    end
  end
end
