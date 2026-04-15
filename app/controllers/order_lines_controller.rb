# frozen_string_literal: true

class OrderLinesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order
  before_action :set_order_line, only: %i[update destroy]

  # POST /orders/:order_id/order_lines
  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    @order_line = @order.order_lines.build(order_line_params)
    authorize @order_line
    if @order_line.save
      @order.reload
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("order_lines", partial: "order_lines/order_line",
                                               locals: { order_line: @order_line, order: @order }),
            turbo_stream.replace("grand_total_panel",
                                 partial: "orders/grand_total", locals: { order: @order })
          ]
        end
        format.html { redirect_to order_path(@order) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash_messages",
                                                    partial: "shared/flash",
                                                    locals: { error: @order_line.errors.full_messages.to_sentence })
        end
        format.html { redirect_to order_path(@order), alert: @order_line.errors.full_messages.to_sentence }
      end
    end
  end

  # PATCH /orders/:order_id/order_lines/:id
  def update # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    authorize @order_line
    if @order_line.update(order_line_params)
      @order.reload
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("order_line_#{@order_line.id}",
                                 partial: "order_lines/order_line",
                                 locals: { order_line: @order_line, order: @order }),
            turbo_stream.replace("grand_total_panel",
                                 partial: "orders/grand_total", locals: { order: @order })
          ]
        end
        format.html { redirect_to order_path(@order) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("flash_messages",
                                                    partial: "shared/flash",
                                                    locals: { error: @order_line.errors.full_messages.to_sentence })
        end
        format.html do
          redirect_to order_path(@order), alert: @order_line.errors.full_messages.to_sentence
        end
      end
    end
  end

  # DELETE /orders/:order_id/order_lines/:id
  def destroy
    authorize @order_line
    @order_line.destroy
    @order.reload
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("order_line_#{@order_line.id}"),
          turbo_stream.replace("grand_total_panel",
                               partial: "orders/grand_total", locals: { order: @order })
        ]
      end
      format.html { redirect_to order_path(@order) }
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_order_line
    @order_line = @order.order_lines.find(params[:id])
  end

  def order_line_params
    params.expect(order_line: %i[
                    product_id unit quantity unit_price discount_price
                    description remark idx
                  ])
  end
end
