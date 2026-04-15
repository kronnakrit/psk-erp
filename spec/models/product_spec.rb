# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product, type: :model do
  describe "validations" do
    it "is valid with required attributes" do
      product = build(:product)
      expect(product).to be_valid
    end

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:product_type) }
    it { is_expected.to validate_inclusion_of(:product_type).in_array(%w[Sa Pr Ch]) }
  end

  describe "SKU auto-generation" do
    it "auto-generates sku when blank on create" do
      product = create(:product, sku: nil)
      expect(product.sku).to be_present
    end

    it "uses vendor initial_name as prefix when vendor present" do
      vendor = create(:vendor, name: "ACME Corp")
      product = create(:product, :with_vendor, vendor: vendor, sku: nil)
      expect(product.sku).to start_with(vendor.initial_name)
    end

    it "does not overwrite explicit sku" do
      product = create(:product, sku: "MANUAL-SKU-001")
      expect(product.sku).to eq("MANUAL-SKU-001")
    end
  end

  describe "barcode auto-generation" do
    it "auto-generates barcode when blank on create" do
      product = create(:product, barcode: nil)
      expect(product.barcode).to be_present
    end

    it "does not overwrite explicit barcode" do
      product = create(:product, barcode: "ABC123")
      expect(product.barcode).to eq("ABC123")
    end
  end

  describe "#unique_name_for_non_child" do
    it "rejects duplicate name among Standalone products" do
      create(:product, name: "Widget", product_type: "Sa")
      dup = build(:product, name: "Widget", product_type: "Sa")
      expect(dup).not_to be_valid
      expect(dup.errors[:name]).to include("has already been taken")
    end

    it "rejects duplicate name among Parent products" do
      create(:product, name: "Widget", product_type: "Pr")
      dup = build(:product, name: "Widget", product_type: "Sa")
      expect(dup).not_to be_valid
    end

    it "allows duplicate name for Child products" do
      parent = create(:product, name: "Widget", product_type: "Pr")
      child = build(:product, name: "Widget", product_type: "Ch", parent: parent)
      expect(child).to be_valid
    end

    it "excludes self on update" do
      product = create(:product, name: "Widget", product_type: "Sa")
      expect(product.update(name: "Widget")).to be_truthy
    end
  end

  describe ".last_price_for" do
    it "returns the product price when no OrderLine exists" do
      product = create(:product, price: 250.0)
      expect(described_class.last_price_for(product_id: product.id, customer_id: 0)).to eq(250.0)
    end
  end

  describe "soft delete" do
    it "sets deleted_at on soft delete" do
      product = create(:product)
      product.soft_delete!
      expect(product.reload.deleted_at).to be_present
    end
  end

  describe ".ransackable_attributes" do
    it "includes expected fields" do
      expect(described_class.ransackable_attributes).to include("name", "sku", "barcode", "product_type")
    end
  end
end
