FactoryBot.define do
  factory :product_class do
    sequence(:name) { |n| "Product Class #{n}" }
  end
end
