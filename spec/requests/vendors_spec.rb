# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Vendors", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_vendors add_vendors change_vendors delete_vendors
           ])
  end
  let(:user) { create(:user) }
  let!(:vendor) { create(:vendor, name: "Acme Corp") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /vendors" do
    it "returns 200" do
      get vendors_path
      expect(response).to have_http_status(:ok)
    end

    it "lists vendors" do
      get vendors_path
      expect(response.body).to include("Acme Corp")
    end
  end

  describe "GET /vendors/new" do
    it "returns 200" do
      get new_vendor_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /vendors" do
    let(:valid_attrs) { { name: "New Vendor Co", telephone: "021234567", address: "Bangkok", remark: "" } }

    it "creates and redirects" do
      expect do
        post vendors_path, params: { vendor: valid_attrs }
      end.to change(Vendor, :count).by(1)
      expect(response).to redirect_to(vendors_path)
    end

    it "auto-generates initial_name after create" do
      post vendors_path, params: { vendor: valid_attrs }
      created = Vendor.find_by!(name: "New Vendor Co")
      expect(created.initial_name).to eq("New Vendor Co-#{created.id}")
    end

    it "renders new on invalid data" do
      post vendors_path, params: { vendor: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /vendors/:id" do
    it "updates and redirects" do
      patch vendor_path(vendor), params: { vendor: { name: "Updated Corp" } }
      expect(response).to redirect_to(vendors_path)
      expect(vendor.reload.name).to eq("Updated Corp")
    end
  end

  describe "DELETE /vendors/:id" do
    it "deletes the vendor" do
      expect do
        delete vendor_path(vendor)
      end.to change(Vendor, :count).by(-1)
      expect(response).to redirect_to(vendors_path)
    end
  end

  describe "POST /vendors/initialize_names" do
    let!(:vendor_no_init) { create(:vendor, name: "NoInit Vendor") }

    before do
      vendor_no_init.update_column(:initial_name, nil) # rubocop:disable Rails/SkipsModelValidations
    end

    it "sets initial_name for vendors missing one" do
      post initialize_names_vendors_path
      expect(response).to redirect_to(vendors_path)
      expect(vendor_no_init.reload.initial_name).to eq("NoInit Vendor-#{vendor_no_init.id}")
    end
  end
end
