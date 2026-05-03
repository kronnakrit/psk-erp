# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#adjuster_display_name" do
    context "when adjuster is nil" do
      it "returns em dash" do
        expect(helper.adjuster_display_name(nil)).to eq("—")
      end
    end

    context "when adjuster has a profile with first and last name" do
      let(:user) { create(:user) }

      before { user.profile.update!(first_name: "Jane", last_name: "Doe") }

      it "returns full name" do
        expect(helper.adjuster_display_name(user)).to eq("Jane Doe")
      end
    end

    context "when adjuster profile has only first name" do
      let(:user) { create(:user) }

      before { user.profile.update!(first_name: "Jane", last_name: nil) }

      it "returns first name only" do
        expect(helper.adjuster_display_name(user)).to eq("Jane")
      end
    end

    context "when adjuster profile has no name" do
      let(:user) { create(:user) }

      before { user.profile.update!(first_name: nil, last_name: nil) }

      it "returns email" do
        expect(helper.adjuster_display_name(user)).to eq(user.email)
      end
    end
  end
end
