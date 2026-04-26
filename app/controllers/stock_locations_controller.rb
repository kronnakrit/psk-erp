# frozen_string_literal: true

class StockLocationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stock_location, only: %i[edit update destroy]

  def index
    @ransack = policy_scope(StockLocation).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @stock_locations = pagy(@ransack.result)
    authorize StockLocation
  end

  def new
    @stock_location = StockLocation.new
    authorize @stock_location
  end

  def create
    @stock_location = StockLocation.new(stock_location_params)
    authorize @stock_location
    if @stock_location.save
      redirect_to stock_locations_path, notice: "Stock location created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @stock_location
  end

  def update
    authorize @stock_location
    if @stock_location.update(stock_location_params)
      redirect_to stock_locations_path, notice: "Stock location updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @stock_location
    @stock_location.destroy!
    redirect_to stock_locations_path, notice: "Stock location deleted."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to stock_locations_path, alert: e.message
  end

  private

  def set_stock_location
    @stock_location = StockLocation.find(params[:id])
  end

  def stock_location_params
    params.expect(stock_location: %i[name description])
  end
end
