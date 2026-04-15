require "rails_helper"

RSpec.describe "Countries", type: :request do
  let!(:thailand) { create(:country_th) }

  describe "GET /countries (public)" do
    it "returns 200 without authentication" do
      get countries_path
      expect(response).to have_http_status(:ok)
    end

    it "lists countries" do
      get countries_path
      expect(response.body).to include("Thailand")
    end
  end

  describe "GET /api/v1/countries (public API)" do
    it "returns 200 without authentication" do
      get api_v1_countries_path, as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "authenticated CRUD" do
    let(:admin_role) { create(:role, permissions: %w[view_countries add_countries change_countries delete_countries]) }
    let(:user) { create(:user) }

    before do
      user.profile.update!(role: admin_role)
      sign_in user
    end

    describe "GET /countries/new" do
      it "returns 200" do
        get new_country_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /countries" do
      let(:valid_attrs) do
        { iso_3166_1_a2: "JP", iso_3166_1_a3: "JPN", iso_3166_1_numeric: "392",
          printable_name: "Japan", name: "JAPAN" }
      end

      it "creates a country and redirects" do
        expect do
          post countries_path, params: { country: valid_attrs }
        end.to change(Country, :count).by(1)
        expect(response).to redirect_to(countries_path)
      end

      it "renders new on invalid data" do
        post countries_path, params: { country: { iso_3166_1_a2: "", printable_name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /countries/:id" do
      it "updates and redirects" do
        patch country_path(thailand), params: { country: { printable_name: "Kingdom of Thailand" } }
        expect(response).to redirect_to(countries_path)
        expect(thailand.reload.printable_name).to eq("Kingdom of Thailand")
      end
    end

    describe "DELETE /countries/:id" do
      it "destroys and redirects" do
        expect do
          delete country_path(thailand)
        end.to change(Country, :count).by(-1)
        expect(response).to redirect_to(countries_path)
      end
    end
  end

  describe "unauthenticated write access" do
    it "redirects create to login" do
      post countries_path, params: { country: { iso_3166_1_a2: "JP", printable_name: "Japan" } }
      expect(response).to redirect_to("/login")
    end
  end
end
