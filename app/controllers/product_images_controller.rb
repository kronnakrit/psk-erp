# frozen_string_literal: true

class ProductImagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_product_image, only: %i[destroy]

  def index
    authorize ProductImage
    @product_images = policy_scope(ProductImage).where(product: @product).order(:position)
  end

  def create
    uploaded = params.dig(:product_image, :image)
    if uploaded.blank?
      skip_authorization
      return redirect_back fallback_location: product_path(@product), alert: "Please select an image to upload."
    end

    @product_image = @product.product_images.build
    @product_image.image.attach(uploaded)
    authorize @product_image
    if @product_image.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("product_images",
                                                   partial: "product_images/product_image",
                                                   locals: { product: @product, product_image: @product_image })
        end
        format.html { redirect_to product_path(@product), notice: "Image uploaded successfully." }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: product_path(@product), alert: @product_image.errors.full_messages.to_sentence }
      end
    end
  end

  def destroy
    authorize @product_image
    @product_image.destroy
    redirect_to product_product_images_path(@product), notice: "Image deleted successfully."
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_product_image
    @product_image = @product.product_images.find(params[:id])
  end
end
