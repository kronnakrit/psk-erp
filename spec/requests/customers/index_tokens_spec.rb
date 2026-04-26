require "rails_helper"

RSpec.describe "Customers index design tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_customers add_customers change_customers delete_customers
    ])
  end
  let(:user) { create(:user) }
  let!(:customer) { create(:customer, first_name: "Alice", last_name: "Smith") }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  describe "GET /customers" do
    before { get customers_path }

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders btn-primary on New Customer button" do
      expect(response.body).to include("btn-primary")
    end

    it "renders row-action-primary on Edit link" do
      expect(response.body).to include("row-action-primary")
    end

    it "renders row-action-danger on Delete button" do
      expect(response.body).to include("row-action-danger")
    end
  end
end
