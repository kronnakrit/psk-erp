require "rails_helper"

RSpec.describe "Invoices show heading tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_invoices add_invoices change_invoices delete_invoices
    ])
  end
  let(:user) { create(:user) }
  let!(:invoice) { create(:invoice) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "GET /invoices/:id" do
    before { get invoice_path(invoice) }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders page-heading on h1" do
      expect(response.body).to include("page-heading")
    end

    it "renders back-link" do
      expect(response.body).to include("back-link")
    end

    it "renders ← Back text" do
      expect(response.body).to include("\u2190 Back")
    end

    it "renders section-heading for sub-sections" do
      expect(response.body).to include("section-heading")
    end
  end
end
