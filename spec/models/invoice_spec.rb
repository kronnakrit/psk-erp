# frozen_string_literal: true

require "rails_helper"

RSpec.describe Invoice, type: :model do
  subject(:invoice) { build(:invoice) }

  describe "associations" do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to belong_to(:created_by).class_name("User").optional(true) }
    it { is_expected.to belong_to(:updated_by).class_name("User").optional(true) }
    it { is_expected.to have_many(:invoice_orders).dependent(:destroy) }
    it { is_expected.to have_many(:orders).through(:invoice_orders) }
    it { is_expected.to have_many(:invoice_audits).dependent(:destroy) }
    it { is_expected.to have_many(:invoice_images).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:status).in_array(Invoice::STATUSES) }
    it { is_expected.to validate_presence_of(:invoice_date) }

    it "requires invoice_number to be present (enforced at DB level; callback generates it on create)" do
      inv = create(:invoice)
      inv.invoice_number = nil
      expect(inv).not_to be_valid
      expect(inv.errors[:invoice_number]).to be_present
    end

    context "invoice_number uniqueness" do
      it "is invalid when another invoice has the same number" do
        create(:invoice, invoice_number: "INV-20240101001")
        duplicate = build(:invoice, invoice_number: "INV-20240101001")
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:invoice_number]).to be_present
      end
    end

    context "status inclusion (AC-04)" do
      it "is valid with each allowed status" do
        Invoice::STATUSES.each do |s|
          invoice.status = s
          expect(invoice).to be_valid, "Expected #{s} to be valid"
        end
      end

      it "is invalid with an unknown status" do
        invoice.status = "XX"
        expect(invoice).not_to be_valid
        expect(invoice.errors[:status]).to be_present
      end
    end

    context "status_immutable_when_cancelled" do
      it "prevents changing status of a cancelled invoice" do
        cancelled = create(:invoice, :cancelled)
        cancelled.status = "Dr"
        expect(cancelled).not_to be_valid
        expect(cancelled.errors[:status]).to be_present
      end

      it "allows changing status of a non-cancelled invoice" do
        draft = create(:invoice)
        draft.status = "Pd"
        expect(draft).to be_valid
      end
    end
  end

  describe "callbacks (AC-01)" do
    describe "#generate_invoice_number" do
      it "assigns an INV-YYYYMMDD### number before create" do
        inv = create(:invoice)
        expect(inv.invoice_number).to match(/\AINV-\d{8}\d{3}\z/)
      end

      it "does not overwrite an explicit invoice_number" do
        inv = create(:invoice, invoice_number: "INV-20240101099")
        expect(inv.invoice_number).to eq("INV-20240101099")
      end
    end

    it "defaults status to 'Dr'" do
      inv = build(:invoice)
      expect(inv.status).to eq("Dr")
    end
  end

  describe "#recalculate_total! (AC-02)" do
    it "sets total_amount to the sum of associated orders' grand_total" do
      inv = create(:invoice)
      order1 = create(:order, grand_total: 100.0)
      order2 = create(:order, grand_total: 250.0)
      inv.orders << order1 << order2

      inv.recalculate_total!

      expect(inv.reload.total_amount).to eq(350.0)
    end

    it "sets total_amount to 0 when no orders are associated" do
      inv = create(:invoice)
      inv.recalculate_total!
      expect(inv.reload.total_amount).to eq(0)
    end
  end
end
