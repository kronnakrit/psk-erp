# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Order Lines (web)", type: :request do # rubocop:disable RSpec/MultipleMemoizedHelpers
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:customer)   { create(:customer) }
  let(:order)      { create(:order, customer: customer, created_by: admin_user) }
  let(:unit_group) { create(:unit_group, :default) }
  let(:unit_def) do
    unit_group.unit_definitions.find_by(ratio: 1) ||
      create(:unit_definition, unit_group: unit_group, name: "pcs", ratio: 1)
  end
  let(:product) { create(:product, unit_group: unit_group) }

  before { sign_in admin_user }

  describe "POST /orders/:order_id/order_lines" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    it "creates an order line and responds with turbo_stream" do
      post order_order_lines_path(order),
           params: { order_line: {
             product_id: product.id, unit_definition_id: unit_def.id,
             quantity: 2, unit_price: 100, discount_price: 0
           } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
    end

    it "falls back to html redirect on failure" do
      post order_order_lines_path(order),
           params: { order_line: {
             product_id: nil, unit_definition_id: unit_def.id,
             quantity: 1, unit_price: 100, discount_price: 0
           } }
      expect(response).to redirect_to(order_path(order))
    end

    it "returns turbo_stream error response on failure" do
      post order_order_lines_path(order),
           params: { order_line: {
             product_id: nil, unit_definition_id: unit_def.id,
             quantity: 1, unit_price: 100, discount_price: 0
           } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /orders/:order_id/order_lines/:id" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:order_line) { create(:order_line, order: order, product: product) }

    it "updates an order line" do
      patch order_order_line_path(order, order_line),
            params: { order_line: { quantity: 5 } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(order_line.reload.quantity).to eq(5)
    end

    it "renders turbo_stream error on update failure" do
      patch order_order_line_path(order, order_line),
            params: { order_line: { quantity: 0 } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
    end

    it "redirects to order on update failure via html" do
      patch order_order_line_path(order, order_line),
            params: { order_line: { quantity: 0 } }
      expect(response).to redirect_to(order_path(order))
    end
  end

  describe "DELETE /orders/:order_id/order_lines/:id" do # rubocop:disable RSpec/MultipleMemoizedHelpers
    let(:order_line) { create(:order_line, order: order, product: product) }

    it "destroys the order line" do
      delete order_order_line_path(order, order_line),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(OrderLine.find_by(id: order_line.id)).to be_nil
    end
  end
end
