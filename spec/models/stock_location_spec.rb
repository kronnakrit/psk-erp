# frozen_string_literal: true

require "rails_helper"

RSpec.describe StockLocation, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  describe "uniqueness" do
    before { create(:stock_location, name: "Rack A") }

    it "is invalid with a duplicate name (case-insensitive)" do
      sl = build(:stock_location, name: "rack a")
      expect(sl).not_to be_valid
      expect(sl.errors[:name]).to include("has already been taken")
    end
  end

  describe ".ransackable_attributes" do
    it "returns expected attributes" do
      expect(StockLocation.ransackable_attributes).to include("name", "description")
    end
  end

  describe ".ransackable_associations" do
    it "returns expected associations" do
      expect(StockLocation.ransackable_associations).to be_an(Array)
    end
  end
end
