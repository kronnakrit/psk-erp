# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnitGroup do
  describe "associations" do
    it { is_expected.to have_many(:unit_definitions).dependent(:destroy) }
    it { is_expected.to have_many(:products) }
  end

  describe "validations" do
    subject { build(:unit_group) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe "AC-01 & AC-02: Default unit group behavior" do
    it "allows saving a default group if it has a base unit (AC-01)" do
      group = build(:unit_group, is_default: true)
      group.unit_definitions.build(name: "pcs", ratio: 1)
      expect(group).to be_valid
      expect(group.save).to be true
      expect(described_class.where(is_default: true).count).to eq(1)
    end

    it "fails validation if trying to set as default without a base unit" do
      group = build(:unit_group, is_default: true)
      expect(group).not_to be_valid
      expect(group.errors.full_messages).to include(/Cannot set as default: group has no base unit/)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "only allows exactly one default group at all times (AC-02)" do
      group1 = create(:unit_group, :with_base_unit, is_default: true)
      expect(group1.reload.is_default).to be true

      group2 = create(:unit_group, :with_base_unit, is_default: true)

      expect(group2.reload.is_default).to be true
      expect(group1.reload.is_default).to be false
      expect(described_class.where(is_default: true).count).to eq(1)
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe "AC-06 & AC-07: Destroy behavior" do
    it "blocks destroy if assigned to products (AC-06)" do
      group = create(:unit_group)
      create(:product, unit_group: group)

      expect(group.destroy).to be_falsey
      expect(group.errors.full_messages).to include(/Cannot delete a unit group that is assigned to products/)
      expect(described_class.exists?(group.id)).to be true
    end

    it "destroys cascades to unit_definitions when no products linked (AC-07)" do
      group = create(:unit_group)
      create(:unit_definition, unit_group: group, ratio: 1)
      create(:unit_definition, unit_group: group, ratio: 12, name: "dozen")

      expect { group.destroy }.to change(described_class, :count).by(-1)
                                                                 .and change(UnitDefinition, :count).by(-2)
    end
  end
end
