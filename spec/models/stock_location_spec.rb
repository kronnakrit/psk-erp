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
end
