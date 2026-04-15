# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductClass, type: :model do
  describe "validations" do
    subject { build(:product_class) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end

RSpec.describe ProductCategory, type: :model do
  describe "validations" do
    subject { build(:product_category) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
