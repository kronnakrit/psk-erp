# frozen_string_literal: true

class PurchaseOrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase_order, only: %i[show edit update destroy confirm]
  before_action :redirect_if_not_draft, only: %i[edit update]

  # GET /purchase_orders
  def index
    @ransack = policy_scope(PurchaseOrder).includes(:supplier).ransack(params[:q])
    @ransack.sorts = "po_date desc" if @ransack.sorts.empty?
    @pagy, @purchase_orders = pagy(@ransack.result)
    authorize PurchaseOrder
  end

  # GET /purchase_orders/:id
  def show
    authorize @purchase_order
    @purchase_order = PurchaseOrder.includes(purchase_order_lines: [:product, :unit_definition])
                                   .find(params[:id])
  end

  # GET /purchase_orders/new
  def new
    @purchase_order = PurchaseOrder.new(po_date: Time.zone.today)
    @purchase_order.purchase_order_lines.build
    authorize @purchase_order
    load_suppliers
  end

  # GET /purchase_orders/:id/edit
  def edit
    authorize @purchase_order
    @purchase_order.purchase_order_lines.build if @purchase_order.purchase_order_lines.empty?
    load_suppliers
  end

  # POST /purchase_orders
  def create
    @purchase_order = PurchaseOrder.new(purchase_order_params)
    authorize @purchase_order
    if @purchase_order.save
      redirect_to purchase_order_path(@purchase_order), notice: "Purchase order created."
    else
      load_suppliers
      render :new, status: :unprocessable_content
    end
  end

  # PATCH /purchase_orders/:id
  def update
    authorize @purchase_order
    if @purchase_order.update(purchase_order_params)
      redirect_to purchase_order_path(@purchase_order), notice: "Purchase order updated."
    else
      load_suppliers
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /purchase_orders/:id
  def destroy
    authorize @purchase_order
    @purchase_order.destroy
    if @purchase_order.errors.any?
      redirect_to purchase_orders_path, alert: @purchase_order.errors.full_messages.to_sentence
    else
      redirect_to purchase_orders_path, notice: "Purchase order deleted."
    end
  end

  # POST /purchase_orders/:id/confirm
  def confirm
    authorize @purchase_order, :update?
    lots_count = ConfirmPurchaseOrderService.new(@purchase_order).call!
    redirect_to purchase_order_path(@purchase_order),
                notice: "Purchase order confirmed. #{lots_count} product lot(s) created."
  rescue ConfirmPurchaseOrderService::Error => e
    redirect_to purchase_order_path(@purchase_order), alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to purchase_order_path(@purchase_order), alert: e.message
  end

  private

  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:id])
  end

  def redirect_if_not_draft
    return if @purchase_order.draft?

    authorize @purchase_order
    redirect_to purchase_order_path(@purchase_order),
                alert: "Confirmed purchase orders cannot be edited."
  end

  def load_suppliers
    @suppliers = Supplier.where(is_active: true).order(:name)
  end

  def purchase_order_params
    params.expect(
      purchase_order: [
        :supplier_id, :po_date, :remark,
        { purchase_order_lines_attributes: [%i[id product_id unit_definition_id quantity unit_cost _destroy]] }
      ]
    )
  end
end
