# frozen_string_literal: true

require "rails_helper"

RSpec.describe Branch, type: :model do
  describe "validations" do
    subject { build(:branch) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe ".default" do
    context "when Main Branch exists" do
      it "returns Main Branch" do
        branch = create(:branch, :main)
        expect(described_class.default).to eq(branch)
      end
    end

    context "when Main Branch does not exist" do
      it "returns the first branch" do
        branch = create(:branch, name: "Warehouse A")
        expect(described_class.default).to eq(branch)
      end
    end
  end
end
