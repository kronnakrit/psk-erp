FactoryBot.define do
  factory :stock_location do
    sequence(:name) { |n| "Location #{n}" }
    description { "Test location" }
  end
end
