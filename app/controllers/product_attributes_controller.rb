class ProductAttributesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product_attribute, only: %i[edit update destroy]

  def index
    @product_attributes = policy_scope(ProductAttribute).where(product_id: params[:product_id]).includes(:attribute)
    authorize ProductAttribute
  end

  def new
    @product_attribute = ProductAttribute.new(product_id: params[:product_id])
    authorize @product_attribute
  end

  def edit
    authorize @product_attribute
  end

  def create
    @product_attribute = ProductAttribute.new(product_attribute_params)
    authorize @product_attribute
    if @product_attribute.save
      redirect_back_or_to root_path, notice: "Attribute value saved."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @product_attribute
    if @product_attribute.update(product_attribute_params)
      redirect_back_or_to root_path, notice: "Attribute value updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @product_attribute
    @product_attribute.destroy
    redirect_back_or_to root_path, notice: "Attribute value removed."
  end

  private

  def set_product_attribute
    @product_attribute = ProductAttribute.find(params[:id])
  end

  def product_attribute_params
    params.expect(product_attribute: %i[product_id attribute_id value])
  end
end
