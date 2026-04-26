# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompanySetting, type: :model do
  describe "validations" do
    it "is valid with a company_name" do
      expect(build(:company_setting)).to be_valid
    end

    it "is invalid without a company_name" do
      expect(build(:company_setting, company_name: "")).to be_invalid
    end
  end

  describe ".current" do
    it "returns or initializes a CompanySetting" do
      expect(CompanySetting.current).to be_a(CompanySetting)
    end
  end

  describe ".current!" do
    it "persists and returns a CompanySetting" do
      setting = CompanySetting.current!
      expect(setting).to be_persisted
    end

    it "returns the same record on second call" do
      first  = CompanySetting.current!
      second = CompanySetting.current!
      expect(first.id).to eq(second.id)
    end
  end

  describe "logo attachment" do
    it "rejects non-image content types" do
      setting = CompanySetting.current!
      setting.logo.attach(
        io: StringIO.new("data"),
        filename: "file.pdf",
        content_type: "application/pdf"
      )
      expect(setting).not_to be_valid
      expect(setting.errors[:logo]).to be_present
    end
  end
end
