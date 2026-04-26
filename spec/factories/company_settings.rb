FactoryBot.define do
  factory :company_setting do
    company_name { "Test Company Ltd." }
    company_address { "1 Test Street" }
    company_telephone { "0800000000" }
    company_tax_id { "1234567890123" }
    company_email { "info@test.com" }
    company_website { "https://test.com" }
  end
end
