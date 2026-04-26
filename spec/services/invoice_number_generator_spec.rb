# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceNumberGenerator do
  subject(:generator) { described_class.new(date) }

  let(:date) { Date.new(2025, 3, 15) }
  let(:scope_double) { instance_double(ActiveRecord::Relation) }

  before do
    allow(Invoice).to receive(:where).with(invoice_date: date).and_return(scope_double)
  end

  describe "#call" do
    context "when no invoices exist for the date" do
      before do
        allow(scope_double).to receive(:count).and_return(0)
        allow(Invoice).to receive(:exists?).with(invoice_number: "INV-20250315001").and_return(false)
      end

      it "returns INV-YYYYMMDD001 format" do
        expect(generator.call).to eq("INV-20250315001")
      end
    end

    context "when 4 invoices already exist for the date" do
      before do
        allow(scope_double).to receive(:count).and_return(4)
        allow(Invoice).to receive(:exists?).with(invoice_number: "INV-20250315005").and_return(false)
      end

      it "starts from sequence 005" do
        expect(generator.call).to eq("INV-20250315005")
      end
    end

    context "when there is a collision on the first candidate" do
      before do
        allow(scope_double).to receive(:count).and_return(0)
        allow(Invoice).to receive(:exists?).with(invoice_number: "INV-20250315001").and_return(true)
        allow(Invoice).to receive(:exists?).with(invoice_number: "INV-20250315002").and_return(false)
      end

      it "loops until a unique number is found" do
        expect(generator.call).to eq("INV-20250315002")
      end
    end

    context "sequence resets per day" do
      let(:other_date) { Date.new(2025, 3, 16) }

      it "generates the correct prefix for a different day" do
        scope2 = instance_double(ActiveRecord::Relation)
        allow(Invoice).to receive(:where).with(invoice_date: other_date).and_return(scope2)
        allow(scope2).to receive(:count).and_return(0)
        allow(Invoice).to receive(:exists?).with(invoice_number: "INV-20250316001").and_return(false)

        result = described_class.new(other_date).call
        expect(result).to eq("INV-20250316001")
      end
    end
  end
end
