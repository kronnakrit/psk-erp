# frozen_string_literal: true

require "rails_helper"

RSpec.describe Supplier, type: :model do
  describe "validations" do
    subject { build(:supplier) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "associations" do
    # has_many :purchase_orders is verified in spec/models/purchase_order_spec.rb
    # once PurchaseOrder is created in STORY-16-02
    it "responds to purchase_orders" do
      expect(described_class.new).to respond_to(:purchase_orders)
    end
  end

  describe "destroy" do
    let!(:supplier) { create(:supplier) }

    it "destroys successfully when no purchase orders" do
      expect { supplier.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
