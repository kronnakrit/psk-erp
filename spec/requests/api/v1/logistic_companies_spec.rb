# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Logistic Companies", type: :request do
  let(:admin_role) { create(:role, :admin) }
  let(:admin_user) { create(:user).tap { |u| u.profile.update!(role: admin_role) } }
  let(:headers) do
    post "/api/v1/auth/sign_in",
         params: { user: { username: admin_user.username, password: "Password1!" } },
         as: :json
    { "Authorization" => response.headers["Authorization"] }
  end
  let(:lc) { create(:logistic_company) }

  describe "GET /api/v1/logistic_companies" do
    it "returns list" do
      lc
      get "/api/v1/logistic_companies", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/logistic_companies/:id" do
    it "returns a single logistic company" do
      get "/api/v1/logistic_companies/#{lc.id}", headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/logistic_companies" do
    it "creates one" do
      post "/api/v1/logistic_companies",
           params: { logistic_company: { name: "NewLogistic" } },
           headers: headers, as: :json
      expect(response).to have_http_status(:created)
    end

    it "returns 422 on blank name" do
      post "/api/v1/logistic_companies",
           params: { logistic_company: { name: "" } },
           headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/logistic_companies/:id" do
    it "updates" do
      patch "/api/v1/logistic_companies/#{lc.id}",
            params: { logistic_company: { name: "Updated LC" } },
            headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "DELETE /api/v1/logistic_companies/:id" do
    it "destroys" do
      delete "/api/v1/logistic_companies/#{lc.id}", headers: headers, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "POST /api/v1/logistic_companies/filter" do
    it "filters by name" do
      lc
      post "/api/v1/logistic_companies/filter",
           params: { search_text: lc.name },
           headers: headers, as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
