# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Customers", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:headers) do
    post "/api/v1/auth/sign_in",
         params: { user: { username: admin_user.username, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end
  let(:customer) { create(:customer) }

  describe "GET /api/v1/customers" do
    it "returns customer list" do
      customer
      get "/api/v1/customers", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["customers"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/customers/:id" do
    it "returns a single customer" do
      get "/api/v1/customers/#{customer.id}", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(customer.id)
    end
  end

  describe "POST /api/v1/customers" do
    it "creates a customer" do
      post "/api/v1/customers",
           params: { customer: { first_name: "APITest", last_name: "Customer" } },
           headers: headers, as: :json
      expect(response).to have_http_status(:created)
    end

    it "returns 422 for invalid data" do
      post "/api/v1/customers",
           params: { customer: { first_name: "" } },
           headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/customers/:id" do
    it "updates a customer" do
      patch "/api/v1/customers/#{customer.id}",
            params: { customer: { first_name: "Updated" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/customers/:id" do
    it "soft deletes a customer" do
      delete "/api/v1/customers/#{customer.id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "POST /api/v1/customers/filter" do
    it "filters customers by name" do
      customer
      post "/api/v1/customers/filter",
           params: { search_text: customer.first_name },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/customers/search" do
    let!(:matching_customer) { create(:customer, first_name: "Searchable", last_name: "Person", telephone: "0812345678") }

    it "returns matching customers as JSON array" do
      get "/api/v1/customers/search", params: { q: "Searchable" }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json).to be_an(Array)
      expect(json.first).to include("id", "full_name", "telephone")
    end

    it "returns empty array when no match" do
      get "/api/v1/customers/search", params: { q: "zzz_no_match" }, headers: headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(json).to eq([])
    end
  end
end
