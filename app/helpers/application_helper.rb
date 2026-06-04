module ApplicationHelper
  def adjuster_display_name(adjuster)
    return "—" if adjuster.nil?

    first = adjuster.profile&.first_name.presence
    last  = adjuster.profile&.last_name.presence
    if first || last
      [first, last].compact.join(" ")
    else
      adjuster.email
    end
  end

  def stock_transaction_lot_display(transaction)
    lot = transaction.related_object
    return content_tag(:span, "—", class: "text-gray-400") unless lot.is_a?(ProductLot)

    parts = [content_tag(:span, lot.lot_number, class: "font-mono text-xs text-gray-800")]
    if lot.purchase_order
      parts << link_to(
        lot.purchase_order.po_number,
        purchase_order_path(lot.purchase_order),
        class: "block text-xs text-blue-600 hover:underline mt-0.5"
      )
    end
    safe_join(parts)
  end
end
