# frozen_string_literal: true

class StocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stock, only: %i[show update deposit withdraw recalculate_checkpoint transactions]

  def index
    @branches = Branch.order(:name)
    @ransack = policy_scope(ProductStock)
               .includes(:branch, :stock_person, :product)
               .ransack(params[:q])
    @ransack.sorts = "id asc" if @ransack.sorts.empty?
    @pagy, @stocks = pagy(@ransack.result)
    authorize ProductStock
  end

  def show
    authorize @stock
    lots = @stock.product.product_lots.includes(:purchase_order).by_latest_received
    @lots = lots
    @lots_for_picker = lots
    @all_stock_locations = StockLocation.order(:name)
    @all_users = User.joins(:profile).includes(:profile).where(is_active: true).order("profiles.first_name")
  end

  def update
    authorize @stock
    if @stock.update(stock_update_params)
      redirect_to stock_path(@stock), notice: t("flash.updated", resource: "Stock")
    else
      redirect_to stock_path(@stock), alert: @stock.errors.full_messages.to_sentence
    end
  end

  def deposit
    perform_lot_adjustment(:deposit)
  end

  def withdraw
    perform_lot_adjustment(:withdraw)
  end

  def recalculate_checkpoint
    authorize @stock, :update?
    @stock.recalculate_checkpoint!
    redirect_to stock_path(@stock), notice: "Checkpoint recalculated successfully."
  end

  def transactions
    authorize @stock, :show?
    @pagy, @transactions = pagy(
      @stock.product_stock_transactions
            .includes(:adjuster, related_object: :purchase_order)
            .order(created_at: :desc)
    )
    render :transactions
  end

  private

  def set_stock
    @stock = ProductStock.find(params[:id])
  end

  def stock_update_params
    params.expect(product_stock: [:stock_person_id, { stock_location_ids: [] }])
  end

  def perform_lot_adjustment(action)
    authorize @stock, :update?

    if @stock.product.product_lots.none?
      redirect_to stock_path(@stock), alert: t("stocks.adjustment.no_lots_available")
      return
    end

    lot = find_product_lot
    unless lot
      redirect_to stock_path(@stock), alert: t("stocks.adjustment.lot_required")
      return
    end

    amount = params[:amount].to_d
    reason = params[:reason].presence

    result = LotAwareStockAdjustmentService.call(
      stock: @stock,
      product_lot: lot,
      amount: amount,
      action: action,
      reason: reason,
      adjuster: current_user
    )

    if result.success?
      notice_key = action == :deposit ? "stocks.adjustment.deposited" : "stocks.adjustment.withdrew"
      redirect_to stock_path(@stock),
                  notice: t(notice_key, amount: format_adjustment_amount(amount), lot_number: lot.lot_number)
    else
      redirect_to stock_path(@stock), alert: result.error
    end
  end

  def find_product_lot
    lot_id = params[:product_lot_id].presence
    return nil unless lot_id

    @stock.product.product_lots.find_by(id: lot_id)
  end

  def format_adjustment_amount(amount)
    amount.frac.zero? ? amount.to_i : amount
  end
end
