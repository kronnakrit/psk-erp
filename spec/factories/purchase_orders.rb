# frozen_string_literal: true

FactoryBot.define do
  factory :purchase_order do
    association :supplier
    po_date { Time.zone.today }
    status  { "Dr" }
    remark  { nil }

    trait :confirmed do
      status { "Cf" }
    end

    trait :cancelled do
      status { "Cc" }
    end
  end
end
