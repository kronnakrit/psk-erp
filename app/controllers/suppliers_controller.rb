# frozen_string_literal: true

class SuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Supplier).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @suppliers = pagy(@ransack.result)
    authorize Supplier
  end

  def show
    authorize @supplier
  end

  def new
    @supplier = Supplier.new
    authorize @supplier
  end

  def edit
    authorize @supplier
  end

  def create
    @supplier = Supplier.new(supplier_params)
    authorize @supplier
    if @supplier.save
      redirect_to suppliers_path, notice: "Supplier created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @supplier
    if @supplier.update(supplier_params)
      redirect_to suppliers_path, notice: "Supplier updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @supplier
    @supplier.destroy!
    redirect_to suppliers_path, notice: "Supplier deleted."
  rescue ActiveRecord::DeleteRestrictionError => e
    redirect_to suppliers_path, alert: e.message
  end

  private

  def set_supplier
    @supplier = Supplier.find(params[:id])
  end

  def supplier_params
    params.expect(supplier: %i[name telephone address remark is_active])
  end
end
