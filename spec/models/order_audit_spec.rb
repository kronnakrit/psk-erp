# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderAudit, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:order) }
    it { is_expected.to belong_to(:changed_by).class_name("User").optional }
  end

  describe "validations" do
    subject { build(:order_audit, order: create(:order)) }

    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_inclusion_of(:event_type).in_array(OrderAudit::EVENT_TYPES) }
  end

  describe "constants" do
    it "defines EVENT_TYPES" do
      expect(OrderAudit::EVENT_TYPES).to contain_exactly(
        "field_update", "status_change", "line_added", "line_removed", "line_updated"
      )
    end

    it "defines EXCLUDED_FIELDS" do
      expect(OrderAudit::EXCLUDED_FIELDS).to include(
        "updated_at", "updated_by_id", "total_price", "vat_price",
        "grand_total", "order_number", "created_by_id"
      )
    end
  end

  describe "factory" do
    it "is valid with default attributes" do
      audit = create(:order_audit)
      expect(audit).to be_valid
    end

    it "is invalid without an order" do
      audit = build(:order_audit, order: nil)
      expect(audit).not_to be_valid
    end

    it "is invalid with an unknown event_type" do
      audit = build(:order_audit, order: create(:order), event_type: "unknown_event")
      expect(audit).not_to be_valid
    end

    it "is valid when changed_by is nil" do
      audit = create(:order_audit, changed_by: nil)
      expect(audit).to be_valid
    end
  end
end
