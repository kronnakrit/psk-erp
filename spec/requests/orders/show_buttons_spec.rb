require "rails_helper"

RSpec.describe "Orders show button tokens", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders add_orders change_orders delete_orders view_all_orders
    ])
  end
  let(:user) { create(:user) }
  let!(:order) { create(:order) }

  before do
    user.profile.update!(role: role)
    sign_in user
    get order_path(order)
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders btn-primary on Edit Order" do
    expect(response.body).to include("btn-primary")
  end

  it "renders btn-secondary on Duplicate" do
    expect(response.body).to include("btn-secondary")
  end
end
