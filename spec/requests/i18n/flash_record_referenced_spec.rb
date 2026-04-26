require "rails_helper"

RSpec.describe "Flash record_referenced i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_roles delete_roles change_roles add_roles])
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
    end

    it "flash message keys exist in English locale" do
      I18n.with_locale(:en) do
        expect(I18n.t("flash.record_referenced")).to include("Cannot delete")
      end
    end
  end

  describe "Thai user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
    end

    it "flash message keys exist in Thai locale" do
      I18n.with_locale(:th) do
        expect(I18n.t("flash.record_referenced")).to include("ลบ")
      end
    end
  end
end
