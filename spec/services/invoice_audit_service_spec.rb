# frozen_string_literal: true

require "rails_helper"

RSpec.describe InvoiceAuditService do
  let(:customer) { create(:customer) }
  let(:user)     { create(:user) }
  let(:invoice)  { create(:invoice, customer: customer) }

  before { allow(Current).to receive(:user).and_return(user) }

  describe "#call" do
    it "creates a field_update audit entry for remark change" do
      expect {
        described_class.new.call(
          invoice: invoice,
          changes: { "remark" => [nil, "New remark"] },
          changed_by: user
        )
      }.to change { invoice.invoice_audits.count }.by(1)

      audit = invoice.invoice_audits.last
      expect(audit.event_type).to eq("field_update")
      expect(audit.field_name).to eq("remark")
      expect(audit.new_value).to eq("New remark")
    end

    it "creates a status_change audit entry for status change" do
      expect {
        described_class.new.call(
          invoice: invoice,
          changes: { "status" => %w[Dr Pd] },
          changed_by: user
        )
      }.to change { invoice.invoice_audits.count }.by(1)

      audit = invoice.invoice_audits.last
      expect(audit.event_type).to eq("status_change")
      expect(audit.previous_value).to eq("Dr")
      expect(audit.new_value).to eq("Pd")
    end

    it "excludes updated_at and updated_by_id fields" do
      expect {
        described_class.new.call(
          invoice: invoice,
          changes: { "updated_at" => [1.day.ago, Time.current], "updated_by_id" => [nil, user.id] },
          changed_by: user
        )
      }.not_to change { invoice.invoice_audits.count }
    end

    it "truncates very long values" do
      long_value = "x" * 1000
      described_class.new.call(
        invoice: invoice,
        changes: { "remark" => [nil, long_value] },
        changed_by: user
      )
      audit = invoice.invoice_audits.last
      expect(audit.new_value.length).to eq(InvoiceAuditService::MAX_VALUE_LENGTH)
    end
  end
end
