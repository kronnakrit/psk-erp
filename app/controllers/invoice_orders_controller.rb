# frozen_string_literal: true

class InvoiceOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice
  skip_after_action :verify_policy_scoped

  # POST /invoices/:invoice_id/invoice_orders
  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    authorize @invoice, :update?

    unless @invoice.status == "Dr"
      return redirect_to invoice_path(@invoice), alert: "Cannot modify orders on a non-Draft invoice",
                                                 status: :unprocessable_content
    end

    order_ids = Array(params[:order_ids]).map(&:to_i).reject(&:zero?)
    return redirect_to add_orders_invoice_path(@invoice), alert: "Please select at least one order" if order_ids.empty?

    orders = Order.where(id: order_ids)

    wrong_customer = orders.reject { |o| o.customer_id == @invoice.customer_id }
    if wrong_customer.any?
      return redirect_to add_orders_invoice_path(@invoice),
                         alert: "Selected orders must belong to the same customer as this invoice",
                         status: :unprocessable_content
    end

    conflict = orders.select do |o|
      InvoiceOrder.joins(:invoice).where(order_id: o.id).where.not(invoices: { status: "Cc" }).exists?
    end
    if conflict.any?
      return redirect_to add_orders_invoice_path(@invoice),
                         alert: "Order(s) already invoiced: #{conflict.map(&:order_number).join(', ')}",
                         status: :unprocessable_content
    end

    orders.each do |order|
      @invoice.invoice_orders.create!(order: order)
      @invoice.invoice_audits.create!(
        event_type: "order_added",
        new_value: order.order_number,
        changed_by: Current.user,
        changed_at: Time.current
      )
    end
    @invoice.recalculate_total!

    redirect_to invoice_path(@invoice), notice: "#{orders.count} order(s) added to invoice"
  end

  # DELETE /invoices/:invoice_id/invoice_orders/:id  (id = order.id)
  def destroy # rubocop:disable Metrics/MethodLength
    authorize @invoice, :update?

    unless @invoice.status == "Dr"
      return render json: { error: "Cannot modify orders on a non-Draft invoice" },
                    status: :unprocessable_content
    end

    order = Order.find(params[:id])
    invoice_order = @invoice.invoice_orders.find_by!(order: order)

    if @invoice.invoice_orders.count <= 1
      return redirect_to invoice_path(@invoice),
                         alert: "An invoice must have at least one order"
    end

    order_number = order.order_number
    invoice_order.destroy!
    @invoice.invoice_audits.create!(
      event_type: "order_removed",
      previous_value: order_number,
      changed_by: Current.user,
      changed_at: Time.current
    )
    @invoice.recalculate_total!

    redirect_to invoice_path(@invoice), notice: "Order removed from invoice"
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:invoice_id])
  end
end
