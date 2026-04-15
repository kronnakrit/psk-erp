class ProductCategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_category, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(ProductCategory).ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @product_categories = pagy(@ransack.result)
    authorize ProductCategory
  end

  def show
    authorize @product_category
  end

  def new
    @product_category = ProductCategory.new
    authorize @product_category
  end

  def edit
    authorize @product_category
  end

  def create
    @product_category = ProductCategory.new(product_category_params)
    authorize @product_category
    if @product_category.save
      redirect_to product_categories_path, notice: "Product category created successfully."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @product_category
    if @product_category.update(product_category_params)
      redirect_to product_categories_path, notice: "Product category updated successfully."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @product_category
    @product_category.destroy
    redirect_to product_categories_path, notice: "Product category deleted successfully."
  end

  private

  def set_product_category
    @product_category = ProductCategory.find(params[:id])
  end

  def product_category_params
    params.expect(product_category: [:name])
  end
end
