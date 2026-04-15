# frozen_string_literal: true

class OrderImagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order
  before_action :set_order_image, only: %i[destroy]
  skip_after_action :verify_policy_scoped

  # GET /orders/:order_id/order_images
  def index
    @order_images = @order.order_images.order(:position)
    authorize OrderImage
  end

  # POST /orders/:order_id/order_images
  def create
    uploaded_image = params.dig(:order_image, :image)
    if uploaded_image.blank?
      skip_authorization
      return redirect_to order_path(@order), alert: "Please select an image to upload."
    end

    @order_image = @order.order_images.build(order_image_params)
    authorize @order_image
    if @order_image.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("order_images",
                                                   partial: "order_images/order_image",
                                                   locals: { order_image: @order_image })
        end
        format.html { redirect_to order_path(@order), notice: "Image uploaded." }
      end
    else
      respond_to do |format|
        format.html { redirect_to order_path(@order), alert: @order_image.errors.full_messages.to_sentence }
      end
    end
  end

  # DELETE /orders/:order_id/order_images/:id
  def destroy
    authorize @order_image
    @order_image.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("order_image_#{@order_image.id}") }
      format.html { redirect_to order_path(@order), notice: "Image removed." }
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_order_image
    @order_image = @order.order_images.find(params[:id])
  end

  def order_image_params
    params.expect(order_image: %i[image position])
  end
end
