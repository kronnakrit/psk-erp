# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseOrderNumberGenerator do
  let(:today) { Date.new(2026, 1, 15) }

  describe "#call" do
    context "when no POs exist for today" do
      it "generates PO-YYYYMMDD-0001 format" do
        result = described_class.new(today).call
        expect(result).to eq("PO-20260115-0001")
      end
    end

    context "when one PO already exists for today" do
      let(:supplier) { create(:supplier) }
      let!(:existing_po) do
        PurchaseOrder.create!(
          po_date: today,
          po_number: "PO-20260115-0001",
          status: "Dr",
          supplier: supplier
        )
      end

      it "generates the next number" do
        result = described_class.new(today).call
        expect(result).to eq("PO-20260115-0002")
      end
    end

    context "with collision avoidance" do
      let(:supplier) { create(:supplier) }

      it "skips taken numbers" do
        PurchaseOrder.create!(po_date: today, po_number: "PO-20260115-0001", status: "Dr", supplier: supplier)
        PurchaseOrder.create!(po_date: today, po_number: "PO-20260115-0002", status: "Dr", supplier: supplier)
        result = described_class.new(today).call
        expect(result).to eq("PO-20260115-0003")
      end

      it "increments count when po_number is taken by a different-date PO" do
        # A PO for a different date uses the same number (forces loop to iterate)
        PurchaseOrder.create!(po_date: today - 1.day, po_number: "PO-20260115-0001", status: "Dr", supplier: supplier)
        result = described_class.new(today).call
        expect(result).to eq("PO-20260115-0002")
      end
    end
  end
end
