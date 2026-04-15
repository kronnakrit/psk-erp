# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderAuditService do
  subject(:service) { described_class.new }

  let(:order)    { create(:order) }
  let(:user)     { create(:user) }

  describe "#call" do
    context "when a non-excluded field changes" do
      it "creates one OrderAudit record per changed field" do
        changes = { "remark" => [nil, "Test remark"] }
        expect do
          service.call(order: order, changes: changes, changed_by: user)
        end.to change(OrderAudit, :count).by(1)
      end
    end

    context "when the status field changes" do
      it "creates an audit with event_type status_change" do
        changes = { "status" => ["Dr", "Pd"] }
        service.call(order: order, changes: changes, changed_by: user)
        audit = order.order_audits.last
        expect(audit.event_type).to eq("status_change")
        expect(audit.field_name).to eq("status")
      end
    end

    context "when a non-status field changes" do
      it "creates an audit with event_type field_update" do
        changes = { "remark" => ["old", "new"] }
        service.call(order: order, changes: changes, changed_by: user)
        audit = order.order_audits.last
        expect(audit.event_type).to eq("field_update")
      end
    end

    context "when only excluded fields are in the changes hash" do
      it "creates no OrderAudit records" do
        changes = {
          "updated_at"    => [1.minute.ago, Time.current],
          "total_price"   => [100.0, 200.0],
          "vat_price"     => [7.0, 14.0],
          "grand_total"   => [107.0, 214.0],
          "updated_by_id" => [nil, user.id]
        }
        expect do
          service.call(order: order, changes: changes, changed_by: user)
        end.not_to change(OrderAudit, :count)
      end
    end

    context "when a value exceeds 500 characters" do
      it "truncates previous_value and new_value to 500 characters" do
        long_string = "x" * 600
        changes = { "remark" => [long_string, long_string] }
        service.call(order: order, changes: changes, changed_by: user)
        audit = order.order_audits.last
        expect(audit.previous_value.length).to eq(500)
        expect(audit.new_value.length).to eq(500)
      end
    end

    context "when changed_by is provided" do
      it "assigns changed_by to the audit record" do
        changes = { "remark" => ["a", "b"] }
        service.call(order: order, changes: changes, changed_by: user)
        expect(order.order_audits.last.changed_by).to eq(user)
      end
    end

    context "when changed_by is nil (system-triggered)" do
      it "creates audit with changed_by nil" do
        changes = { "remark" => ["a", "b"] }
        service.call(order: order, changes: changes, changed_by: nil)
        expect(order.order_audits.last.changed_by).to be_nil
      end
    end

    context "when multiple non-excluded fields change" do
      it "creates one record per field" do
        changes = { "remark" => ["a", "b"], "address" => ["old addr", "new addr"] }
        expect do
          service.call(order: order, changes: changes, changed_by: user)
        end.to change(OrderAudit, :count).by(2)
      end
    end
  end
end
