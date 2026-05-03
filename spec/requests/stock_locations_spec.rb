# frozen_string_literal: true

require "rails_helper"

RSpec.describe "StockLocations", type: :request do
  let(:role) do
    create(:role, permissions: %w[view_product_stocks change_product_stocks])
  end
  let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

  before { sign_in user }

  describe "POST /stock_locations (AC-02)" do
    it "creates a stock location and redirects" do
      expect do
        post stock_locations_path, params: { stock_location: { name: "Rack A", description: "Main warehouse rack A" } }
      end.to change(StockLocation, :count).by(1)
      expect(response).to redirect_to(stock_locations_path)
    end

    it "returns 422 on blank name (AC-03)" do
      post stock_locations_path, params: { stock_location: { name: "", description: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /stocks/:id with stock_location_ids (AC-06)" do
    let(:location_a) { create(:stock_location) }
    let(:location_b) { create(:stock_location) }
    let!(:stock) { create(:product_stock) }

    it "updates location associations" do
      patch stock_path(stock), params: { product_stock: { stock_location_ids: [location_a.id, location_b.id] } }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.stock_location_ids).to contain_exactly(location_a.id, location_b.id)
    end

    it "clears associations when empty array provided (AC-07)" do
      stock.stock_locations = [location_a]
      patch stock_path(stock), params: { product_stock: { stock_location_ids: [""] } }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.stock_locations).to be_empty
    end
  end

  # STORY-19-10 specs
  describe "PATCH /stocks/:id with stock_person_id (AC-02)" do
    let!(:stock) { create(:product_stock) }
    let(:stock_person) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it "updates stock_person_id" do
      patch stock_path(stock), params: { product_stock: { stock_person_id: stock_person.id } }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.stock_person_id).to eq(stock_person.id)
    end

    it "clears stock_person_id when blank provided" do
      stock.update!(stock_person_id: stock_person.id)
      patch stock_path(stock), params: { product_stock: { stock_person_id: "" } }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.stock_person_id).to be_nil
    end
  end

  describe "GET /stocks renders STOCK PERSON column (AC-04)" do
    let(:stock_person) { create(:user).tap { |u| u.profile.update!(role: role) } }
    let!(:stock) { create(:product_stock, stock_person: stock_person) } # rubocop:disable RSpec/LetSetup

    it "includes stock person name in response" do
      get stocks_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(stock_person.profile.full_name)
    end
  end

  describe "GET /stock_locations" do
    it "renders index" do
      get stock_locations_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /stock_locations/new" do
    it "renders new form" do
      get new_stock_location_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /stock_locations/:id/edit" do
    let(:loc) { create(:stock_location) }

    it "renders edit form" do
      get edit_stock_location_path(loc)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /stock_locations/:id" do
    let(:loc) { create(:stock_location) }

    it "updates and redirects on valid params" do
      patch stock_location_path(loc), params: { stock_location: { name: "Updated", description: "desc" } }
      expect(response).to redirect_to(stock_locations_path)
    end

    it "renders edit on blank name" do
      patch stock_location_path(loc), params: { stock_location: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /stock_locations/:id" do
    let!(:loc) { create(:stock_location) }

    it "destroys and redirects" do
      expect { delete stock_location_path(loc) }.to change(StockLocation, :count).by(-1)
      expect(response).to redirect_to(stock_locations_path)
    end
  end
end
