# frozen_string_literal: true

require "rails_helper"

RSpec.describe Brand, type: :model do
  describe "validations" do
    subject { build(:brand) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe ".ransackable_attributes" do
    it "returns the allowed search attributes" do
      expect(described_class.ransackable_attributes).to include("name", "description", "remark")
    end
  end
end
