# frozen_string_literal: true

require "rails_helper"

RSpec.describe Attribute, type: :model do
  let(:product_class) { create(:product_class) }

  describe "validations" do
    subject { build(:attribute, product_class: product_class) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to belong_to(:product_class) }

    it "enforces uniqueness of name scoped to product_class" do
      create(:attribute, name: "Color", product_class: product_class)
      dup = build(:attribute, name: "Color", product_class: product_class)
      expect(dup).not_to be_valid
    end

    it "allows same name across different product classes" do
      other_class = create(:product_class)
      create(:attribute, name: "Color", product_class: product_class)
      attr2 = build(:attribute, name: "Color", product_class: other_class)
      expect(attr2).to be_valid
    end
  end
end
