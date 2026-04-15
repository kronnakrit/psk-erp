FactoryBot.define do
  factory :product_image do
    association :product
    position { 0 }
  end
end
