require "rails_helper"

RSpec.describe "Customers", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_customers add_customers change_customers delete_customers
           ])
  end
  let(:user) { create(:user) }
  let!(:customer) { create(:customer, first_name: "Alice", last_name: "Smith") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /customers" do
    it "returns 200" do
      get customers_path
      expect(response).to have_http_status(:ok)
    end

    it "lists active customers" do
      get customers_path
      expect(response.body).to include("Alice")
    end

    it "does not list soft-deleted customers" do
      customer.soft_delete!
      get customers_path
      expect(response.body).not_to include("Alice")
    end
  end

  describe "GET /customers/new" do
    it "returns 200" do
      get new_customer_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /customers" do
    let(:valid_attrs) { { first_name: "Bob", last_name: "Jones", telephone: "0811111111" } }

    it "creates customer and redirects" do
      expect do
        post customers_path, params: { customer: valid_attrs }
      end.to change(Customer, :count).by(1)
      expect(response).to redirect_to(customers_path)
    end

    it "renders new on invalid data" do
      post customers_path, params: { customer: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /customers/:id" do
    it "updates and redirects" do
      patch customer_path(customer), params: { customer: { last_name: "Updated" } }
      expect(response).to redirect_to(customers_path)
      expect(customer.reload.last_name).to eq("Updated")
    end
  end

  describe "GET /customers/:id" do
    it "returns 200" do
      get customer_path(customer)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /customers/:id/edit" do
    it "returns 200" do
      get edit_customer_path(customer)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /customers/:id with invalid data" do
    it "renders edit with unprocessable_content" do
      patch customer_path(customer), params: { customer: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /customers/:id (soft delete)" do
    it "soft-deletes (sets deleted_at) and redirects" do
      delete customer_path(customer)
      expect(response).to redirect_to(customers_path)
      expect(Customer.with_deleted.find(customer.id).soft_deleted?).to be true
      expect(Customer.count).to eq(0)
    end
  end

  describe "POST /api/v1/customers/filter" do
    it "filters by first or last name" do
      post filter_api_v1_customers_path,
           params: { search_text: "alice" }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["customers"].pluck("first_name")).to include("Alice")
    end

    it "does not return soft-deleted customers" do
      customer.soft_delete!
      post filter_api_v1_customers_path,
           params: { search_text: "alice" }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      json = response.parsed_body
      expect(json["customers"]).to be_empty
    end
  end
end
