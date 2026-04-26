require "rails_helper"

RSpec.describe "Products i18n", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_products add_products change_products delete_products])
  end

  describe "Thai user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "th")
      sign_in user
      get products_path
    end

    it "renders สินค้า as page title" do
      expect(response.body).to include("สินค้า")
    end

    it "renders Thai New Product CTA" do
      expect(response.body).to include("เพิ่มสินค้า")
    end
  end

  describe "English user" do
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: role, preferred_locale: "en")
      sign_in user
      get products_path
    end

    it "renders Products as page title" do
      expect(response.body).to include("Products")
    end

    it "does not include missing translation marker" do
      expect(response.body).not_to include('[missing "en')
    end
  end
end
