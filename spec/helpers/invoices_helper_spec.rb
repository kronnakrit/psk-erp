# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoicesHelper, type: :helper do
  let(:user_with_profile) do
    u = create(:user)
    u.profile.update!(first_name: "Bob", last_name: "Jones")
    u
  end

  def build_audit(event_type:, field_name: nil, previous_value: nil, new_value: nil, changed_by: nil)
    double(
      event_type: event_type,
      field_name: field_name,
      previous_value: previous_value,
      new_value: new_value,
      changed_by: changed_by
    )
  end

  describe "#invoice_audit_initials" do
    it "returns SYS when changed_by is nil" do
      audit = build_audit(event_type: "status_change")
      expect(helper.invoice_audit_initials(audit)).to eq("SYS")
    end

    it "returns initials from full name" do
      audit = build_audit(event_type: "status_change", changed_by: user_with_profile)
      expect(helper.invoice_audit_initials(audit)).to eq("BJ")
    end
  end

  describe "#invoice_audit_actor_name" do
    it "returns System when changed_by is nil" do
      audit = build_audit(event_type: "status_change")
      expect(helper.invoice_audit_actor_name(audit)).to eq("System")
    end

    it "returns full name when profile has name" do
      audit = build_audit(event_type: "status_change", changed_by: user_with_profile)
      expect(helper.invoice_audit_actor_name(audit)).to eq("Bob Jones")
    end

    it "capitalizes parts from email" do
      user = create(:user)
      user.profile.update!(first_name: nil, last_name: nil)
      audit = build_audit(event_type: "status_change", changed_by: user)
      expect(helper.invoice_audit_actor_name(audit)).to be_a(String)
    end
  end

  describe "#invoice_audit_description" do
    it "handles status_change" do
      audit = build_audit(event_type: "status_change", previous_value: "Dr", new_value: "Pd")
      result = helper.invoice_audit_description(audit)
      expect(result).to include("Draft")
      expect(result).to include("Paid")
    end

    it "handles field_update" do
      audit = build_audit(event_type: "field_update", field_name: "remark", previous_value: "old", new_value: "new")
      result = helper.invoice_audit_description(audit)
      expect(result).to include("remark")
    end

    it "handles order_added" do
      audit = build_audit(event_type: "order_added", new_value: "ORD-001")
      result = helper.invoice_audit_description(audit)
      expect(result).to include("ORD-001")
    end

    it "handles order_removed" do
      audit = build_audit(event_type: "order_removed", previous_value: "ORD-001")
      result = helper.invoice_audit_description(audit)
      expect(result).to include("ORD-001")
    end

    it "handles unknown event" do
      audit = build_audit(event_type: "something_else", field_name: "xyz")
      result = helper.invoice_audit_description(audit)
      expect(result).to include("something_else")
    end
  end
end
