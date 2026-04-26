# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Suppliers", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[
             view_suppliers add_suppliers change_suppliers delete_suppliers
           ])
  end
  let(:user) { create(:user) }
  let!(:supplier) { create(:supplier, name: "Top Supplier") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /suppliers" do
    it "returns 200" do
      get suppliers_path
      expect(response).to have_http_status(:ok)
    end

    it "lists suppliers" do
      get suppliers_path
      expect(response.body).to include("Top Supplier")
    end
  end

  describe "GET /suppliers/new" do
    it "returns 200" do
      get new_supplier_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /suppliers" do
    let(:valid_attrs) do
      { name: "New Supplier", telephone: "021234567", address: "Bangkok", remark: "", is_active: true }
    end

    it "creates and redirects" do
      expect do
        post suppliers_path,
             params: { supplier: valid_attrs }
      end.to change(Supplier, :count).by(1)
      expect(response).to redirect_to(suppliers_path)
    end

    it "renders new on invalid data (blank name)" do
      post suppliers_path, params: { supplier: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "renders new on duplicate name" do
      post suppliers_path, params: { supplier: valid_attrs.merge(name: "Top Supplier") }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /suppliers/:id/edit" do
    it "returns 200" do
      get edit_supplier_path(supplier)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /suppliers/:id" do
    it "updates and redirects" do
      patch supplier_path(supplier), params: { supplier: { name: "Updated Supplier" } }
      expect(response).to redirect_to(suppliers_path)
      expect(supplier.reload.name).to eq("Updated Supplier")
    end

    it "renders edit on invalid data" do
      patch supplier_path(supplier), params: { supplier: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /suppliers/:id" do
    it "destroys and redirects" do
      expect do
        delete supplier_path(supplier)
      end.to change(Supplier, :count).by(-1)
      expect(response).to redirect_to(suppliers_path)
    end
  end

  describe "authorisation" do
    let(:no_perm_user) { create(:user) }

    before { sign_in no_perm_user }

    it "redirects GET /suppliers for user without permission" do
      get suppliers_path
      expect(response).to redirect_to(root_path)
    end
  end
end
