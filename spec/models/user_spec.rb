require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_one(:profile).dependent(:destroy) }
  end

  describe "validations" do
    subject(:user) { build(:user) }

    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "#active_for_authentication?" do
    it "returns true for an active user" do
      user = build(:user, is_active: true)
      expect(user.active_for_authentication?).to be true
    end

    it "returns false for an inactive user" do
      user = build(:user, :inactive)
      expect(user.active_for_authentication?).to be false
    end
  end

  describe "#inactive_message" do
    it "returns :account_inactive when user is deactivated" do
      user = build(:user, :inactive)
      expect(user.inactive_message).to eq(:account_inactive)
    end
  end

  describe "after_create callback" do
    it "auto-creates a blank profile for a new user" do
      user = create(:user)
      expect(user.profile).to be_a(Profile)
    end
  end
end
