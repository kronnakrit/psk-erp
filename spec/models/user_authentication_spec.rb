# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User.find_for_database_authentication", type: :model do
  let!(:user) { create(:user, username: "alice") }

  it "finds a user by exact username match" do
    result = User.find_for_database_authentication(username: "alice")
    expect(result).to eq(user)
  end

  it "finds a user case-insensitively (uppercase input)" do
    result = User.find_for_database_authentication(username: "ALICE")
    expect(result).to eq(user)
  end

  it "finds a user case-insensitively (mixed case input)" do
    result = User.find_for_database_authentication(username: "Alice")
    expect(result).to eq(user)
  end

  it "strips leading/trailing whitespace from username" do
    result = User.find_for_database_authentication(username: "  alice  ")
    expect(result).to eq(user)
  end

  it "returns nil when no user matches the username" do
    result = User.find_for_database_authentication(username: "ghost")
    expect(result).to be_nil
  end

  context "with an inactive user" do
    let!(:inactive_user) { create(:user, :inactive, username: "inactive_bob") }

    it "finds the user record (active_for_authentication? check happens separately)" do
      result = User.find_for_database_authentication(username: "inactive_bob")
      expect(result).to eq(inactive_user)
    end

    it "returns false for active_for_authentication?" do
      expect(inactive_user.active_for_authentication?).to be false
    end
  end
end
