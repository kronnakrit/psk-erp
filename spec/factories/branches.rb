FactoryBot.define do
  factory :branch do
    sequence(:name) { |n| "Branch #{n}" }

    trait :main do
      name { "Main Branch" }
    end
  end
end
