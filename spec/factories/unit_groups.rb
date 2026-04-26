FactoryBot.define do
  factory :unit_group do
    sequence(:name) { |n| "Unit Group #{n}" }
    is_default { false }

    trait :with_base_unit do
      after(:build) do |group|
        group.unit_definitions << build(:unit_definition, unit_group: group, ratio: 1)
      end
    end
    
    trait :default do
      is_default { true }
      with_base_unit
    end
  end
end
