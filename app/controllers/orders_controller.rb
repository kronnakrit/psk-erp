# frozen_string_literal: true

class OrdersController < ApplicationController # rubocop:disable Metrics/ClassLength
  before_action :authenticate_user!
  before_action :set_order, only: %i[show edit update destroy export export_token delivery_order duplicate audit_trail]
  before_action :redirect_if_cancelled, only: %i[edit update]
  before_action :load_associations, only: %i[new create edit update]

  # GET /orders
  def index
    @ransack = filtered_scope.includes(:customer, :logistic_company, :created_by).ransack(params[:q])
    @ransack.sorts = "running_date desc" if @ransack.sorts.empty?
    @pagy, @orders = pagy(@ransack.result)
    authorize Order
  end

  # Status-filtered list actions (GET /orders/draft, etc.)
  def draft
    @ransack = policy_scope(Order).draft.includes(:customer).ransack(params[:q])
    @ransack.sorts = "running_date desc" if @ransack.sorts.empty?
    @pagy, @orders = pagy(@ransack.result)
    authorize Order, :index?
    render :index
  end

  def paid
    @ransack = policy_scope(Order).paid.includes(:customer).ransack(params[:q])
    @ransack.sorts = "running_date desc" if @ransack.sorts.empty?
    @pagy, @orders = pagy(@ransack.result)
    authorize Order, :index?
    render :index
  end

  def completed
    @ransack = policy_scope(Order).completed.includes(:customer).ransack(params[:q])
    @ransack.sorts = "running_date desc" if @ransack.sorts.empty?
    @pagy, @orders = pagy(@ransack.result)
    authorize Order, :index?
    render :index
  end

  def cancelled
    @ransack = policy_scope(Order).cancelled.includes(:customer).ransack(params[:q])
    @ransack.sorts = "running_date desc" if @ransack.sorts.empty?
    @pagy, @orders = pagy(@ransack.result)
    authorize Order, :index?
    render :index
  end

  # GET /orders/dashboard
  def dashboard
    authorize Order, :dashboard?
    today = Time.zone.today
    @today_count    = Order.for_date(today).count
    @draft_count    = Order.draft.count
    @monthly_revenue = Order.completed
                            .where(running_date: today.all_month)
                            .sum(:grand_total)
    @recent_orders = Order.includes(:customer).order(running_date: :desc).limit(10)
  end

  # GET /orders/advance_search
  def advance_search
    authorize Order, :index?
    @ransack = policy_scope(Order)
               .includes(:customer, :logistic_company)
               .ransack(params[:q])
    @pagy, @orders = pagy(@ransack.result)
  end

  # POST /orders/filter
  def filter
    authorize Order, :index?
    scope = policy_scope(Order).includes(:customer)
    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @orders = pagy(scope.order(running_date: :desc))
    render :index
  end

  # PATCH /orders/bulk_update_status
  def bulk_update_status # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    authorize Order, :bulk_update_status?
    ids             = params[:ids]
    is_selected_all = params[:is_selected_all].to_s == "true"

    if ids.present? && is_selected_all
      render json: { error: "Provide either ids or is_selected_all, not both" }, status: :bad_request
      return
    end

    new_status = params[:status]
    unless Order::STATUSES.include?(new_status)
      render json: { error: "Invalid status" }, status: :unprocessable_content
      return
    end

    if is_selected_all
      scope = Order.where.not(status: "Cc")
      skipped_count = Order.where(status: "Cc").count
      scope.update_all(status: new_status) # rubocop:disable Rails/SkipsModelValidations
    else
      all_ids = Array(ids)
      skipped_count = Order.where(id: all_ids, status: "Cc").count
      Order.where(id: all_ids).where.not(status: "Cc").update_all(status: new_status) # rubocop:disable Rails/SkipsModelValidations
    end

    respond_to do |format|
      format.json { render json: { message: "Status updated", skipped_count: skipped_count } }
      format.html do
        redirect_to orders_path,
                    notice: "Status updated successfully. #{skipped_count} cancelled order(s) skipped."
      end
    end
  end

  def show
    authorize @order
    @order_lines = @order.order_lines.includes(:product).order(:idx, :id)
    @grand_total = ::GrandTotalCalculator.new(@order).call
  end

  def new
    @order = Order.new(running_date: Time.zone.today)
    @order.order_lines.build
    authorize @order
  end

  def edit
    authorize @order
    @order.order_lines.build if @order.order_lines.empty?
  end

  def create
    @order = Order.new(order_params)
    authorize @order
    if @order.save
      redirect_to order_path(@order), notice: "Order #{@order.order_number} created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @order
    if @order.update(order_params)
      redirect_to order_path(@order), notice: "Order updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @order
    @order.destroy
    redirect_to orders_path, notice: "Order deleted."
  end

  # GET /orders/:id/delivery_order
  def delivery_order
    authorize @order
    @order_lines = @order.order_lines.includes(:product).order(:idx, :id)
    render layout: "print"
  end

  # GET /orders/:id/audit_trail
  def audit_trail
    raise Pundit::NotAuthorizedError unless policy(@order).audit?

    skip_authorization
    @order_audits = @order.order_audits.includes(:changed_by).order(changed_at: :desc)
    render partial: "orders/audit_trail", locals: { order_audits: @order_audits }
  end

  # POST /orders/:id/duplicate
  def duplicate
    authorize @order, :duplicate?
    Current.user = current_user
    new_order = OrderDuplicateService.new(@order, current_user: current_user).call
    redirect_to order_path(new_order), notice: "Order duplicated as #{new_order.order_number}."
  rescue StandardError => e
    redirect_to order_path(@order), alert: "Could not duplicate order: #{e.message}."
  end

  # GET /orders/:id/export
  def export
    authorize @order
    package = OrderExcelService.new(@order).build
    send_data package.to_stream.read,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment",
              filename: "order-#{@order.order_number}.xlsx"
  end

  # GET /orders/:id/export_token
  def export_token
    authorize @order
    token      = Rails.application.message_verifier(:export)
                      .generate({ order_id: @order.id }, expires_in: 10.minutes)
    expires_at = 10.minutes.from_now
    render json: { token: token, expires_at: expires_at.iso8601 }
  end

  # GET /orders/download?token=...
  def download
    skip_authorization
    data     = Rails.application.message_verifier(:export).verify(params[:token])
    order_id = data[:order_id] || data["order_id"]
    order    = Order.find(order_id)
    package  = OrderExcelService.new(order).build
    send_data package.to_stream.read,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment",
              filename: "order-#{order.order_number}.xlsx"
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    head :forbidden
  end

  # POST /orders/combine_bills
  def combine_bills
    authorize Order, :combine_bills?
    orders = policy_scope(Order).where(id: Array(params[:ids])).includes(:customer, order_lines: :product)
    redirect_to orders_path, alert: "No orders selected." and return if orders.empty?

    result = CombinedBillsService.new(order_ids: orders.pluck(:id), prepared_by: current_prepared_by).build
    redirect_to orders_path, alert: result[:error] and return if result[:error]

    stream_combined_bills(result)
  end

  private

  def filtered_scope
    scope = policy_scope(Order)
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope
  end

  def set_order
    @order = Order.find(params[:id])
  end

  def redirect_if_cancelled
    return unless @order.status == "Cc"

    authorize @order # satisfies Pundit's verify_authorized after_action
    redirect_to order_path(@order), alert: "Cancelled orders cannot be edited."
  end

  def current_prepared_by
    current_user.profile&.full_name.presence || current_user.email
  end

  def stream_combined_bills(result)
    filename = "ใบรวมบิล-#{result[:customer_name]}.xlsx"
    send_data result[:package].to_stream.read,
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment; filename*=UTF-8''#{ERB::Util.url_encode(filename)}",
              filename: filename
  end

  def load_associations
    @customers = Customer.order(:first_name, :last_name)
    @logistic_companies = LogisticCompany.order(:name)
  end

  def order_params
    params.expect(order: [
                    :customer_id, :logistic_company_id, :telephone, :address,
                    :has_vat, :is_included_vat, :discount_price, :is_discount_percentage,
                    :discount_percentage, :remark, :internal_note, :status, :running_date,
                    :is_withholding_tax, :withholding_tax, :logistic_status,
                    { order_lines_attributes: [%i[
                      id product_id unit quantity unit_price
                      discount_price description remark idx _destroy
                    ]] }
                  ])
  end
end
