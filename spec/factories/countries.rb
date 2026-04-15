FactoryBot.define do
  factory :country do
    sequence(:iso_3166_1_a2) { |n| format("%02d", n % 100).tr("0-9", "A-Z")[0..1] }
    iso_3166_1_a3 { "#{iso_3166_1_a2}X" }
    iso_3166_1_numeric { "001" }
    printable_name { "Test Country #{iso_3166_1_a2}" }
    name { "TEST COUNTRY #{iso_3166_1_a2}" }
  end

  factory :country_th, class: "Country" do
    iso_3166_1_a2 { "TH" }
    iso_3166_1_a3 { "THA" }
    iso_3166_1_numeric { "764" }
    printable_name { "Thailand" }
    name { "THAILAND" }
  end
end
