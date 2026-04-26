# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceAudit, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:invoice) }
    it { is_expected.to belong_to(:changed_by).class_name("User").optional(true) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:event_type).in_array(InvoiceAudit::EVENT_TYPES) }

    context "event_type inclusion" do
      InvoiceAudit::EVENT_TYPES.each do |type|
        it "is valid with event_type '#{type}'" do
          audit = build(:invoice_audit, event_type: type)
          expect(audit).to be_valid
        end
      end

      it "is invalid with an unknown event_type" do
        audit = build(:invoice_audit, event_type: "unknown_event")
        expect(audit).not_to be_valid
        expect(audit.errors[:event_type]).to be_present
      end
    end
  end
end
