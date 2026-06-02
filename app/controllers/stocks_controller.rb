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
    @lots = @stock.product.product_lots.includes(:purchase_order).order(received_date: :asc)
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
    authorize @stock, :update?
    amount = params[:amount].to_d
    reason = params[:reason].presence
    if amount.positive?
      @stock.deposit!(amount: amount, reason: reason, adjuster: current_user)
      redirect_to stock_path(@stock), notice: "Deposited #{amount} units successfully."
    else
      redirect_to stock_path(@stock), alert: "Amount must be greater than 0."
    end
  end

  def withdraw
    authorize @stock, :update?
    amount = params[:amount].to_d
    reason = params[:reason].presence
    if amount.positive?
      @stock.withdraw!(amount: amount, reason: reason, adjuster: current_user)
      redirect_to stock_path(@stock), notice: "Withdrew #{amount} units successfully."
    else
      redirect_to stock_path(@stock), alert: "Amount must be greater than 0."
    end
  end

  def recalculate_checkpoint
    authorize @stock, :update?
    @stock.recalculate_checkpoint!
    redirect_to stock_path(@stock), notice: "Checkpoint recalculated successfully."
  end

  def transactions
    authorize @stock, :show?
    @pagy, @transactions = pagy(
      @stock.product_stock_transactions.includes(:adjuster).order(created_at: :desc)
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
end
