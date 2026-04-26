require "rails_helper"

RSpec.describe "Invoices index design tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_invoices add_invoices change_invoices delete_invoices
    ])
  end
  let(:user) { create(:user) }
  let!(:invoice) { create(:invoice) }

  before do
    user.profile.update!(role: role, preferred_locale: "en")
    sign_in user
  end

  describe "GET /invoices" do
    before { get invoices_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders btn-primary on New Invoice button" do
      expect(response.body).to include("btn-primary")
    end

    it "uses New Invoice label (not Create Invoice)" do
      expect(response.body).to include("New Invoice")
      expect(response.body).not_to include("Create Invoice")
    end

    it "renders row-action-primary on View links" do
      expect(response.body).to include("row-action-primary")
    end

    it "renders row-action-muted on Print links" do
      expect(response.body).to include("row-action-muted")
    end
  end
end
