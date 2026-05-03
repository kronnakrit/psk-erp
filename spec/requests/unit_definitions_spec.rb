# frozen_string_literal: true

require "rails_helper"

RSpec.describe "UnitDefinitions", type: :request do
  let(:admin_role) { create(:role, permissions: %w[manage_unit_groups]) }
  let(:user) { create(:user) }
  let(:group) { create(:unit_group, name: "Standard", is_default: false) }
  let!(:base_def) { create(:unit_definition, unit_group: group, name: "pcs", ratio: 1) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "POST /unit_groups/:unit_group_id/unit_definitions" do
    context "with valid params (AC-04, AC-05)" do
      let(:valid_params) { { unit_definition: { name: "dozen", ratio: 12 } } }

      it "creates definition and returns turbo stream" do
        expect do
          post unit_group_unit_definitions_path(group), params: valid_params, as: :turbo_stream
        end.to change(UnitDefinition, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("dozen")
        expect(response.body).to include("unit_definitions_list")
      end
    end

    context "with invalid params" do
      let(:invalid_params) { { unit_definition: { name: "", ratio: -1 } } }

      it "returns unprocessable_content and renders errors" do
        expect do
          post unit_group_unit_definitions_path(group), params: invalid_params, as: :turbo_stream
        end.not_to change(UnitDefinition, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("can&#39;t be blank")
      end
    end
  end

  describe "DELETE /unit_groups/:unit_group_id/unit_definitions/:id" do
    let!(:target_def) { create(:unit_definition, unit_group: group, name: "pack", ratio: 5) }

    it "deletes the definition and returns turbo stream" do
      expect do
        delete unit_group_unit_definition_path(group, target_def), as: :turbo_stream
      end.to change(UnitDefinition, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include(%Q(turbo-stream action="remove"))
    end

    context "Edge Case: deleting the last base unit from the default group" do
      let!(:default_group) { create(:unit_group, :with_base_unit, name: "Global", is_default: true) }
      let!(:default_base) { default_group.unit_definitions.find_by(ratio: 1) }

      it "blocks deletion and returns 422" do
        expect do
          delete unit_group_unit_definition_path(default_group, default_base), as: :turbo_stream
        end.not_to change(UnitDefinition, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Cannot remove the base unit from the default group")
      end
    end
  end

  describe "POST /unit_groups/:unit_group_id/unit_definitions/:id/set_main" do
    let!(:target_def) { create(:unit_definition, unit_group: group, name: "pack", ratio: 5) }

    it "sets the definition as main (turbo stream)" do
      patch set_main_unit_group_unit_definition_path(group, target_def), as: :turbo_stream
      expect(response).to have_http_status(:ok)
      expect(target_def.reload.is_main).to be true
    end

    it "sets the definition as main (html fallback)" do
      patch set_main_unit_group_unit_definition_path(group, target_def)
      expect(response).to redirect_to(unit_group_path(group))
    end
  end

  describe "HTML fallback paths" do
    it "creates unit definition via HTML" do
      post unit_group_unit_definitions_path(group),
           params: { unit_definition: { name: "box", ratio: 12 } }
      expect(response).to redirect_to(unit_group_path(group))
    end

    it "destroys unit definition via HTML" do
      ud = create(:unit_definition, unit_group: group, name: "bag", ratio: 50)
      delete unit_group_unit_definition_path(group, ud)
      expect(response).to redirect_to(unit_group_path(group))
    end
  end

  describe "POST /unit_groups/:id/unit_definitions/:ud_id/set_main rescue StatementInvalid" do
    let!(:target_def) { create(:unit_definition, unit_group: group, name: "pack", ratio: 5) }

    it "returns 422 turbo_stream on StatementInvalid" do
      allow(UnitDefinition).to receive(:where).and_call_original
      allow(UnitDefinition).to receive(:where).with(unit_group_id: group.id).and_wrap_original do |m, *args|
        relation = m.call(*args)
        allow(relation).to receive(:update_all).and_raise(ActiveRecord::StatementInvalid, "DB error")
        relation
      end

      patch set_main_unit_group_unit_definition_path(group, target_def), as: :turbo_stream
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
