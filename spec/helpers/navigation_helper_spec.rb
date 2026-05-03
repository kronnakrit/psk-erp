# frozen_string_literal: true

require "rails_helper"

RSpec.describe NavigationHelper, type: :helper do
  describe "#active_nav_classes" do
    it "returns active classes when on the current page" do
      allow(helper).to receive(:current_page?).and_return(true)
      expect(helper.active_nav_classes("/orders")).to include("blue")
    end

    it "returns inactive classes when not on the current page" do
      allow(helper).to receive(:current_page?).and_return(false)
      expect(helper.active_nav_classes("/orders")).to include("gray")
    end
  end
end
