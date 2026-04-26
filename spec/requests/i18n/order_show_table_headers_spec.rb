require "rails_helper"

RSpec.describe "Orders show page table header i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_orders view_all_orders change_orders])
  end
  let(:user) { create(:user) }
  let!(:order) { create(:order) }

  before do
    user.profile.update!(role: role, preferred_locale: "th")
    sign_in user
    get order_path(order)
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders สินค้า as Product column header" do
    expect(response.body).to include("สินค้า")
  end

  it "renders รายละเอียด as Description column header" do
    expect(response.body).to include("รายละเอียด")
  end

  it "renders หน่วย as Unit column header" do
    expect(response.body).to include("หน่วย")
  end

  it "renders จำนวน as Qty column header" do
    expect(response.body).to include("จำนวน")
  end

  it "renders ราคาต่อหน่วย as Unit Price column header" do
    expect(response.body).to include("ราคาต่อหน่วย")
  end

  it "renders ส่วนลด as Discount column header" do
    expect(response.body).to include("ส่วนลด")
  end

  it "renders รวมบรรทัด as Line Total column header" do
    expect(response.body).to include("รวมบรรทัด")
  end
end
