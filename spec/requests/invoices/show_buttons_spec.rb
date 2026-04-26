require "rails_helper"

RSpec.describe "Invoices show button tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_invoices add_invoices change_invoices delete_invoices
    ])
  end
  let(:user) { create(:user) }
  let!(:invoice) { create(:invoice, status: "Dr") }

  before do
    user.profile.update!(role: role)
    sign_in user
    get invoice_path(invoice)
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders btn-secondary on Print Invoice" do
    expect(response.body).to include("btn-secondary")
  end

  it "renders btn-outline on Edit Remark" do
    expect(response.body).to include("btn-outline")
  end
end
