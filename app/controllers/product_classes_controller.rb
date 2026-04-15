class ProductClassesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_class, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(ProductClass).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @product_classes = pagy(@ransack.result)
    authorize ProductClass
  end

  def show
    authorize @product_class
  end

  def new
    @product_class = ProductClass.new
    authorize @product_class
  end

  def edit
    authorize @product_class
  end

  def create
    @product_class = ProductClass.new(product_class_params)
    authorize @product_class
    if @product_class.save
      redirect_to product_classes_path, notice: "Product class created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @product_class
    if @product_class.update(product_class_params)
      redirect_to product_classes_path, notice: "Product class updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @product_class
    @product_class.destroy
    redirect_to product_classes_path, notice: "Product class deleted successfully."
  end

  private

  def set_product_class
    @product_class = ProductClass.find(params[:id])
  end

  def product_class_params
    params.expect(product_class: [:name])
  end
end
