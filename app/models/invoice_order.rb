# frozen_string_literal: true

class InvoiceOrder < ApplicationRecord
  belongs_to :invoice
  belongs_to :order

  validate :order_not_on_active_invoice

  private

  def order_not_on_active_invoice
    return if order_id.blank?

    duplicate = InvoiceOrder
                .joins(:invoice)
                .where(order_id: order_id)
                .where.not(invoices: { status: "Cc" })
                .where.not(id: id)
                .exists?

    errors.add(:order_id, :already_invoiced, message: "is already on an active invoice") if duplicate
  end
end
