# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Orders form order line product/description placeholder i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders add_orders view_all_orders])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /orders/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_order_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Thai order line product search placeholder" do
      expect(response.body).to include("ค้นหา SKU หรือชื่อสินค้า")
    end

    it "renders Thai order line description placeholder" do
      expect(response.body).to include("รายละเอียดสินค้า")
    end
  end
end
