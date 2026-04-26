# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseOrder, type: :model do
  describe "validations" do
    subject { create(:purchase_order) }

    it { is_expected.to validate_presence_of(:po_date) }
    it { is_expected.to validate_presence_of(:po_number) }
    it { is_expected.to validate_uniqueness_of(:po_number) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:supplier) }
  end

  describe "po_number generation" do
    it "auto-generates po_number before validation on create" do
      po = build(:purchase_order, po_number: nil, po_date: Date.new(2026, 4, 18))
      po.valid?
      expect(po.po_number).to match(/\APO-20260418-\d{4}\z/)
    end

    it "does not overwrite an explicitly set po_number" do
      po = build(:purchase_order, po_number: "PO-CUSTOM-001")
      po.valid?
      expect(po.po_number).to eq("PO-CUSTOM-001")
    end
  end

  describe "destroy guard" do
    it "allows destroying a draft PO" do
      po = create(:purchase_order)
      expect { po.destroy }.to change(described_class, :count).by(-1)
    end

    it "prevents destroying a confirmed PO" do
      po = create(:purchase_order, :confirmed)
      po.destroy
      expect(described_class).to exist(po.id)
      expect(po.errors[:base]).to include("Cannot delete a confirmed purchase order")
    end
  end

  describe "status helpers" do
    it "returns true for draft? when status is Dr" do
      expect(build(:purchase_order, status: "Dr").draft?).to be true
    end

    it "returns true for confirmed? when status is Cf" do
      expect(build(:purchase_order, status: "Cf").confirmed?).to be true
    end

    it "returns true for cancelled? when status is Cc" do
      expect(build(:purchase_order, status: "Cc").cancelled?).to be true
    end
  end
end
