FactoryBot.define do
  factory :supplier do
    sequence(:name) { |n| "Supplier #{n}" }
    telephone { "0812345678" }
    address { "123 Supplier Street" }
    remark { "Test remark" }
    is_active { true }
  end
end
