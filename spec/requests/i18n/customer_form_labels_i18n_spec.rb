# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customers form labels i18n", type: :request do
  let(:role) { create(:role, permissions: %w[view_customers add_customers change_customers]) }
  let(:user) { create(:user) }

  describe "TH user visiting GET /customers/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get new_customer_path
    end

    it "returns 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders ชื่อ as First Name label" do
      expect(response.body).to include("ชื่อ")
    end

    it "renders เบอร์โทรศัพท์ as Telephone label" do
      expect(response.body).to include("เบอร์โทรศัพท์")
    end

    it "renders เพิ่มลูกค้า as submit button" do
      expect(response.body).to include("เพิ่มลูกค้า")
    end

    it "renders ประเทศ as Country label" do
      expect(response.body).to include("ประเทศ")
    end
  end

  describe "EN user visiting GET /customers/new" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get new_customer_path
    end

    it "renders First Name as first name label" do
      expect(response.body).to include("First Name")
    end

    it "renders Telephone as telephone label" do
      expect(response.body).to include("Telephone")
    end

    it "renders Create Customer as submit button" do
      expect(response.body).to include("Create Customer")
    end
  end
end
