# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceImage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:invoice) }
  end

  describe "Active Storage" do
    it { is_expected.to have_one_attached(:image) }
    it { is_expected.to have_one_attached(:thumb_image) }
  end

  describe "after_create callback: generate_thumbnail (ImageCompressible)" do
    it "calls generate_thumbnail after create" do
      invoice       = create(:invoice)
      invoice_image = build(:invoice_image, invoice: invoice)
      expect(invoice_image).to receive(:generate_thumbnail)
      invoice_image.save!
    end
  end

  describe "image_content_type validation" do
    it "rejects disallowed content types" do
      invoice = create(:invoice)
      invoice_image = InvoiceImage.new(invoice: invoice)
      invoice_image.image.attach(
        io: StringIO.new("fake pdf"),
        filename: "doc.pdf",
        content_type: "application/pdf"
      )
      expect(invoice_image).not_to be_valid
      expect(invoice_image.errors[:image]).to be_present
    end

    it "allows JPEG content type" do
      invoice = create(:invoice)
      invoice_image = InvoiceImage.new(invoice: invoice)
      invoice_image.image.attach(
        io: StringIO.new("fake jpeg"),
        filename: "img.jpg",
        content_type: "image/jpeg"
      )
      expect(invoice_image.errors[:image]).to be_empty
    end
  end

  describe ".ransackable_attributes" do
    it "returns expected attributes" do
      expect(InvoiceImage.ransackable_attributes).to include("invoice_id", "position", "created_at")
    end
  end

  describe ".ransackable_associations" do
    it "returns expected associations" do
      expect(InvoiceImage.ransackable_associations).to include("invoice")
    end
  end

  describe "generate_thumbnail rescue path (ImageCompressible)" do
    it "logs a warning when thumbnail generation raises StandardError" do
      invoice = create(:invoice)
      invoice_image = InvoiceImage.new(invoice: invoice)
      invoice_image.image.attach(
        io: StringIO.new("fake jpeg"),
        filename: "img.jpg",
        content_type: "image/jpeg"
      )
      allow(invoice_image.image).to receive(:variant).and_raise(StandardError, "processing failed")
      expect(Rails.logger).to receive(:warn).with(/Thumbnail generation failed/)
      invoice_image.send(:generate_thumbnail)
    end
  end
end
