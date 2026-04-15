# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfilePolicy, type: :policy do
  subject(:policy) { described_class.new(user, profile) }

  let(:user)    { create(:user) }
  let(:profile) { user.profile }

  context "when user owns the profile" do
    it { is_expected.to be_show }
    it { is_expected.to be_update }
  end

  context "when user does not own the profile" do
    subject(:policy) { described_class.new(other_user, profile) }

    let(:other_user) { create(:user) }

    it { is_expected.not_to be_show }
    it { is_expected.not_to be_update }
  end
end
