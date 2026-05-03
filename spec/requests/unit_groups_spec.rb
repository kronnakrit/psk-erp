# frozen_string_literal: true

require "rails_helper"

RSpec.describe "UnitGroups", type: :request do
  let(:admin_role) { create(:role, permissions: %w[manage_unit_groups]) }
  let(:user) { create(:user) }
  let!(:sys_default) { create(:unit_group, :with_base_unit, name: "Global Default", is_default: true) }

  before do
    user.profile.update!(role: admin_role)
  end

  describe "Authentication & Authorization (AC-10, AC-11)" do
    context "when not authenticated" do
      it "redirects to login" do
        get unit_groups_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated without manage_unit_groups permission" do
      before do
        user.profile.update!(role: create(:role, permissions: []))
        sign_in user
      end

      it "redirects to root with alert" do
        get unit_groups_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("คุณไม่มีสิทธิ์ดำเนินการนี้")
      end
    end
  end

  describe "Authenticated admin actions" do
    before { sign_in user }

    describe "GET /unit_groups (AC-01)" do
      it "returns 200 and lists unit groups" do
        get unit_groups_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Global Default")
      end
    end

    describe "GET /unit_groups/new" do
      it "returns 200" do
        get new_unit_group_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /unit_groups/:id/edit" do
      it "returns 200" do
        get edit_unit_group_path(sys_default)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /unit_groups (AC-02)" do
      it "creates a new unit group and redirects" do
        expect do
          post unit_groups_path, params: { unit_group: { name: "Standard Piece Count", is_default: false } }
        end.to change(UnitGroup, :count).by(1)

        new_group = UnitGroup.last
        expect(response).to redirect_to(unit_group_path(new_group))
        expect(flash[:notice]).to eq("Unit group created.")
      end

      it "renders new on blank name" do
        post unit_groups_path, params: { unit_group: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "PATCH /unit_groups/:id" do
      it "updates and redirects" do
        patch unit_group_path(sys_default), params: { unit_group: { name: "Updated Group" } }
        expect(response).to redirect_to(unit_group_path(sys_default))
        expect(sys_default.reload.name).to eq("Updated Group")
      end

      it "renders edit on blank name" do
        patch unit_group_path(sys_default), params: { unit_group: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "GET /unit_groups/:id (AC-03)" do
      it "returns 200 and shows the detail view" do
        get unit_group_path(sys_default)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Global Default")
        expect(response.body).to include(sys_default.unit_definitions.first.name)
      end
    end

    describe "PATCH /unit_groups/:id/set_default" do
      let(:new_group) { create(:unit_group, name: "Weights", is_default: false) }

      context "when group has a base unit (AC-06)" do
        before { create(:unit_definition, unit_group: new_group, name: "kg", ratio: 1) }

        it "updates default and redirects" do
          patch set_default_unit_group_path(new_group)
          expect(new_group.reload.is_default?).to be true
          expect(sys_default.reload.is_default?).to be false
          expect(flash[:notice]).to eq("Default unit group updated.")
        end
      end

      context "when group has no base unit (AC-07)" do
        it "fails with 422 unprocessable_content" do
          patch set_default_unit_group_path(new_group)
          expect(response).to have_http_status(:unprocessable_content)
          expect(flash[:alert]).to include("base unit")
          expect(new_group.reload.is_default?).to be false
        end
      end
    end

    describe "DELETE /unit_groups/:id" do
      let!(:deletable_group) { create(:unit_group, name: "Delete Me", is_default: false) }

      context "when NO products link to it (AC-09)" do
        it "deletes the group and redirects" do
          expect do
            delete unit_group_path(deletable_group)
          end.to change(UnitGroup, :count).by(-1)
          expect(response).to redirect_to(unit_groups_path)
          expect(flash[:notice]).to eq("Unit group deleted.")
        end
      end

      context "when products link to it (AC-08)" do
        before do
          # create product to prevent deletion
          create(:product, unit_group: deletable_group)
        end

        it "returns 409 conflict and shows flash" do
          expect do
            delete unit_group_path(deletable_group)
          end.not_to change(UnitGroup, :count)

          expect(response).to have_http_status(:conflict)
          expect(flash[:alert]).to include("assigned to products")
        end
      end
    end
  end
end
