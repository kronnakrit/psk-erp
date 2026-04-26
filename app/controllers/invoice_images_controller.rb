# frozen_string_literal: true

class InvoiceImagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_invoice
  before_action :set_invoice_image, only: %i[destroy]
  skip_after_action :verify_policy_scoped

  # POST /invoices/:invoice_id/invoice_images
  def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    uploaded_image = params.dig(:invoice_image, :image)
    if uploaded_image.blank?
      skip_authorization
      return redirect_to invoice_path(@invoice), alert: "Please select an image to upload."
    end

    @invoice_image = @invoice.invoice_images.build(invoice_image_params)
    authorize @invoice_image
    if @invoice_image.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("invoice_images",
                                                   partial: "invoice_images/invoice_image",
                                                   locals: { invoice_image: @invoice_image })
        end
        format.html { redirect_to invoice_path(@invoice), notice: "Image uploaded." }
      end
    else
      respond_to do |format|
        format.html { redirect_to invoice_path(@invoice), alert: @invoice_image.errors.full_messages.to_sentence }
      end
    end
  end

  # DELETE /invoices/:invoice_id/invoice_images/:id
  def destroy
    authorize @invoice_image
    @invoice_image.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("invoice_image_#{@invoice_image.id}") }
      format.html { redirect_to invoice_path(@invoice), notice: "Image removed." }
    end
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:invoice_id])
  end

  def set_invoice_image
    @invoice_image = @invoice.invoice_images.find(params[:id])
  end

  def invoice_image_params
    params.expect(invoice_image: [:image])
  end
end
