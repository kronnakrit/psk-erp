# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Branches", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[view_branches add_branches change_branches delete_branches])
  end
  let(:user) { create(:user) }
  let!(:branch) { create(:branch, name: "Main Branch") }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /branches" do
    it "returns 200" do
      get branches_path
      expect(response).to have_http_status(:ok)
    end

    it "lists branches" do
      get branches_path
      expect(response.body).to include("Main Branch")
    end
  end

  describe "GET /branches/new" do
    it "returns 200" do
      get new_branch_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /branches" do
    it "creates and redirects" do
      expect do
        post branches_path, params: { branch: { name: "Warehouse A" } }
      end.to change(Branch, :count).by(1)
      expect(response).to redirect_to(branches_path)
    end

    it "renders new on invalid data" do
      post branches_path, params: { branch: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /branches/:id" do
    it "updates and redirects" do
      patch branch_path(branch), params: { branch: { name: "Updated Branch" } }
      expect(response).to redirect_to(branches_path)
      expect(branch.reload.name).to eq("Updated Branch")
    end
  end

  describe "DELETE /branches/:id" do
    it "deletes and redirects" do
      expect do
        delete branch_path(branch)
      end.to change(Branch, :count).by(-1)
      expect(response).to redirect_to(branches_path)
    end
  end
end
