FactoryBot.define do
  factory :user do
    sequence(:email)              { |n| "user#{n}@example.com" }
    sequence(:username)           { |n| "user#{n}" }
    password                      { "Password1!" }
    password_confirmation         { "Password1!" }
    is_active                     { true }

    trait :inactive do
      is_active { false }
    end
  end
end
