# frozen_string_literal: true

class StocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stock, only: %i[show deposit withdraw recalculate_checkpoint transactions reset_stock]

  def index
    @branches = Branch.order(:name)
    @ransack = policy_scope(ProductStock)
               .includes(:branch, product: :vendor)
               .ransack(params[:q])
    @ransack.sorts = "id asc" if @ransack.sorts.empty?
    @pagy, @stocks = pagy(@ransack.result)
    authorize ProductStock
  end

  def show
    authorize @stock
    @transactions = @stock.product_stock_transactions.includes(:adjuster).order(created_at: :desc)
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

  def reset_stock
    authorize @stock, :update?
    reason = params[:reason].presence
    unless reason
      redirect_to stock_path(@stock), alert: "Reason is required to reset stock."
      return
    end
    result = @stock.reset_stock!(reason: reason, adjuster: current_user)
    if result == :already_zero
      redirect_to stock_path(@stock), notice: "Stock is already at zero — no changes made."
    else
      redirect_to stock_path(@stock), notice: "Stock has been reset to 0."
    end
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
end
