# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductAttribute, type: :model do
  let(:product_class) { create(:product_class) }
  let(:product)       { create(:product, product_class: product_class) }
  let(:attribute)     { create(:attribute, product_class: product_class) }

  describe "validations" do
    it "is valid with product and attribute" do
      pa = described_class.new(product: product, attribute_id: attribute.id, value: "Blue")
      expect(pa).to be_valid
    end

    it "is invalid without product_id" do
      pa = described_class.new(attribute_id: attribute.id, value: "Blue")
      expect(pa).not_to be_valid
    end

    it "enforces uniqueness of attribute_id scoped to product_id" do
      described_class.create!(product: product, attribute_id: attribute.id, value: "Red")
      pa2 = described_class.new(product: product, attribute_id: attribute.id, value: "Blue")
      expect(pa2).not_to be_valid
    end
  end
end
