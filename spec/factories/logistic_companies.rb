FactoryBot.define do
  factory :logistic_company do
    sequence(:name) { |n| "Logistic Co #{n}" }
    telephone { "0812345678" }
    address { "123 Test Street" }
    remark { "Test remark" }
  end
end
