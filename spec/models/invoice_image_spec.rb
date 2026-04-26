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
end
