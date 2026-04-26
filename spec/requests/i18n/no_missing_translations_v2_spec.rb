# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Form pages have no missing translations", type: :request do
  let(:role) do
    create(:role, permissions: %w[
      view_orders add_orders view_all_orders
      view_products add_products
      view_customers add_customers
      view_purchase_orders add_purchase_orders
      view_users add_users change_users
    ])
  end
  let(:user) { create(:user) }

  shared_examples "no missing translations" do |path_helper|
    %w[th en].each do |locale|
      context "#{locale} locale" do
        before do
          user.profile.update!(role: role, preferred_locale: locale)
          sign_in user
          get send(path_helper)
        end

        it "returns 200" do
          expect(response).to have_http_status(:ok)
        end

        it "has no missing translation placeholders" do
          expect(response.body).not_to include('[missing "')
        end
      end
    end
  end

  describe "GET /orders/new" do
    include_examples "no missing translations", :new_order_path
  end

  describe "GET /products/new" do
    include_examples "no missing translations", :new_product_path
  end

  describe "GET /customers/new" do
    include_examples "no missing translations", :new_customer_path
  end

  describe "GET /purchase_orders/new" do
    include_examples "no missing translations", :new_purchase_order_path
  end

  describe "GET /users/new" do
    include_examples "no missing translations", :new_user_path
  end
end
