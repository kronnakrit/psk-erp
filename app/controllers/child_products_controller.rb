# frozen_string_literal: true

class ChildProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_child_product

  def update
    authorize @child_product, :update?
    if @child_product.update(child_product_params)
      redirect_to products_path, notice: "Child product updated successfully."
    else
      render json: { errors: @child_product.errors }, status: :unprocessable_content
    end
  end

  def destroy
    authorize @child_product, :destroy?
    @child_product.destroy
    redirect_to products_path, notice: "Child product deleted successfully."
  end

  private

  def set_child_product
    @child_product = Product.find(params[:id])
  end

  def child_product_params
    params.expect(
      product: [:name, :description, :description_th, :sku, :barcode,
                :unit, :price, :cost, :remark, :vendor_id, :brand_id, :enable_stock,
                { product_category_ids: [] }]
    )
  end
end
