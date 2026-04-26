require "rails_helper"

RSpec.describe "No missing translations on index pages (all locales)", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders view_all_orders view_invoices view_products view_customers
      view_purchase_orders view_users view_product_stocks
    ])
  end
  let(:user) { create(:user) }

  %w[en th].each do |locale|
    describe "#{locale.upcase} user" do
      before do
        user.profile.update!(role: role, preferred_locale: locale)
        sign_in user
      end

      [
        [:orders_path, "orders"],
        [:invoices_path, "invoices"],
        [:products_path, "products"],
        [:customers_path, "customers"],
        [:purchase_orders_path, "purchase_orders"],
        [:users_path, "users"]
      ].each do |path_helper, name|
        describe "GET /#{name}" do
          before { get send(path_helper) }

          it "returns 200" do
            expect(response).to have_http_status(:ok)
          end

          it "does not include [missing \"#{locale} marker" do
            expect(response.body).not_to include("[missing \"#{locale}")
          end
        end
      end
    end
  end
end
