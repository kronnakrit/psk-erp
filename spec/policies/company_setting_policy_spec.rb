# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanySettingPolicy, type: :policy do
  subject(:policy) { described_class.new(user, company_setting) }

  let(:company_setting) { CompanySetting.new }

  context "when user has change_company_settings permission" do
    let(:role) { create(:role, permissions: %w[change_company_settings]) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.to be_edit }
    it { is_expected.to be_update }
  end

  context "when user lacks change_company_settings permission" do
    let(:role) { create(:role, permissions: []) }
    let(:user) { create(:user).tap { |u| u.profile.update!(role: role) } }

    it { is_expected.not_to be_edit }
    it { is_expected.not_to be_update }
  end
end
