# frozen_string_literal: true

class PurchaseOrderLinesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_purchase_order
  before_action :set_purchase_order_line, only: %i[update destroy]

  # POST /purchase_orders/:purchase_order_id/purchase_order_lines
  def create
    return render_forbidden if @purchase_order.confirmed? || @purchase_order.cancelled?

    @purchase_order_line = @purchase_order.purchase_order_lines.build(purchase_order_line_params)
    authorize @purchase_order, :update?
    if @purchase_order_line.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove("empty_lines_row"),
            turbo_stream.append("purchase_order_lines",
                                partial: "purchase_orders/purchase_order_line",
                                locals: { line: @purchase_order_line,
                                          purchase_order: @purchase_order }),
            turbo_stream.replace("po_total_panel",
                                 partial: "purchase_orders/po_total",
                                 locals: { purchase_order: @purchase_order.reload })
          ]
        end
        format.html { redirect_to purchase_order_path(@purchase_order) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @purchase_order_line.errors.full_messages.to_sentence
          render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash"),
                 status: :unprocessable_content
        end
        format.html do
          redirect_to purchase_order_path(@purchase_order),
                      alert: @purchase_order_line.errors.full_messages.to_sentence
        end
      end
    end
  end

  # PATCH /purchase_orders/:purchase_order_id/purchase_order_lines/:id
  def update
    return render_forbidden if @purchase_order.confirmed? || @purchase_order.cancelled?

    authorize @purchase_order, :update?
    if @purchase_order_line.update(purchase_order_line_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("purchase_order_line_#{@purchase_order_line.id}",
                                 partial: "purchase_orders/purchase_order_line",
                                 locals: { line: @purchase_order_line,
                                           purchase_order: @purchase_order }),
            turbo_stream.replace("po_total_panel",
                                 partial: "purchase_orders/po_total",
                                 locals: { purchase_order: @purchase_order.reload })
          ]
        end
        format.html { redirect_to purchase_order_path(@purchase_order) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = @purchase_order_line.errors.full_messages.to_sentence
          render turbo_stream: turbo_stream.replace("flash_messages", partial: "layouts/flash"),
                 status: :unprocessable_content
        end
        format.html do
          redirect_to purchase_order_path(@purchase_order),
                      alert: @purchase_order_line.errors.full_messages.to_sentence
        end
      end
    end
  end

  # DELETE /purchase_orders/:purchase_order_id/purchase_order_lines/:id
  def destroy
    return render_forbidden if @purchase_order.confirmed? || @purchase_order.cancelled?

    authorize @purchase_order, :update?
    @purchase_order_line.destroy
    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.remove("purchase_order_line_#{@purchase_order_line.id}"),
          turbo_stream.replace("po_total_panel",
                               partial: "purchase_orders/po_total",
                               locals: { purchase_order: @purchase_order.reload })
        ]
        if @purchase_order.purchase_order_lines.empty?
          empty_row = <<~HTML.html_safe
            <tr id="empty_lines_row">
              <td colspan="7" class="px-4 py-8 text-center text-gray-400">No lines added yet.</td>
            </tr>
          HTML
          streams << turbo_stream.append("purchase_order_lines", html: empty_row)
        end
        render turbo_stream: streams
      end
      format.html { redirect_to purchase_order_path(@purchase_order) }
    end
  end

  private

  def set_purchase_order
    @purchase_order = PurchaseOrder.find(params[:purchase_order_id])
  end

  def set_purchase_order_line
    @purchase_order_line = @purchase_order.purchase_order_lines.find(params[:id])
  end

  def render_forbidden
    skip_authorization
    head :forbidden
  end

  def purchase_order_line_params
    params.expect(purchase_order_line: %i[product_id unit_definition_id quantity unit_cost])
  end
end
