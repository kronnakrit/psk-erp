# frozen_string_literal: true

# InvoiceAuditService records field-level audit entries on an Invoice.
#
# Usage:
#   InvoiceAuditService.new.call(invoice: invoice, changes: invoice.saved_changes, changed_by: Current.user)
class InvoiceAuditService
  MAX_VALUE_LENGTH = 500

  EXCLUDED_FIELDS = %w[updated_at updated_by_id].freeze

  def call(invoice:, changes:, changed_by:)
    changes.each do |field, (old_val, new_val)|
      next if EXCLUDED_FIELDS.include?(field)

      invoice.invoice_audits.create!(
        event_type: event_type_for(field),
        field_name: field,
        previous_value: truncate(old_val.to_s),
        new_value: truncate(new_val.to_s),
        changed_by: changed_by,
        changed_at: Time.current
      )
    end
  end

  private

  def event_type_for(field)
    field == "status" ? "status_change" : "field_update"
  end

  def truncate(value)
    value.length > MAX_VALUE_LENGTH ? value[0, MAX_VALUE_LENGTH] : value
  end
end
