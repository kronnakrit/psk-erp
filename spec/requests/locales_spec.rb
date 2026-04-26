require "rails_helper"

RSpec.describe "LocalesController", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "PATCH /locale with valid locale 'en'" do
    it "updates profile preferred_locale to 'en' and redirects" do
      patch locale_path, params: { locale: "en" }
      expect(response).to have_http_status(:redirect)
      expect(user.profile.reload.preferred_locale).to eq("en")
    end
  end

  describe "PATCH /locale with valid locale 'th'" do
    before { user.profile.update!(preferred_locale: "en") }

    it "updates profile preferred_locale back to 'th'" do
      patch locale_path, params: { locale: "th" }
      expect(user.profile.reload.preferred_locale).to eq("th")
    end
  end

  describe "PATCH /locale with invalid locale 'fr'" do
    it "responds with 422 and does NOT update profile" do
      original_locale = user.profile.preferred_locale
      patch locale_path, params: { locale: "fr" }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.profile.reload.preferred_locale).to eq(original_locale)
    end
  end

  describe "PATCH /locale unauthenticated" do
    before { sign_out user }

    it "redirects to login" do
      patch locale_path, params: { locale: "en" }
      expect(response).to have_http_status(:redirect)
    end
  end
end
