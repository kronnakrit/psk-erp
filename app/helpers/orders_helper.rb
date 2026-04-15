module OrdersHelper
  def logistic_status_label(code)
    Order::LOGISTIC_STATUS_LABELS.fetch(code.to_s, code.to_s)
  end

  def audit_initials(audit)
    return "SYS" unless audit.changed_by

    name = audit.changed_by.profile&.full_name.presence || audit.changed_by.email
    name.split.map { |w| w[0].upcase }.first(2).join
  end

  def audit_actor_name(audit)
    return "System" unless audit.changed_by

    audit.changed_by.profile&.full_name.presence ||
      audit.changed_by.email.split("@").first.split(/[._\-]/).map(&:capitalize).join(" ")
  end

  def audit_description(audit)
    case audit.event_type
    when "status_change", "field_update"
      "changed <strong>#{h(audit.field_name)}</strong> from " \
        "<code>#{h(audit.previous_value)}</code> \u2192 <code>#{h(audit.new_value)}</code>"
    when "line_added"
      data = JSON.parse(audit.new_value)
      "added Order Line: #{h(data['product_name'])}, " \
        "Qty #{h(data['quantity'].to_s)}, \u0e3f#{number_with_precision(data['unit_price'].to_f, precision: 2, delimiter: ',')}"
    when "line_removed"
      data = JSON.parse(audit.previous_value)
      "removed Order Line: #{h(data['product_name'])}"
    when "line_updated"
      "changed line <strong>#{h(audit.field_name)}</strong> from " \
        "<code>#{h(audit.previous_value)}</code> \u2192 <code>#{h(audit.new_value)}</code>"
    else
      "#{h(audit.event_type)}: #{h(audit.field_name)}"
    end
  rescue JSON::ParserError
    "#{h(audit.event_type)}: #{h(audit.field_name)}"
  end
end
