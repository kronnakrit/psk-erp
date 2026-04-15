FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    permissions { [] }
    group_id { nil }

    trait :admin do
      name { "Admin" }
      permissions { Permissions::ALL }
    end
  end
end
