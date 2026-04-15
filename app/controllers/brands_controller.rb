class BrandsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_brand, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Brand).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @brands = pagy(@ransack.result)
    authorize Brand
  end

  def show
    authorize @brand
  end

  def new
    @brand = Brand.new
    authorize @brand
  end

  def edit
    authorize @brand
  end

  def create
    @brand = Brand.new(brand_params)
    authorize @brand
    if @brand.save
      redirect_to brands_path, notice: "Brand created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @brand
    if @brand.update(brand_params)
      redirect_to brands_path, notice: "Brand updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @brand
    @brand.destroy
    redirect_to brands_path, notice: "Brand deleted successfully."
  end

  private

  def set_brand
    @brand = Brand.find(params[:id])
  end

  def brand_params
    params.expect(brand: %i[name description remark])
  end
end
