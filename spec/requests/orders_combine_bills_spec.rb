# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders combine_bills", type: :request do
  let(:role) { create(:role, permissions: %w[view_orders add_orders change_orders delete_orders]) }
  let(:user)       { create(:user) }
  let(:customer)   { create(:customer) }
  let!(:order1)    { create(:order, customer: customer, grand_total: 1000) }
  let!(:order2)    { create(:order, customer: customer, grand_total: 2500) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "POST /orders/combine_bills" do
    it "returns xlsx for same-customer orders" do
      post combine_bills_orders_path, params: { ids: [order1.id, order2.id] }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("spreadsheetml")
      expect(response.headers["Content-Disposition"]).to include("%E0%B9%83%E0%B8%9A%E0%B8%A3%E0%B8%A7%E0%B8%A1%E0%B8%9A%E0%B8%B4%E0%B8%A5")
    end

    it "redirects with alert when orders from different customers" do
      other_customer = create(:customer)
      other_order    = create(:order, customer: other_customer)
      post combine_bills_orders_path, params: { ids: [order1.id, other_order.id] }
      expect(response).to redirect_to(orders_path)
      follow_redirect!
      expect(response.body).to include("same customer")
    end

    it "redirects with alert when no ids provided" do
      post combine_bills_orders_path, params: { ids: [] }
      expect(response).to redirect_to(orders_path)
    end
  end
end
