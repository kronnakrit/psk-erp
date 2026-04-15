require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:role).optional }
  end

  describe "#full_name" do
    it "returns first and last name joined" do
      profile = build(:profile, first_name: "Jane", last_name: "Smith")
      expect(profile.full_name).to eq("Jane Smith")
    end

    it "strips whitespace when a name part is blank" do
      profile = build(:profile, first_name: "Jane", last_name: "")
      expect(profile.full_name).to eq("Jane")
    end

    it "returns empty string when both names are blank" do
      profile = build(:profile, first_name: "", last_name: "")
      expect(profile.full_name).to eq("")
    end
  end
end
