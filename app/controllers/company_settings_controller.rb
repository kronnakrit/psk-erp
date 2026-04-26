# frozen_string_literal: true

class CompanySettingsController < ApplicationController
  before_action :authenticate_user!
  skip_after_action :verify_policy_scoped

  # GET /company_setting/edit
  def edit
    @company_setting = CompanySetting.current!
    authorize @company_setting
  end

  # PATCH /company_setting
  def update
    @company_setting = CompanySetting.current!
    authorize @company_setting

    if params[:company_setting][:remove_logo] == "1"
      @company_setting.logo.purge_later
    elsif params.dig(:company_setting, :logo).present?
      @company_setting.logo.attach(params[:company_setting][:logo])
    end

    if @company_setting.update(company_setting_params)
      redirect_to edit_company_setting_path, notice: "Company settings saved"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def company_setting_params
    params.expect(
      company_setting: %i[company_name company_address company_telephone
                          company_tax_id company_email company_website]
    )
  end
end
