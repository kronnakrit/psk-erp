# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: %i[show edit update destroy unit_definitions lots duplicate]

  def index
    @default_unit_group = UnitGroup.includes(:unit_definitions).find_by(is_default: true)
    @ransack = policy_scope(Product)
               .includes(:brand, :product_class, :product_stocks, { unit_group: :unit_definitions },
                         :featured_image_attachment, { product_images: { image_attachment: :blob } },
                         { children: [:product_stocks, :featured_image_attachment, { unit_group: :unit_definitions },
                                      { product_images: { image_attachment: :blob } }] })
               .ransack(params[:q])
    @ransack.sorts = "name asc" if @ransack.sorts.empty?
    @pagy, @products = pagy(@ransack.result)
    authorize Product
  end

  def show
    authorize @product
  end

  def lots
    authorize @product, :show?
    @lots = @product.product_lots.includes(:purchase_order).order(received_date: :asc)
  end

  def new
    @product = Product.new
    @brands = Brand.order(:name)
    @product_classes = ProductClass.order(:name)
    @product_categories = ProductCategory.order(:name)
    @unit_groups = UnitGroup.order(:name)
    authorize @product
  end

  def edit
    @brands = Brand.order(:name)
    @product_classes = ProductClass.order(:name)
    @product_categories = ProductCategory.order(:name)
    @unit_groups = UnitGroup.order(:name)
    authorize @product
  end

  def create
    @product = Product.new(product_params)
    authorize @product
    if @product.save
      if params[:commit] == "Create and New"
        redirect_to new_product_path, notice: "Product created successfully."
      else
        redirect_to products_path, notice: "Product created successfully."
      end
    else
      @brands = Brand.order(:name)
      @product_classes = ProductClass.order(:name)
      @product_categories = ProductCategory.order(:name)
      @unit_groups = UnitGroup.order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @product
    if @product.update(product_params)
      redirect_to products_path, notice: "Product updated successfully."
    else
      @brands = Brand.order(:name)
      @product_classes = ProductClass.order(:name)
      @product_categories = ProductCategory.order(:name)
      @unit_groups = UnitGroup.order(:name)
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @product
    @product.destroy
    redirect_to products_path, notice: "Product deleted successfully."
  end

  def duplicate
    authorize @product, :duplicate?
    new_product = Products::DuplicateService.new(@product).call
    if new_product.save
      redirect_to edit_product_path(new_product), notice: "Product duplicated as \"#{new_product.name}\"."
    else
      redirect_to product_path(@product), alert: "Could not duplicate product: #{new_product.errors.full_messages.to_sentence}."
    end
  end

  def unit_definitions
    authorize @product, :show?
    group = @product.effective_unit_group
    defs = if group
             group.unit_definitions.order(ratio: :desc).map do |ud|
               { id: ud.id, name: ud.name, ratio: ud.ratio, is_base: ud.ratio == 1 }
             end
           else
             []
           end
    render json: defs
  end

  private

  def set_product
    @product = Product.includes(:brand, :product_class, :product_categories,
                                :product_stocks, :product_images, { unit_group: :unit_definitions },
                                { product_attributes: :product_attr },
                                { children: [:product_stocks, { unit_group: :unit_definitions }] }).find(params[:id])
  end

  def product_params
    params.expect(
      product: [:name, :description, :description_th, :sku, :barcode, :product_type,
                :unit_group_id, :price, :remark, :brand_id, :product_class_id,
                :parent_id, :enable_stock,
                { product_category_ids: [] },
                product_attributes_attributes: [%i[id attribute_id value _destroy]]]
    )
  end
end
