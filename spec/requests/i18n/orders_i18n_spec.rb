require "rails_helper"

RSpec.describe "Orders i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders add_orders change_orders delete_orders view_all_orders
    ])
  end

  describe "Thai user" do
    let(:user) { create(:user) }
    let!(:order) { create(:order) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get orders_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ออเดอร์ as page title" do
      expect(response.body).to include("ออเดอร์")
    end

    it "renders Thai New Order CTA button" do
      expect(response.body).to include("สร้างออเดอร์")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }
    let!(:order) { create(:order) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get orders_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders Orders as page title" do
      expect(response.body).to include("Orders")
    end

    it "renders New Order CTA button" do
      expect(response.body).to include("New Order")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
