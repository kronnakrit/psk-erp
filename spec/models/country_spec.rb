require "rails_helper"

RSpec.describe Country, type: :model do
  describe "validations" do
    subject { build(:country_th) }

    it { is_expected.to validate_presence_of(:iso_3166_1_a2) }
    it { is_expected.to validate_uniqueness_of(:iso_3166_1_a2).case_insensitive }
    it { is_expected.to validate_length_of(:iso_3166_1_a2).is_equal_to(2) }
    it { is_expected.to validate_presence_of(:printable_name) }
  end

  describe "primary key" do
    it "uses iso_3166_1_a2 as primary key" do
      country = create(:country_th)
      expect(described_class.find("TH")).to eq(country)
    end
  end
end
