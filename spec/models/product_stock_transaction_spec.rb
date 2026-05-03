# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductStockTransaction, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:product_stock) }
    it { is_expected.to belong_to(:adjuster).optional }
    it { is_expected.to belong_to(:related_object).optional }
  end

  describe "validations" do
    let(:stock) { create(:product_stock) }

    it "is valid with valid attributes" do
      t = ProductStockTransaction.new(product_stock: stock, transaction_type: "IB", amount: 5)
      expect(t).to be_valid
    end

    it "rejects invalid transaction_type" do
      t = ProductStockTransaction.new(product_stock: stock, transaction_type: "XX", amount: 5)
      expect(t).not_to be_valid
    end

    it "rejects zero amount" do
      t = ProductStockTransaction.new(product_stock: stock, transaction_type: "IB", amount: 0)
      expect(t).not_to be_valid
    end

    it "rejects negative amount" do
      t = ProductStockTransaction.new(product_stock: stock, transaction_type: "OB", amount: -1)
      expect(t).not_to be_valid
    end
  end

  describe ".ransackable_attributes" do
    it "includes expected attributes" do
      expect(described_class.ransackable_attributes).to include("transaction_type", "amount", "reason")
    end
  end

  describe ".ransackable_associations" do
    it "includes product_stock" do
      expect(described_class.ransackable_associations).to include("product_stock")
    end
  end
end
