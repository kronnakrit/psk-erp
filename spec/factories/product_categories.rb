FactoryBot.define do
  factory :product_category do
    sequence(:name) { |n| "Category #{n}" }
  end
end
