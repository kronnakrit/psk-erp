FactoryBot.define do
  factory :invoice_image do
    association :invoice
    position { 0 }
  end
end
