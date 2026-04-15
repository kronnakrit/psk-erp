# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductCategory, type: :model do
  describe "validations" do
    it "is valid with a unique name" do
      expect(build(:product_category)).to be_valid
    end

    it "is invalid without a name" do
      expect(described_class.new).not_to be_valid
    end

    it "is invalid with a duplicate name" do
      create(:product_category, name: "Tops")
      expect(described_class.new(name: "Tops")).not_to be_valid
    end
  end
end
