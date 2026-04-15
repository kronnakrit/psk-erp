require "rails_helper"

RSpec.describe Role, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:profiles).dependent(:nullify) }
  end

  describe "validations" do
    subject(:role) { build(:role) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end

  describe "permissions column" do
    it "defaults to an empty array" do
      role = create(:role)
      expect(role.permissions).to eq([])
    end

    it "stores an array of codenames" do
      role = create(:role, permissions: %w[view_users add_users])
      expect(role.reload.permissions).to contain_exactly("view_users", "add_users")
    end
  end
end
