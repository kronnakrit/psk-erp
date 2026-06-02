FactoryBot.define do
  factory :customer do
    sequence(:first_name) { |n| "Customer#{n}" }
    last_name { "Doe" }
    address { "123 Test Road" }
    remark { nil }
    telephones { ["0891234567"] }
    country_id { nil }
    logistic_company_id { nil }
    deleted_at { nil }
  end
end
