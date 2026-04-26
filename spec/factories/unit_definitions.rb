FactoryBot.define do
  factory :unit_definition do
    unit_group
    sequence(:name) { |n| "Unit #{n}" }
    ratio { 1 }
    is_migration_placeholder { false }
  end
end
