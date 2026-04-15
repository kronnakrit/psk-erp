# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vendor, type: :model do
  describe "validations" do
    subject { build(:vendor) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_uniqueness_of(:initial_name).case_insensitive.allow_blank }
  end

  describe "#auto_set_initial_name" do
    context "when initial_name is blank on create" do
      it "auto-generates initial_name as name-id after create" do
        vendor = create(:vendor, name: "Acme Corp", initial_name: nil)
        expect(vendor.initial_name).to eq("Acme Corp-#{vendor.id}")
      end
    end

    context "when initial_name is already set" do
      it "does not overwrite the existing initial_name" do
        vendor = create(:vendor, name: "Acme Corp", initial_name: "ACME")
        expect(vendor.initial_name).to eq("ACME")
      end
    end
  end

  describe ".ransackable_attributes" do
    it "returns the allowed search attributes" do
      expect(described_class.ransackable_attributes).to include("name", "initial_name", "telephone")
    end
  end
end
