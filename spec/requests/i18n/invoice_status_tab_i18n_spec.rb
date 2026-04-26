# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Invoice status filter tab i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_invoices view_all_invoices])
  end
  let(:user) { create(:user) }

  describe "TH user visiting GET /invoices" do
    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get invoices_path
    end

    it "renders ร่าง as Draft filter tab label" do
      expect(response.body).to include("ร่าง")
    end

    it "renders ชำระแล้ว as Paid filter tab label" do
      expect(response.body).to include("ชำระแล้ว")
    end

    it "renders ยกเลิก as Cancelled filter tab label" do
      expect(response.body).to include("ยกเลิก")
    end
  end

  describe "EN user visiting GET /invoices" do
    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get invoices_path
    end

    it "renders Draft as filter tab label" do
      expect(response.body).to include("Draft")
    end

    it "renders Paid as filter tab label" do
      expect(response.body).to include("Paid")
    end

    it "renders Cancelled as filter tab label" do
      expect(response.body).to include("Cancelled")
    end
  end
end
