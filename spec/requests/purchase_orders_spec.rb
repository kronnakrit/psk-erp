# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PurchaseOrders", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_purchase_orders add_purchase_orders change_purchase_orders delete_purchase_orders
           ])
  end
  let(:user)     { create(:user) }
  let(:supplier) { create(:supplier) }
  let!(:po)      { create(:purchase_order, supplier: supplier) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /purchase_orders" do
    it "returns 200" do
      get purchase_orders_path
      expect(response).to have_http_status(:ok)
    end

    it "lists purchase orders" do
      get purchase_orders_path
      expect(response.body).to include(po.po_number)
    end
  end

  describe "GET /purchase_orders/:id" do
    it "returns 200" do
      get purchase_order_path(po)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /purchase_orders/new" do
    it "returns 200" do
      get new_purchase_order_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /purchase_orders" do
    let(:valid_attrs) { { supplier_id: supplier.id, po_date: Time.zone.today, remark: "test" } }

    it "creates and redirects to show" do
      expect do
        post purchase_orders_path,
             params: { purchase_order: valid_attrs }
      end.to change(PurchaseOrder, :count).by(1)
      expect(response).to redirect_to(purchase_order_path(PurchaseOrder.last))
    end

    it "renders new on missing supplier" do
      post purchase_orders_path,
           params: { purchase_order: { supplier_id: nil, po_date: Time.zone.today } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /purchase_orders/:id/edit" do
    it "returns 200 for draft PO" do
      get edit_purchase_order_path(po)
      expect(response).to have_http_status(:ok)
    end

    it "redirects for confirmed PO" do
      po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
      get edit_purchase_order_path(po)
      expect(response).to redirect_to(purchase_order_path(po))
    end
  end

  describe "PATCH /purchase_orders/:id" do
    it "updates and redirects" do
      patch purchase_order_path(po),
            params: { purchase_order: { remark: "Updated remark" } }
      expect(response).to redirect_to(purchase_order_path(po))
      expect(po.reload.remark).to eq("Updated remark")
    end

    it "blocks update on confirmed PO" do
      po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
      patch purchase_order_path(po),
            params: { purchase_order: { remark: "Attempt" } }
      expect(response).to redirect_to(purchase_order_path(po))
    end
  end

  describe "DELETE /purchase_orders/:id" do
    it "destroys draft and redirects" do
      expect do
        delete purchase_order_path(po)
      end.to change(PurchaseOrder, :count).by(-1)
      expect(response).to redirect_to(purchase_orders_path)
    end

    it "cannot destroy confirmed PO" do
      po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
      expect do
        delete purchase_order_path(po)
      end.not_to change(PurchaseOrder, :count)
      expect(response).to redirect_to(purchase_orders_path)
    end
  end

  describe "POST /purchase_orders/:id/confirm" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:unit_group) { create(:unit_group) }
    let(:unit_def)   { create(:unit_definition, unit_group: unit_group, ratio: 1) }
    let(:product)    { create(:product, unit_group: unit_group) }

    it "confirms a draft PO with lines" do
      create(:purchase_order_line, purchase_order: po, product: product, unit_definition: unit_def)
      post confirm_purchase_order_path(po)
      expect(po.reload.status).to eq("Cf")
      expect(response).to redirect_to(purchase_order_path(po))
      expect(flash[:notice]).to include("product lot(s) created")
    end

    it "creates ProductLots on confirmation" do
      create(:purchase_order_line, purchase_order: po, product: product, unit_definition: unit_def)
      expect { post confirm_purchase_order_path(po) }.to change(ProductLot, :count).by(1)
    end

    it "returns alert when already confirmed" do
      po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
      post confirm_purchase_order_path(po)
      expect(response).to redirect_to(purchase_order_path(po))
      expect(flash[:alert]).to include("already confirmed")
    end

    it "returns alert when PO is cancelled" do
      po.update_columns(status: "Cc") # rubocop:disable Rails/SkipsModelValidations
      post confirm_purchase_order_path(po)
      expect(flash[:alert]).to include("cancelled")
    end

    it "returns alert when PO has no lines" do
      post confirm_purchase_order_path(po)
      expect(flash[:alert]).to include("no lines")
    end
  end

  describe "GET /purchase_orders (unauthorised)" do
    it "redirects when user has no view_purchase_orders permission" do
      user.profile.update!(role: create(:role, permissions: []))
      get purchase_orders_path
      expect(response).to redirect_to(root_path)
    end
  end
end
