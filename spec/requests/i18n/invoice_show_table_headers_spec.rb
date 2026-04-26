require "rails_helper"

RSpec.describe "Invoices show page nested table header i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_invoices add_invoices change_invoices])
  end
  let(:user) { create(:user) }
  let!(:invoice) { create(:invoice) }
  let!(:order) { create(:order) }
  let!(:invoice_order) { create(:invoice_order, invoice: invoice, order: order) }

  before do
    user.profile.update!(role: role, preferred_locale: "th")
    sign_in user
    get invoice_path(invoice)
  end

  it "returns 200" do
    expect(response).to have_http_status(:ok)
  end

  it "renders เลขที่ as Order # column header" do
    expect(response.body).to include("เลขที่")
  end

  it "renders ยอดรวมสุทธิ as Grand Total column header" do
    expect(response.body).to include("ยอดรวมสุทธิ")
  end

  it "renders ส่วนลด as Discount column header" do
    expect(response.body).to include("ส่วนลด")
  end

  it "renders รวมบรรทัด as Line Total column header" do
    expect(response.body).to include("รวมบรรทัด")
  end
end
