FactoryBot.define do
  factory :invoice_order do
    association :invoice
    association :order
  end
end
