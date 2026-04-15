FactoryBot.define do
  factory :vendor do
    sequence(:name) { |n| "Vendor #{n}" }
    initial_name { nil }
    description { nil }
    address { nil }
    remark { nil }
    telephone { nil }
  end
end
