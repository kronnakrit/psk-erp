# frozen_string_literal: true

# Builds the query of orders eligible for invoicing.
# Eligible = not already linked to a non-cancelled (Draft or Paid) invoice.
#
# Accepts a params-like hash with optional filters:
#   customer_id:    filter by customer
#   from_date:      running_date >= from_date
#   to_date:        running_date <= to_date
class EligibleOrdersQuery
  def initialize(params = {})
    @customer_id = params[:customer_id].presence
    @from_date   = params[:from_date].presence
    @to_date     = params[:to_date].presence
  end

  def call
    already_invoiced_ids = InvoiceOrder
                           .joins(:invoice)
                           .where.not(invoices: { status: "Cc" })
                           .select(:order_id)

    scope = Order.where.not(id: already_invoiced_ids).includes(:customer)

    scope = scope.where(customer_id: @customer_id) if @customer_id.present?
    scope = scope.where(running_date: @from_date..) if @from_date.present?
    scope = scope.where(running_date: ..@to_date)   if @to_date.present?

    scope.order(running_date: :desc)
  end
end
