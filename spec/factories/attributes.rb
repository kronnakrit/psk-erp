FactoryBot.define do
  factory :attribute do
    sequence(:name) { |n| "Attribute #{n}" }
    association :product_class
  end
end
