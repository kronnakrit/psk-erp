# frozen_string_literal: true

class InvoicesController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :authenticate_user!
  before_action :set_invoice, only: %i[show edit update cancel mark_paid reopen audit_trail print]
  skip_after_action :verify_authorized,    only: :index
  skip_after_action :verify_policy_scoped, except: %i[index draft paid cancelled]

  # GET /invoices
  def index
    authorize Invoice
    @ransack = policy_scope(Invoice).includes(:customer).ransack(params[:q])
    @ransack.sorts = "invoice_date desc" if @ransack.sorts.empty?
    @pagy, @invoices = pagy(@ransack.result)
  end

  # GET /invoices/draft
  def draft
    authorize Invoice, :index?
    @ransack = policy_scope(Invoice).draft.includes(:customer).ransack(params[:q])
    @ransack.sorts = "invoice_date desc" if @ransack.sorts.empty?
    @pagy, @invoices = pagy(@ransack.result)
    render :index
  end

  # GET /invoices/paid
  def paid
    authorize Invoice, :index?
    @ransack = policy_scope(Invoice).paid.includes(:customer).ransack(params[:q])
    @ransack.sorts = "invoice_date desc" if @ransack.sorts.empty?
    @pagy, @invoices = pagy(@ransack.result)
    render :index
  end

  # GET /invoices/cancelled
  def cancelled
    authorize Invoice, :index?
    @ransack = policy_scope(Invoice).cancelled.includes(:customer).ransack(params[:q])
    @ransack.sorts = "invoice_date desc" if @ransack.sorts.empty?
    @pagy, @invoices = pagy(@ransack.result)
    render :index
  end

  # GET /invoices/:id
  def show
    authorize @invoice
    @invoice_images    = @invoice.invoice_images.order(:position)
    @associated_orders = @invoice.orders.includes(:customer, order_lines: [:product, :unit_definition])
  end

  # GET /invoices/:id/audit_trail
  def audit_trail
    authorize @invoice, :audit?
    @audits = @invoice.invoice_audits.order(changed_at: :desc)
    render partial: "invoices/audit_trail", locals: { audits: @audits }, layout: false
  end

  # GET /invoices/:id/print
  def print
    authorize @invoice, :show?
    @invoice = Invoice.includes(:customer, orders: { order_lines: :product }).find(@invoice.id)
    @company_setting = CompanySetting.current!
    render layout: "print"
  end

  # GET /invoices/new
  def new
    authorize Invoice, :create?
    @eligible_orders = EligibleOrdersQuery.new(params).call
    @customers       = Customer.order(:first_name, :last_name)
    @preselected_ids = Array(params[:order_ids]).map(&:to_i)
  end

  # GET /invoices/:id/edit
  def edit
    authorize @invoice, :update?
  end

  # POST /invoices
  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    authorize Invoice, :create?

    order_ids = Array(params[:order_ids]).map(&:to_i).reject(&:zero?)
    if order_ids.empty?
      flash.now[:alert] = "Please select at least one order"
      @eligible_orders  = EligibleOrdersQuery.new(params).call
      @customers        = Customer.order(:first_name, :last_name)
      @preselected_ids  = []
      return render :new, status: :unprocessable_content
    end

    selected_orders = Order.where(id: order_ids)
    conflict = selected_orders.select do |o|
      InvoiceOrder.joins(:invoice).where(order_id: o.id).where.not(invoices: { status: "Cc" }).exists?
    end

    if conflict.any?
      flash.now[:alert] = "Order(s) already invoiced: #{conflict.map(&:order_number).join(', ')}"
      @eligible_orders = EligibleOrdersQuery.new(params).call
      @customers       = Customer.order(:first_name, :last_name)
      @preselected_ids = order_ids
      return render :new, status: :unprocessable_content
    end

    created_count = 0
    ActiveRecord::Base.transaction do
      selected_orders.group_by(&:customer_id).each_value do |orders|
        invoice = Invoice.create!(
          customer: orders.first.customer,
          invoice_date: Time.zone.today,
          created_by: Current.user
        )
        orders.each do |order|
          invoice.invoice_orders.create!(order: order)
          invoice.invoice_audits.create!(
            event_type: "order_added",
            new_value: order.order_number,
            changed_by: Current.user,
            changed_at: Time.current
          )
        end
        invoice.recalculate_total!
        created_count += 1
      end
    end

    redirect_to invoices_path, notice: "#{created_count} invoice(s) created successfully"
  end

  # PATCH /invoices/:id
  def update
    authorize @invoice, :update?
    old_remark = @invoice.remark

    if @invoice.update(invoice_params)
      if @invoice.remark != old_remark
        @invoice.invoice_audits.create!(
          event_type: "field_update",
          field_name: "remark",
          previous_value: old_remark.to_s,
          new_value: @invoice.remark.to_s,
          changed_by: Current.user,
          changed_at: Time.current
        )
      end
      redirect_to invoice_path(@invoice), notice: "Invoice updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

  # POST /invoices/:id/cancel
  def cancel
    authorize @invoice, :cancel?

    unless @invoice.status == "Dr"
      msg = @invoice.status == "Cc" ? "Invoice is already cancelled" : "Only Draft invoices can be cancelled"
      return redirect_to invoices_path, alert: msg, status: :unprocessable_content
    end

    @invoice.update!(status: "Cc")
    @invoice.invoice_audits.create!(
      event_type: "status_change",
      field_name: "status",
      previous_value: "Dr",
      new_value: "Cc",
      changed_by: Current.user,
      changed_at: Time.current
    )
    redirect_to invoices_path, notice: "Invoice cancelled"
  end

  # POST /invoices/:id/mark_paid
  def mark_paid
    authorize @invoice, :mark_paid?

    unless @invoice.status == "Dr"
      return redirect_to invoice_path(@invoice), alert: "Only Draft invoices can be marked as Paid",
                                                 status: :unprocessable_content
    end

    @invoice.update!(status: "Pd")
    @invoice.invoice_audits.create!(
      event_type: "status_change",
      field_name: "status",
      previous_value: "Dr",
      new_value: "Pd",
      changed_by: Current.user,
      changed_at: Time.current
    )
    redirect_to invoice_path(@invoice), notice: "Invoice marked as Paid"
  end

  # POST /invoices/:id/reopen
  def reopen
    authorize @invoice, :reopen?

    unless @invoice.status == "Pd"
      return redirect_to invoice_path(@invoice), alert: "Only Paid invoices can be reopened to Draft",
                                                 status: :unprocessable_content
    end

    @invoice.update!(status: "Dr")
    @invoice.invoice_audits.create!(
      event_type: "status_change",
      field_name: "status",
      previous_value: "Pd",
      new_value: "Dr",
      changed_by: Current.user,
      changed_at: Time.current
    )
    redirect_to invoice_path(@invoice), notice: "Invoice reopened to Draft"
  end

  # POST /invoices/bulk_update_status
  def bulk_update_status # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    authorize Invoice, :bulk_update_status?

    ids = Array(params[:ids]).map(&:to_i).reject(&:zero?)
    if ids.empty?
      return redirect_to invoices_path, alert: "Please select at least one invoice",
                                        status: :unprocessable_content
    end

    if params[:status] == "Cc"
      return redirect_to invoices_path,
                         alert: "Use the Cancel Invoice action to cancel individual invoices",
                         status: :unprocessable_content
    end

    unless Invoice::STATUSES.include?(params[:status])
      return redirect_to invoices_path, alert: "Invalid status", status: :unprocessable_content
    end

    invoices = Invoice.where(id: ids)
    invoices.each do |inv|
      old_status = inv.status
      inv.update!(status: params[:status])
      inv.invoice_audits.create!(
        event_type: "status_change",
        field_name: "status",
        previous_value: old_status,
        new_value: params[:status],
        changed_by: Current.user,
        changed_at: Time.current
      )
    end

    redirect_to invoices_path, notice: "#{invoices.count} invoices updated"
  end

  # GET /invoices/:id/add_orders
  def add_orders
    @invoice = Invoice.find(params[:id])
    authorize @invoice, :update?
    @eligible_orders = EligibleOrdersQuery.new(customer_id: @invoice.customer_id).call
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render file: Rails.public_path.join("404.html"), status: :not_found, layout: false
  end

  def invoice_params
    params.expect(invoice: [:remark])
  end
end
