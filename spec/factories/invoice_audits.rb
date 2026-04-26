FactoryBot.define do
  factory :invoice_audit do
    association :invoice
    association :changed_by, factory: :user

    event_type     { "status_change" }
    previous_value { "Dr" }
    new_value      { "Pd" }
    changed_at     { Time.current }
  end
end
