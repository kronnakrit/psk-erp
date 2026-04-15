FactoryBot.define do
  factory :order_audit do
    association :order
    event_type  { "field_update" }
    field_name  { "status" }
    previous_value { "Dr" }
    new_value      { "Pd" }
    changed_at  { Time.current }
    changed_by  { nil }
  end
end
