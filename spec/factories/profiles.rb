FactoryBot.define do
  factory :profile do
    association :user
    role { nil }
    first_name { "John" }
    last_name { "Doe" }
    address { "123 Main St" }
    remark { nil }
    telephone { "080-000-0000" }
  end
end
