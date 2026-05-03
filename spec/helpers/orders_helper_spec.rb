# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrdersHelper, type: :helper do
  let(:user_with_profile) do
    u = create(:user)
    u.profile.update!(first_name: "Alice", last_name: "Smith")
    u
  end

  describe "#logistic_status_label" do
    it "returns human label for known code" do
      code = Order::LOGISTIC_STATUS_LABELS.keys.first
      expect(helper.logistic_status_label(code)).to eq(Order::LOGISTIC_STATUS_LABELS[code])
    end

    it "returns raw code for unknown status" do
      expect(helper.logistic_status_label("UNKNOWN")).to eq("UNKNOWN")
    end
  end

  describe "#audit_initials" do
    it "returns SYS when changed_by is nil" do
      audit = double(changed_by: nil)
      expect(helper.audit_initials(audit)).to eq("SYS")
    end

    it "returns initials from full name" do
      audit = double(changed_by: user_with_profile)
      expect(helper.audit_initials(audit)).to eq("AS")
    end

    it "returns initials from email when no profile name" do
      user = create(:user)
      user.profile.update!(first_name: nil, last_name: nil)
      audit = double(changed_by: user)
      expect(helper.audit_initials(audit)).to be_a(String)
      expect(helper.audit_initials(audit).length).to be_between(1, 2)
    end
  end

  describe "#audit_actor_name" do
    it "returns System when changed_by is nil" do
      audit = double(changed_by: nil)
      expect(helper.audit_actor_name(audit)).to eq("System")
    end

    it "returns full name when profile is set" do
      audit = double(changed_by: user_with_profile)
      expect(helper.audit_actor_name(audit)).to eq("Alice Smith")
    end

    it "returns formatted name from email when no profile name" do
      user = create(:user)
      user.profile.update!(first_name: nil, last_name: nil)
      audit = double(changed_by: user)
      expect(helper.audit_actor_name(audit)).to be_a(String)
    end
  end

  describe "#audit_description" do
    def build_audit(event_type:, field_name: nil, previous_value: nil, new_value: nil)
      double(
        event_type: event_type,
        field_name: field_name,
        previous_value: previous_value,
        new_value: new_value,
        changed_by: nil
      )
    end

    it "handles status_change event" do
      audit = build_audit(event_type: "status_change", field_name: "status", previous_value: "Dr", new_value: "Pd")
      result = helper.audit_description(audit)
      expect(result).to include("status")
      expect(result).to include("Dr")
      expect(result).to include("Pd")
    end

    it "handles field_update event" do
      audit = build_audit(event_type: "field_update", field_name: "address", previous_value: "Old", new_value: "New")
      result = helper.audit_description(audit)
      expect(result).to include("address")
    end

    it "handles line_added event" do
      new_val = { product_name: "Widget", quantity: 2, unit_price: 100 }.to_json
      audit = build_audit(event_type: "line_added", new_value: new_val)
      result = helper.audit_description(audit)
      expect(result).to include("Widget")
    end

    it "handles line_removed event" do
      prev_val = { product_name: "Widget" }.to_json
      audit = build_audit(event_type: "line_removed", previous_value: prev_val)
      result = helper.audit_description(audit)
      expect(result).to include("Widget")
    end

    it "handles line_updated event" do
      audit = build_audit(event_type: "line_updated", field_name: "qty", previous_value: "1", new_value: "2")
      result = helper.audit_description(audit)
      expect(result).to include("qty")
    end

    it "handles unknown event type" do
      audit = build_audit(event_type: "other_event", field_name: "something")
      result = helper.audit_description(audit)
      expect(result).to include("other_event")
    end

    it "handles JSON::ParserError gracefully" do
      audit = build_audit(event_type: "line_added", new_value: "invalid json")
      result = helper.audit_description(audit)
      expect(result).to be_a(String)
    end
  end
end
