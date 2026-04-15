FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    product_type { "Sa" }
    price        { 100.00 }
    cost         { 50.00 }
    enable_stock { false }

    trait :parent do
      product_type { "Pr" }
    end

    trait :child do
      product_type { "Ch" }
      association :parent, factory: :product, product_type: "Pr"
    end

    trait :with_vendor do
      association :vendor
    end

    trait :with_brand do
      association :brand
    end

    trait :with_product_class do
      association :product_class
    end
  end
end
