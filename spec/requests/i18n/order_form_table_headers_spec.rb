require "rails_helper"

RSpec.describe "Orders form order lines table header i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders add_orders change_orders view_all_orders])
  end
  let(:user) { create(:user) }

  before do
    user.profile.update!(role: role, preferred_locale: "th")
    sign_in user
    get new_order_path
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders สินค้า as Product column header in the order lines table" do
    expect(response.body).to include("สินค้า")
  end

  it "renders รายละเอียด as Description column header in the order lines table" do
    expect(response.body).to include("รายละเอียด")
  end
end
