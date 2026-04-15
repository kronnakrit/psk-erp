FactoryBot.define do
  factory :brand do
    sequence(:name) { |n| "Brand #{n}" }
    description { nil }
    remark { nil }
  end
end
