# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: %i[show edit update destroy]

  def index
    @ransack = policy_scope(Product)
               .includes(:vendor, :brand, :product_class, :product_stocks,
                         :featured_image_attachment, { product_images: { image_attachment: :blob } },
                         { children: [:product_stocks, :featured_image_attachment,
                                      { product_images: { image_attachment: :blob } }] })
               .ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @products = pagy(@ransack.result)
    authorize Product
  end

  def show
    authorize @product
  end

  def new
    @product = Product.new
    @vendors = Vendor.order(:name)
    @brands = Brand.order(:name)
    @product_classes = ProductClass.order(:name)
    @product_categories = ProductCategory.order(:name)
    authorize @product
  end

  def edit
    @vendors = Vendor.order(:name)
    @brands = Brand.order(:name)
    @product_classes = ProductClass.order(:name)
    @product_categories = ProductCategory.order(:name)
    authorize @product
  end

  def create
    @product = Product.new(product_params)
    authorize @product
    if @product.save
      redirect_to products_path, notice: "Product created successfully."
    else
      @vendors = Vendor.order(:name)
      @brands = Brand.order(:name)
      @product_classes = ProductClass.order(:name)
      @product_categories = ProductCategory.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @product
    if @product.update(product_params)
      redirect_to products_path, notice: "Product updated successfully."
    else
      @vendors = Vendor.order(:name)
      @brands = Brand.order(:name)
      @product_classes = ProductClass.order(:name)
      @product_categories = ProductCategory.order(:name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @product
    @product.destroy
    redirect_to products_path, notice: "Product deleted successfully."
  end

  private

  def set_product
    @product = Product.includes(:vendor, :brand, :product_class, :product_categories,
                                :product_stocks, :product_images,
                                { product_attributes: :product_attr },
                                { children: :product_stocks }).find(params[:id])
  end

  def product_params
    params.expect(
      product: [:name, :description, :description_th, :sku, :barcode, :product_type,
                :unit, :price, :cost, :remark, :vendor_id, :brand_id, :product_class_id,
                :parent_id, :enable_stock,
                { product_category_ids: [] },
                product_attributes_attributes: [[:id, :attribute_id, :value, :_destroy]]]
    )
  end
end
