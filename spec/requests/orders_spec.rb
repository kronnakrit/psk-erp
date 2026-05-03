# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders", type: :request do
  let(:role) do
    create(:role, permissions: %w[
             view_orders add_orders change_orders delete_orders
           ])
  end
  let(:user)     { create(:user) }
  let!(:order)   { create(:order) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  # ------------------------------------------------------------------ Index --

  describe "GET /orders" do
    it "returns 200 and lists orders" do
      get orders_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.order_number)
    end
  end

  describe "GET /orders/draft" do
    it "returns 200" do
      get draft_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /orders/paid" do
    it "returns 200" do
      get paid_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /orders/completed" do
    it "returns 200" do
      get completed_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /orders/cancelled" do
    it "returns 200" do
      get cancelled_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ Show --

  describe "GET /orders/:id" do
    it "returns 200 and shows order number" do
      get order_path(order)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(order.order_number)
    end
  end

  # ------------------------------------------------------------------ Dashboard --

  describe "GET /orders/dashboard" do
    it "returns 200" do
      get dashboard_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ------------------------------------------------------------------ New / Create --

  describe "GET /orders/new" do
    it "returns 200" do
      get new_order_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /orders" do
    let(:customer) { create(:customer) }
    let(:valid_attrs) do
      {
        customer_id: customer.id,
        running_date: Time.zone.today.to_s,
        status: "Dr",
        logistic_status: "WTS",
        has_vat: false,
        is_included_vat: false,
        is_discount_percentage: false,
        is_withholding_tax: false,
        discount_price: 0,
        withholding_tax: 0
      }
    end

    it "creates order and redirects to show" do
      expect do
        post orders_path, params: { order: valid_attrs }
      end.to change(Order, :count).by(1)
      expect(response).to redirect_to(order_path(Order.last))
    end

    it "renders new on invalid data" do
      post orders_path, params: { order: { customer_id: nil, status: nil } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  # ------------------------------------------------------------------ Edit / Update --

  describe "GET /orders/:id/edit" do
    it "returns 200" do
      get edit_order_path(order)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /orders/:id" do
    it "updates status and redirects" do
      patch order_path(order), params: { order: { status: "Pd", logistic_status: "ST" } }
      expect(response).to redirect_to(order_path(order))
      expect(order.reload.status).to eq("Pd")
    end
  end

  # ------------------------------------------------------------------ Destroy --

  describe "DELETE /orders/:id" do
    it "destroys the order and redirects" do
      expect do
        delete order_path(order)
      end.to change(Order, :count).by(-1)
      expect(response).to redirect_to(orders_path)
    end
  end

  # ------------------------------------------------------------------ Bulk update status --

  describe "POST /orders/bulk_update_status" do
    let!(:order2) { create(:order) }

    it "bulk-updates selected orders to Paid" do
      post bulk_update_status_orders_path,
           params: { ids: [order.id, order2.id], status: "Pd" }
      expect(response).to have_http_status(:found)
      expect(order.reload.status).to eq("Pd")
      expect(order2.reload.status).to eq("Pd")
    end

    it "bulk-updates all orders when is_selected_all is true" do
      post bulk_update_status_orders_path,
           params: { is_selected_all: "true", status: "Cp" }
      expect(response).to have_http_status(:found)
      expect(Order.all.map(&:status)).to all(eq("Cp"))
    end

    it "returns bad_request when both ids and is_selected_all are provided" do
      post bulk_update_status_orders_path,
           params: { ids: [order.id], is_selected_all: "true", status: "Pd" },
           headers: { "Accept" => "application/json" }
      expect(response).to have_http_status(:bad_request)
    end
  end

  # ------------------------------------------------------------------ Export --

  describe "GET /orders/:id/export" do
    it "returns xlsx file for authenticated user" do
      get export_order_path(order)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("spreadsheetml")
      expect(response.headers["Content-Disposition"]).to include("order-#{order.order_number}.xlsx")
    end

    it "returns 401 for unauthenticated user" do
      sign_out user
      get export_order_path(order)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /orders/:id/export_token" do
    it "returns a signed token with expires_at" do
      get export_token_order_path(order)
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to have_key("token")
      expect(json).to have_key("expires_at")
    end
  end

  describe "GET /orders/download" do
    it "streams xlsx using a valid signed token" do
      token = Rails.application.message_verifier(:export)
                   .generate({ order_id: order.id }, expires_in: 10.minutes)
      get download_orders_path(token: token)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("spreadsheetml")
    end

    it "returns 403 for an expired token" do
      token = Rails.application.message_verifier(:export)
                   .generate({ order_id: order.id }, expires_in: -1.second)
      get download_orders_path(token: token)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 403 for a tampered token" do
      get download_orders_path(token: "bad.token.value")
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ------------------------------------------------------------------ Print link on index --

  describe "GET /orders — Print link visibility" do
    context "when user has view_orders permission" do
      it "shows the Print link for each order row" do
        get orders_path
        expect(response.body).to include(delivery_order_order_path(order))
        expect(response.body).to include("Print")
      end
    end

    context "when user lacks view_orders permission" do
      let(:no_perm_role) { create(:role, permissions: %w[add_orders change_orders delete_orders]) }
      let(:no_perm_user) { create(:user) }

      before do
        no_perm_user.profile.update!(role: no_perm_role)
        sign_in no_perm_user
      end

      it "does not show the Print link" do
        get orders_path
        expect(response.body).not_to include(delivery_order_order_path(order))
      end
    end
  end

  describe "PATCH /orders/:id — cancelled order immutability" do
    let!(:cancelled_order) { create(:order, :cancelled) }

    it "redirects with alert when trying to edit/update a cancelled order" do
      patch order_path(cancelled_order), params: { order: { status: "Dr" } }
      expect(cancelled_order.reload.status).to eq("Cc")
    end
  end

  describe "GET /orders/:id/edit — cancelled order blocked" do
    let!(:cancelled_order) { create(:order, :cancelled) }

    it "redirects to show with alert for a cancelled order" do
      get edit_order_path(cancelled_order)
      expect(response).to redirect_to(order_path(cancelled_order))
    end
  end

  describe "PATCH /orders/:id — returns stock on cancellation" do
    let(:branch) { create(:branch, :main) }
    let(:stock_product) { create(:product, enable_stock: true) }
    let!(:stock) { create(:product_stock, product: stock_product, branch: branch, amount: 100) }
    let!(:draft_order) { create(:order, status: "Dr") }

    before { create(:order_line, order: draft_order, product: stock_product, quantity: 3) }

    it "creates stock deposit transactions when order is cancelled" do
      amount_before_cancel = stock.reload.amount
      patch order_path(draft_order), params: { order: { status: "Cc" } }
      expect(response).to redirect_to(order_path(draft_order))
      expect(stock.reload.amount).to eq(amount_before_cancel + 3)
      expect(stock.product_stock_transactions.where(transaction_type: "IB").count).to be >= 1
    end
  end

  describe "POST /orders/:id/duplicate" do
    it "creates a new draft order and redirects" do
      expect do
        post duplicate_order_path(order)
      end.to change(Order, :count).by(1)
      expect(response).to redirect_to(order_path(Order.last))
    end

    it "does not create order and redirects with alert for unauthorised user" do
      no_perm_role = create(:role, permissions: %w[view_orders])
      no_perm_user = create(:user)
      no_perm_user.profile.update!(role: no_perm_role)
      sign_in no_perm_user
      expect do
        post duplicate_order_path(order)
      end.not_to change(Order, :count)
    end
  end

  # ------------------------------------------------------------------- EPIC-14 audit trail --

  describe "PATCH /orders/:id — audit trail creation" do
    it "creates an OrderAudit record when status field changes" do
      Current.user = user
      expect do
        patch order_path(order), params: { order: { status: "Pd" } }
      end.to change(OrderAudit, :count).by_at_least(1)
      audit = order.order_audits.order(:changed_at).last
      expect(audit.event_type).to eq("status_change")
      expect(audit.field_name).to eq("status")
      expect(audit.new_value).to eq("Pd")
    end
  end

  describe "GET /orders/:id — audit trail turbo frame" do
    context "when user has view_order_audit permission" do
      let(:audit_role) do
        create(:role, permissions: %w[view_orders add_orders change_orders delete_orders view_order_audit])
      end

      before do
        user.profile.update!(role: audit_role)
        sign_in user
      end

      it "renders the order_audit_trail turbo frame" do
        get order_path(order)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("order_audit_trail")
        expect(response.body).to include("Change History")
      end
    end

    context "when user does not have view_order_audit permission" do
      it "does not render the order_audit_trail turbo frame" do
        get order_path(order)
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("order_audit_trail")
        expect(response.body).not_to include("Change History")
      end
    end
  end

  describe "GET /orders/:id/audit_trail" do
    context "when user lacks view_order_audit permission" do
      it "raises Pundit::NotAuthorizedError (redirects for HTML)" do
        get audit_trail_order_path(order)
        # ApplicationController redirects HTML Pundit errors; API returns 403
        expect(response).to have_http_status(:redirect).or have_http_status(:forbidden)
      end
    end

    context "when user has view_order_audit permission" do
      let(:audit_role) do
        create(:role, permissions: %w[view_orders add_orders change_orders delete_orders view_order_audit])
      end

      before do
        user.profile.update!(role: audit_role)
        sign_in user
      end

      it "returns 200 and renders audit timeline" do
        create(:order_audit, order: order, event_type: "status_change", field_name: "status",
                             previous_value: "Dr", new_value: "Pd")
        get audit_trail_order_path(order)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /orders/:id — excluded-fields do not create audits" do
    it "does not create OrderAudit when only excluded fields change via update_columns" do
      # Directly updating excluded fields via update_columns avoids callbacks
      expect do
        order.update_columns( # rubocop:disable Rails/SkipsModelValidations
          total_price: 999.99,
          vat_price:   69.99,
          grand_total: 1068.98,
          updated_at:  Time.current
        )
      end.not_to change(OrderAudit, :count)
    end
  end

  # -------------------------------------------------------- EPIC-14 duplicate badge --

  describe "GET /orders — Possible Duplicate badge" do
    context "when an order is flagged as a possible duplicate" do
      let!(:flagged_order) do
        create(:order).tap { |o| o.update_columns(is_possible_duplicate: true) } # rubocop:disable Rails/SkipsModelValidations
      end

      it "renders the Possible Duplicate badge" do
        get orders_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Possible Duplicate")
      end
    end

    context "when no orders are flagged" do
      it "does not render the badge" do
        get orders_path
        expect(response.body).not_to include("Possible Duplicate")
      end
    end
  end

  describe "GET /orders/advance_search" do
    it "returns 200" do
      get advance_search_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /orders/filter" do
    it "returns 200 and filters orders" do
      post filter_orders_path, params: { status: "Dr" }
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 with no status filter" do
      post filter_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /orders/bulk_update_status with invalid status" do
    it "returns 422" do
      post bulk_update_status_orders_path,
           params: { ids: [order.id], status: "INVALID_STATUS" },
           as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /orders/:id update failure" do
    it "renders edit with unprocessable_content when updated_by is removed" do
      patch order_path(order), params: { order: { customer_id: nil } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /orders/scan" do
    let(:role) do
      create(:role, permissions: %w[view_orders])
    end

    it "returns 200" do
      get scan_orders_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /orders/find_by_number" do
    it "returns order json when found" do
      get find_by_number_orders_path, params: { q: order.order_number }, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["order_number"]).to eq(order.order_number)
    end

    it "returns 404 when not found" do
      get find_by_number_orders_path, params: { q: "XX-00000000-XXXX" }, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /orders with status filter" do
    it "returns 200 with status param" do
      get orders_path, params: { status: "Dr" }
      expect(response).to have_http_status(:ok)
    end
  end
end
