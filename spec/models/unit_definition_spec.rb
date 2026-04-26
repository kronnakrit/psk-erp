# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnitDefinition do
  describe "associations" do
    it { is_expected.to belong_to(:unit_group) }
  end

  describe "validations" do
    subject { build(:unit_definition) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:ratio) }
    it { is_expected.to validate_numericality_of(:ratio).only_integer.is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:unit_group_id).case_insensitive }
  end

  describe "AC-03: Create valid definition" do
    it "persists successfully" do
      group = create(:unit_group)
      definition = group.unit_definitions.build(name: "pcs", ratio: 1)
      expect(definition).to be_valid
      expect { definition.save }.to change(described_class, :count).by(1)
    end
  end

  describe "AC-04: Ratio zero is rejected" do
    it "rejects ratio 0" do
      definition = build(:unit_definition, ratio: 0)
      expect(definition).not_to be_valid
      expect(definition.errors[:ratio]).to include("must be greater than 0")
    end
  end

  describe "AC-05: Ratio 1 uniqueness within group" do
    it "rejects a second ratio 1 if not a migration placeholder" do
      group = create(:unit_group)
      create(:unit_definition, unit_group: group, ratio: 1, name: "pcs")

      second_base = group.unit_definitions.build(ratio: 1, name: "pack", is_migration_placeholder: false)
      expect(second_base).not_to be_valid
      expect(second_base.errors[:ratio]).to include("1 already exists in this unit group")
    end

    it "allows a second ratio 1 if it IS a migration placeholder" do
      group = create(:unit_group)
      create(:unit_definition, unit_group: group, ratio: 1, name: "pcs")

      second_base = group.unit_definitions.build(ratio: 1, name: "pack", is_migration_placeholder: true)
      expect(second_base).to be_valid
      expect { second_base.save }.to change(described_class, :count).by(1)
    end

    it "allows same ratio for > 1 values (e.g. 12 dozen and 12 box)" do
      group = create(:unit_group)
      create(:unit_definition, unit_group: group, ratio: 12, name: "dozen")

      box = group.unit_definitions.build(ratio: 12, name: "box")
      expect(box).to be_valid
    end
  end
end
