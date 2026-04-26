FactoryBot.define do
  factory :order do
    association :customer
    association :created_by, factory: :user

    running_date         { Time.zone.today }
    status               { "Dr" }
    # logistic_status removed in migration 20260418161726
    has_vat              { false }
    is_included_vat      { false }
    is_withholding_tax   { false }
    withholding_tax      { 3 }
    is_discount_percentage { false }
    discount_price       { 0 }
    discount_percentage  { 0 }

    trait :with_vat do
      has_vat { true }
    end

    trait :with_included_vat do
      has_vat         { true }
      is_included_vat { true }
    end

    trait :with_withholding_tax do
      is_withholding_tax { true }
      withholding_tax    { 3 }
    end

    trait :paid do
      status { "Pd" }
    end

    trait :completed do
      status { "Cp" }
    end

    trait :cancelled do
      status { "Cc" }
    end
  end
end
