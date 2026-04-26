# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customer status badge i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_customers add_customers change_customers])
  end
  let(:user) { create(:user) }
  let!(:customer) { create(:customer) }

  describe "TH user visiting GET /customers with an active customer" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get customers_path
    end

    it "renders ใช้งาน as active customer status badge" do
      expect(response.body).to include("ใช้งาน")
    end
  end

  describe "EN user visiting GET /customers with an active customer" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get customers_path
    end

    it "renders Active as customer status badge label" do
      expect(response.body).to include("Active")
    end
  end
end
