require "rails_helper"

RSpec.describe "Purchase Orders show button tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_purchase_orders add_purchase_orders change_purchase_orders delete_purchase_orders
    ])
  end
  let(:user) { create(:user) }
  let!(:purchase_order) { create(:purchase_order, status: "Dr") }

  before do
    user.profile.update!(role: role)
    sign_in user
    get purchase_order_path(purchase_order)
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders btn-primary on Confirm PO" do
    expect(response.body).to include("btn-primary")
  end

  it "renders btn-outline on Edit" do
    expect(response.body).to include("btn-outline")
  end

  it "renders btn-danger on Delete" do
    expect(response.body).to include("btn-danger")
  end
end
