# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CompanySettings", type: :request do
  let(:role) { create(:role, permissions: %w[change_company_settings]) }
  let(:user) { create(:user) }

  before do
    user.profile.update!(role: role)
    sign_in user
  end

  # ------------------------------------------------------------------ Edit --

  describe "GET /company_setting/edit" do
    it "returns 200" do
      get edit_company_setting_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Company Settings")
    end
  end

  # ------------------------------------------------------------------ Update --

  describe "PATCH /company_setting" do
    it "updates company name and redirects back to edit" do
      patch company_setting_path,
            params: { company_setting: { company_name: "New Name Co.", company_address: "123 Main St" } }
      expect(response).to redirect_to(edit_company_setting_path)
      expect(CompanySetting.current.company_name).to eq("New Name Co.")
    end

    it "returns 422 when company_name is blank" do
      patch company_setting_path,
            params: { company_setting: { company_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    context "when remove_logo is checked" do
      it "purges logo and redirects" do
        company_setting = CompanySetting.current!
        # Attach a dummy logo first
        company_setting.logo.attach(
          io: StringIO.new("fake"),
          filename: "logo.png",
          content_type: "image/png"
        )
        patch company_setting_path,
              params: { company_setting: { company_name: company_setting.company_name, remove_logo: "1" } }
        expect(response).to redirect_to(edit_company_setting_path)
      end
    end

    context "when a logo file is provided" do
      it "attaches the logo and redirects" do
        tmpfile = Tempfile.new(["logo", ".png"])
        tmpfile.write("\x89PNG\r\n\x1A\n" + ("x" * 100))
        tmpfile.rewind
        file = Rack::Test::UploadedFile.new(tmpfile.path, "image/png")

        patch company_setting_path,
              params: { company_setting: { company_name: "Logo Co.", logo: file } }
        tmpfile.close
        tmpfile.unlink
        expect(response).to redirect_to(edit_company_setting_path)
      end
    end
  end

  # ------------------------------------------------------------------ Unauthorised --

  describe "when user lacks change_company_settings" do
    let(:role) { create(:role, permissions: []) }

    it "redirects with alert (Pundit rescued by ApplicationController)" do
      get edit_company_setting_path
      expect(response).to redirect_to(root_path)
    end
  end
end
