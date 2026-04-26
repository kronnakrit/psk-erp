module InvoicesHelper
  def invoice_audit_initials(audit)
    return "SYS" unless audit.changed_by

    name = audit.changed_by.profile&.full_name.presence || audit.changed_by.email
    name.split.map { |w| w[0].upcase }.first(2).join
  end

  def invoice_audit_actor_name(audit)
    return "System" unless audit.changed_by

    audit.changed_by.profile&.full_name.presence ||
      audit.changed_by.email.split("@").first.split(/[._-]/).map(&:capitalize).join(" ")
  end

  def invoice_audit_description(audit)
    case audit.event_type
    when "status_change"
      "changed <strong>status</strong> from " \
      "<code>#{h(status_label(audit.previous_value))}</code> → " \
      "<code>#{h(status_label(audit.new_value))}</code>"
    when "field_update"
      "changed <strong>#{h(audit.field_name)}</strong> from " \
      "<code>#{h(audit.previous_value)}</code> → <code>#{h(audit.new_value)}</code>"
    when "order_added"
      "added order <strong>#{h(audit.new_value)}</strong>"
    when "order_removed"
      "removed order <strong>#{h(audit.previous_value)}</strong>"
    else
      "#{h(audit.event_type)}: #{h(audit.field_name)}"
    end
  end

  private

  def status_label(code)
    { "Dr" => "Draft", "Pd" => "Paid", "Cc" => "Cancelled" }.fetch(code, code)
  end
end
