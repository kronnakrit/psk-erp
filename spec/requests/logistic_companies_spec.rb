require "rails_helper"

RSpec.describe "LogisticCompanies", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_logistic_companies add_logistic_companies change_logistic_companies delete_logistic_companies
           ])
  end
  let(:user) { create(:user) }
  let!(:logistic_company) { create(:logistic_company, name: "Fast Delivery") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /logistic_companies" do
    it "returns 200" do
      get logistic_companies_path
      expect(response).to have_http_status(:ok)
    end

    it "lists logistic companies" do
      get logistic_companies_path
      expect(response.body).to include("Fast Delivery")
    end
  end

  describe "GET /logistic_companies/new" do
    it "returns 200" do
      get new_logistic_company_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /logistic_companies" do
    let(:valid_attrs) { { name: "New Courier", telephone: "021234567", address: "Bangkok", remark: "" } }

    it "creates and redirects" do
      expect do
        post logistic_companies_path, params: { logistic_company: valid_attrs }
      end.to change(LogisticCompany, :count).by(1)
      expect(response).to redirect_to(logistic_companies_path)
    end

    it "renders new on invalid data" do
      post logistic_companies_path, params: { logistic_company: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /logistic_companies/:id" do
    it "updates and redirects" do
      patch logistic_company_path(logistic_company), params: { logistic_company: { name: "Speedy Delivery" } }
      expect(response).to redirect_to(logistic_companies_path)
      expect(logistic_company.reload.name).to eq("Speedy Delivery")
    end
  end

  describe "DELETE /logistic_companies/:id" do
    it "destroys and redirects" do
      expect do
        delete logistic_company_path(logistic_company)
      end.to change(LogisticCompany, :count).by(-1)
      expect(response).to redirect_to(logistic_companies_path)
    end
  end

  describe "POST /api/v1/logistic_companies/filter" do
    it "filters by name case-insensitively" do
      post filter_api_v1_logistic_companies_path,
           params: { search_text: "fast" }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["logistic_companies"].pluck("name")).to include("Fast Delivery")
    end

    it "returns empty for no match" do
      post filter_api_v1_logistic_companies_path,
           params: { search_text: "zzz_no_match" }.to_json,
           headers: { "Content-Type" => "application/json", "Accept" => "application/json" }
      json = response.parsed_body
      expect(json["logistic_companies"]).to be_empty
    end
  end

  describe "GET /logistic_companies/:id" do
    it "returns 200" do
      get logistic_company_path(logistic_company)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /logistic_companies/:id/edit" do
    it "returns 200" do
      get edit_logistic_company_path(logistic_company)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /logistic_companies/:id with invalid data" do
    it "renders edit with unprocessable_content" do
      patch logistic_company_path(logistic_company), params: { logistic_company: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
