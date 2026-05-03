# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductImage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:product) }
  end

  describe "Active Storage" do
    it { is_expected.to have_one_attached(:image) }
    it { is_expected.to have_one_attached(:thumb_image) }
  end

  describe "image_content_type validation" do
    let(:product) { create(:product) }

    it "rejects disallowed content types" do
      product_image = ProductImage.new(product: product)
      product_image.image.attach(
        io: StringIO.new("fake pdf"),
        filename: "doc.pdf",
        content_type: "application/pdf"
      )
      expect(product_image).not_to be_valid
      expect(product_image.errors[:image]).to be_present
    end

    it "allows PNG content type" do
      product_image = ProductImage.new(product: product)
      product_image.image.attach(
        io: StringIO.new("fake png"),
        filename: "img.png",
        content_type: "image/png"
      )
      expect(product_image.errors[:image]).to be_empty
    end
  end

  describe ".ransackable_attributes" do
    it "returns expected attributes" do
      expect(ProductImage.ransackable_attributes).to include("product_id", "position", "created_at")
    end
  end

  describe ".ransackable_associations" do
    it "returns expected associations" do
      expect(ProductImage.ransackable_associations).to include("product")
    end
  end
end
