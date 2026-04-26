# frozen_string_literal: true

require "rails_helper"

RSpec.describe "InvoiceOrders", type: :request do
  let(:role) { create(:role, permissions: %w[view_invoices add_invoices change_invoices]) }
  let(:user)     { create(:user) }
  let(:customer) { create(:customer) }
  let!(:order)   { create(:order, customer: customer, status: "Pd") }
  let!(:order2)  { create(:order, customer: customer, status: "Pd") }
  let!(:invoice) { create(:invoice, customer: customer) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  # ------------------------------------------------------------------ Create --

  describe "POST /invoices/:invoice_id/invoice_orders" do
    context "when adding a new valid order" do
      it "adds the order and redirects to invoice" do
        expect {
          post invoice_invoice_orders_path(invoice), params: { order_ids: [order.id] }
        }.to change { invoice.reload.invoice_orders.count }.by(1)
        expect(response).to redirect_to(invoice_path(invoice))
      end
    end

    context "when invoice is not Draft" do
      let!(:paid_invoice) { create(:invoice, :paid, customer: customer) }

      it "returns 422 with alert" do
        post invoice_invoice_orders_path(paid_invoice), params: { order_ids: [order.id] }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when order belongs to a different customer" do
      let(:other_order) { create(:order, status: "Pd") }

      it "returns 422 with alert" do
        post invoice_invoice_orders_path(invoice), params: { order_ids: [other_order.id] }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when no orders selected" do
      it "redirects to add_orders page" do
        post invoice_invoice_orders_path(invoice), params: { order_ids: [] }
        expect(response).to redirect_to(add_orders_invoice_path(invoice))
      end
    end
  end

  # ------------------------------------------------------------------ Destroy --

  describe "DELETE /invoices/:invoice_id/invoice_orders/:id" do
    context "when more than one order on invoice" do
      before do
        invoice.invoice_orders.create!(order: order)
        invoice.invoice_orders.create!(order: order2)
      end

      it "removes the order and redirects" do
        expect {
          delete invoice_invoice_order_path(invoice, order)
        }.to change { invoice.reload.invoice_orders.count }.by(-1)
        expect(response).to redirect_to(invoice_path(invoice))
      end
    end

    context "when only one order remains" do
      before { invoice.invoice_orders.create!(order: order) }

      it "returns redirect with alert (last-order guard)" do
        delete invoice_invoice_order_path(invoice, order)
        expect(response).to redirect_to(invoice_path(invoice))
        expect(flash[:alert]).to include("at least one order")
      end
    end

    context "when invoice is not Draft" do
      let!(:paid_invoice) { create(:invoice, :paid, customer: customer) }

      before { paid_invoice.invoice_orders.create!(order: order) }

      it "returns 422" do
        delete invoice_invoice_order_path(paid_invoice, order)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
