FactoryBot.define do
  factory :product_stock do
    association :branch
    association :product
    amount         { 0 }
    holding_amount { 0 }
  end
end
