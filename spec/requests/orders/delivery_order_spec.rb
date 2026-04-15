# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /orders/:id/delivery_order", type: :request do
  let(:role_with_permission)    { create(:role, permissions: %w[view_orders]) }
  let(:role_without_permission) { create(:role, permissions: []) }
  let(:user)                    { create(:user) }
  let!(:order)                  { create(:order, internal_note: "SECRET NOTE") }

  # AC-01 — authenticated user with view_orders → HTTP 200
  context "when authenticated with view_orders permission" do
    before do
      user.profile.update!(role: role_with_permission)
      sign_in user
    end

    it "returns HTTP 200" do
      get delivery_order_order_path(order)
      expect(response).to have_http_status(:ok)
    end

    it "renders using the print layout (no nav, no aside)" do
      get delivery_order_order_path(order)
      expect(response.body).not_to include("<nav")
      expect(response.body).not_to include("<aside")
    end

    it "contains บิลขนส่ง heading" do
      get delivery_order_order_path(order)
      expect(response.body).to include("บิลขนส่ง")
    end

    it "contains the order number" do
      get delivery_order_order_path(order)
      expect(response.body).to include(order.order_number)
    end

    it "does NOT contain the internal_note" do
      get delivery_order_order_path(order)
      expect(response.body).not_to include("SECRET NOTE")
    end

    it "contains ลงชื่อ signature text" do
      get delivery_order_order_path(order)
      expect(response.body).to include("ลงชื่อ")
    end

    it "contains รายละเอียด column header" do
      get delivery_order_order_path(order)
      expect(response.body).to include("รายละเอียด")
    end
  end

  # AC-02 — unauthenticated → 302 redirect to login
  context "when unauthenticated" do
    it "redirects to the login page" do
      get delivery_order_order_path(order)
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # AC-03 — authenticated without view_orders → redirected (HTML format redirects via user_not_authorized)
  context "when authenticated without view_orders permission" do
    before do
      user.profile.update!(role: role_without_permission)
      sign_in user
    end

    it "redirects (user_not_authorized HTML handler)" do
      get delivery_order_order_path(order)
      expect(response).to have_http_status(:found)
    end
  end

  # AC-04 — non-existent order → 404
  context "when the order does not exist" do
    before do
      user.profile.update!(role: role_with_permission)
      sign_in user
    end

    it "returns HTTP 404 Not Found" do
      get delivery_order_order_path(id: 999_999_999)
      expect(response).to have_http_status(:not_found)
    end
  end
end
