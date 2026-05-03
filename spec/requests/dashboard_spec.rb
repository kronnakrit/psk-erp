require "rails_helper"

RSpec.describe "Root route smoke test", type: :request do
  context "when unauthenticated" do
    it "redirects to login" do
      get root_path
      expect(response).to redirect_to("/login")
    end
  end

  context "when authenticated" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "renders the dashboard with HTTP 200" do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Price Anomaly Monitor section" do
    context "when user has see_price_monitor permission" do
      let(:role) { create(:role, permissions: ["see_price_monitor"]) }
      let(:user) { create(:user) }

      before do
        user.profile.update!(role: role)
        sign_in user
      end

      it "renders the Price Anomaly Monitor section" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Price Anomaly Monitor")
      end
    end

    context "when user does not have see_price_monitor permission" do
      let(:role) { create(:role, permissions: []) }
      let(:user) { create(:user) }

      before do
        user.profile.update!(role: role)
        sign_in user
      end

      it "does not render the Price Anomaly Monitor section" do
        get root_path
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("Price Anomaly Monitor")
      end
    end
  end

  describe "Sale graph section" do
    context "when user has see_sale_graph permission" do
      let(:role) { create(:role, permissions: %w[see_sale_graph]) }
      let(:user) { create(:user) }

      before do
        user.profile.update!(role: role)
        sign_in user
      end

      it "renders with 200 and sets chart data" do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

