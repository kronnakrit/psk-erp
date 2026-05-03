# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoices", type: :request do
  let(:role) do
    create(:role, permissions: %w[
             view_invoices add_invoices change_invoices view_invoice_audit
           ])
  end
  let(:user)     { create(:user) }
  let(:customer) { create(:customer) }
  let!(:order)   { create(:order, customer: customer, status: "Pd") }
  let!(:invoice) { create(:invoice, customer: customer) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  # ------------------------------------------------------------------ Index --

  describe "GET /invoices" do
    it "returns 200 and lists invoices" do
      get invoices_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invoice.invoice_number)
    end
  end

  describe "GET /invoices/draft" do
    it "returns 200" do
      get draft_invoices_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /invoices/paid" do
    it "returns 200" do
      get paid_invoices_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /invoices/cancelled" do
    it "returns 200" do
      get cancelled_invoices_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ Show --

  describe "GET /invoices/:id" do
    it "returns 200 and shows invoice details" do
      get invoice_path(invoice)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(invoice.invoice_number)
    end
  end

  describe "GET /invoices/:id/audit_trail" do
    it "returns 200 and renders audit partial" do
      create(:invoice_audit, invoice: invoice, event_type: "status_change",
                             field_name: "status", new_value: "Pd", changed_by: user)
      get audit_trail_invoice_path(invoice)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /invoices/:id/print" do
    it "returns 200 and uses print layout" do
      get print_invoice_path(invoice)
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ New / Create --

  describe "GET /invoices/new" do
    it "returns 200 and shows eligible orders" do
      get new_invoice_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /invoices" do
    context "when no orders selected" do
      it "returns 422 and re-renders new" do
        post invoices_path, params: { order_ids: [] }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with valid orders" do
      it "creates an invoice and redirects" do
        expect {
          post invoices_path, params: { order_ids: [order.id] }
        }.to change(Invoice, :count).by(1)
        expect(response).to redirect_to(invoices_path)
      end
    end

    context "when order is already on an active invoice" do
      before { create(:invoice_order, invoice: invoice, order: order) }

      it "returns 422 and re-renders new" do
        post invoices_path, params: { order_ids: [order.id] }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ------------------------------------------------------------------ Edit / Update --

  describe "GET /invoices/:id/edit" do
    it "returns 200" do
      get edit_invoice_path(invoice)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /invoices/:id" do
    it "updates remark and redirects to show" do
      patch invoice_path(invoice), params: { invoice: { remark: "Updated remark" } }
      expect(response).to redirect_to(invoice_path(invoice))
      expect(invoice.reload.remark).to eq("Updated remark")
    end
  end

  # ------------------------------------------------------------------ Cancel --

  describe "POST /invoices/:id/cancel" do
    context "when invoice is Draft" do
      it "cancels and redirects to index" do
        post cancel_invoice_path(invoice)
        expect(response).to redirect_to(invoices_path)
        expect(invoice.reload.status).to eq("Cc")
      end
    end

    context "when invoice is already Cancelled" do
      let!(:invoice) { create(:invoice, :cancelled, customer: customer) }

      it "redirects to root (policy denies cancel? on non-Draft)" do
        post cancel_invoice_path(invoice)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when invoice is Paid" do
      let!(:invoice) { create(:invoice, :paid, customer: customer) }

      it "redirects to root (policy denies cancel? on Paid) and does not cancel" do
        post cancel_invoice_path(invoice)
        expect(response).to redirect_to(root_path)
        expect(invoice.reload.status).to eq("Pd")
      end
    end
  end

  # ------------------------------------------------------------------ Mark Paid --

  describe "POST /invoices/:id/mark_paid" do
    context "when invoice is Draft" do
      it "marks as paid and redirects to show" do
        post mark_paid_invoice_path(invoice)
        expect(response).to redirect_to(invoice_path(invoice))
        expect(invoice.reload.status).to eq("Pd")
      end
    end

    context "when invoice is already Paid" do
      let!(:invoice) { create(:invoice, :paid, customer: customer) }

      it "redirects to root (policy denies mark_paid? on non-Draft)" do
        post mark_paid_invoice_path(invoice)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ------------------------------------------------------------------ Reopen --

  describe "POST /invoices/:id/reopen" do
    context "when invoice is Paid" do
      let!(:invoice) { create(:invoice, :paid, customer: customer) }

      it "reopens to Draft and redirects" do
        post reopen_invoice_path(invoice)
        expect(response).to redirect_to(invoice_path(invoice))
        expect(invoice.reload.status).to eq("Dr")
      end
    end

    context "when invoice is Draft" do
      it "redirects to root (policy denies reopen? on non-Paid)" do
        post reopen_invoice_path(invoice)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ------------------------------------------------------------------ Bulk Update Status --

  describe "POST /invoices/bulk_update_status" do
    let!(:invoice2) { create(:invoice, customer: customer) }

    it "updates status for all selected invoices" do
      post bulk_update_status_invoices_path,
           params: { ids: [invoice.id, invoice2.id], status: "Pd" }
      expect(response).to redirect_to(invoices_path)
      expect(invoice.reload.status).to eq("Pd")
      expect(invoice2.reload.status).to eq("Pd")
    end

    it "rejects Cc status with 422" do
      post bulk_update_status_invoices_path,
           params: { ids: [invoice.id], status: "Cc" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects empty ids with 422" do
      post bulk_update_status_invoices_path, params: { ids: [], status: "Pd" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ------------------------------------------------------------------ Add Orders page --

  describe "GET /invoices/:id/add_orders" do
    it "returns 200 and shows eligible orders" do
      get add_orders_invoice_path(invoice)
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ Unauthorised --

  describe "when user lacks view_invoices permission" do
    let(:role) { create(:role, permissions: []) }

    it "redirects with alert (Pundit rescued by ApplicationController)" do
      get invoices_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH /invoices/:id update failure" do
    it "renders edit on invalid data" do
      allow_any_instance_of(Invoice).to receive(:update).and_return(false) # rubocop:disable RSpec/AnyInstance
      patch invoice_path(invoice), params: { invoice: { remark: "x" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /invoices/:id/cancel status guards" do
    context "when invoice is already Cancelled" do
      before do
        invoice.update_columns(status: "Cc") # rubocop:disable Rails/SkipsModelValidations
        allow_any_instance_of(InvoicePolicy).to receive(:cancel?).and_return(true) # rubocop:disable RSpec/AnyInstance
      end

      it "redirects with already-cancelled message" do
        post cancel_invoice_path(invoice)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /invoices/:id/mark_paid status guard" do
    context "when invoice is already Paid" do
      before do
        invoice.update_columns(status: "Pd") # rubocop:disable Rails/SkipsModelValidations
        allow_any_instance_of(InvoicePolicy).to receive(:mark_paid?).and_return(true) # rubocop:disable RSpec/AnyInstance
      end

      it "redirects to invoice with alert" do
        post mark_paid_invoice_path(invoice)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /invoices/:id/reopen status guard" do
    context "when invoice is Draft (not Paid)" do
      before do
        allow_any_instance_of(InvoicePolicy).to receive(:reopen?).and_return(true) # rubocop:disable RSpec/AnyInstance
      end

      it "redirects to invoice with alert" do
        post reopen_invoice_path(invoice)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "POST /invoices/bulk_update_status invalid status" do
    it "rejects invalid status with 422" do
      post bulk_update_status_invoices_path, params: { ids: [invoice.id], status: "INVALID" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /invoices/:id with non-existent id" do
    it "returns 404" do
      get invoice_path(id: 99_999_999)
      expect(response).to have_http_status(:not_found)
    end
  end
end
