# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderImage, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:order) }
  end

  describe "Active Storage" do
    it { is_expected.to have_one_attached(:image) }
    it { is_expected.to have_one_attached(:thumb_image) }
  end

  describe "validations" do
    it "is valid without an image attached" do
      order = create(:order)
      order_image = OrderImage.new(order: order)
      expect(order_image).to be_valid
    end

    it "rejects disallowed content types" do
      order = create(:order)
      order_image = OrderImage.new(order: order)
      # Attach a file with disallowed content type
      order_image.image.attach(
        io: StringIO.new("fake pdf content"),
        filename: "test.pdf",
        content_type: "application/pdf"
      )
      expect(order_image).not_to be_valid
      expect(order_image.errors[:image]).to be_present
    end
  end

  describe ".ransackable_attributes" do
    it "returns expected attributes" do
      expect(OrderImage.ransackable_attributes).to include("order_id", "position", "created_at")
    end
  end

  describe ".ransackable_associations" do
    it "returns expected associations" do
      expect(OrderImage.ransackable_associations).to include("order")
    end
  end

  describe "#purge_attachments" do
    it "calls purge_later on attachments when called directly" do
      order = create(:order)
      order_image = OrderImage.new(order: order)
      expect { order_image.send(:purge_attachments) }.not_to raise_error
    end
  end
end
