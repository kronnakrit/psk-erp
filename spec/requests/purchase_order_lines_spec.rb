# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PurchaseOrderLines", type: :request do # rubocop:disable RSpec/MultipleMemoizedHelpers
  let(:admin_role) do
    create(:role, permissions: %w[
             view_purchase_orders add_purchase_orders change_purchase_orders delete_purchase_orders
           ])
  end
  let(:user)       { create(:user) }
  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, ratio: 1) }
  let(:product)    { create(:product, unit_group: unit_group) }
  let!(:po)        { create(:purchase_order, supplier: create(:supplier)) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "POST /purchase_orders/:id/purchase_order_lines" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:valid_attrs) do
      { product_id: product.id, unit_definition_id: unit_def.id, quantity: 5, unit_cost: 10.00 }
    end

    it "creates line and responds with turbo stream" do
      post purchase_order_purchase_order_lines_path(po),
           params: { purchase_order_line: valid_attrs },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(po.purchase_order_lines.count).to eq(1)
    end

    it "returns 422 when quantity is 0" do
      post purchase_order_purchase_order_lines_path(po),
           params: { purchase_order_line: valid_attrs.merge(quantity: 0) },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns 403 when PO is confirmed" do
      po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
      post purchase_order_purchase_order_lines_path(po),
           params: { purchase_order_line: valid_attrs }
      expect(response).to have_http_status(:forbidden)
    end

    it "returns html redirect on create failure" do
      post purchase_order_purchase_order_lines_path(po),
           params: { purchase_order_line: valid_attrs.merge(quantity: 0) }
      expect(response).to redirect_to(purchase_order_path(po))
    end
  end

  describe "PATCH /purchase_orders/:id/purchase_order_lines/:line_id" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let!(:line) do
      create(:purchase_order_line,
             purchase_order: po, product: product, unit_definition: unit_def)
    end

    it "updates line and responds with turbo stream" do
      patch purchase_order_purchase_order_line_path(po, line),
            params: { purchase_order_line: { quantity: 10, unit_cost: 20.00 } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(line.reload.quantity).to eq(10)
    end

    it "returns 422 on turbo_stream when quantity is 0" do
      patch purchase_order_purchase_order_line_path(po, line),
            params: { purchase_order_line: { quantity: 0 } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns html redirect on update success" do
      patch purchase_order_purchase_order_line_path(po, line),
            params: { purchase_order_line: { quantity: 10 } }
      expect(response).to redirect_to(purchase_order_path(po))
    end

    it "returns html redirect on update failure" do
      patch purchase_order_purchase_order_line_path(po, line),
            params: { purchase_order_line: { quantity: 0 } }
      expect(response).to redirect_to(purchase_order_path(po))
    end

    it "returns 403 when PO is confirmed" do
      po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
      patch purchase_order_purchase_order_line_path(po, line),
            params: { purchase_order_line: { quantity: 10 } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /purchase_orders/:id/purchase_order_lines/:line_id" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let!(:line) do
      create(:purchase_order_line,
             purchase_order: po, product: product, unit_definition: unit_def)
    end

    it "removes line and responds with turbo stream" do
      delete purchase_order_purchase_order_line_path(po, line),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
      expect(PurchaseOrderLine.exists?(line.id)).to be false
    end

    it "returns 403 when PO is confirmed" do
      po.update_columns(status: "Cf") # rubocop:disable Rails/SkipsModelValidations
      delete purchase_order_purchase_order_line_path(po, line)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
