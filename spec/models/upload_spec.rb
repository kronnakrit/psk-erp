# frozen_string_literal: true

require "rails_helper"

RSpec.describe Upload, type: :model do
  let(:user) { create(:user) }

  def build_upload_with_file(status: "pending")
    upload = Upload.new(user: user, status: status)
    upload.file.attach(
      io: StringIO.new("test"),
      filename: "test.xlsx",
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    upload
  end

  describe "validations" do
    it "is valid with a file and valid status" do
      expect(build_upload_with_file).to be_valid
    end

    it "is invalid without a file" do
      expect(described_class.new(user: user, status: "pending")).not_to be_valid
    end

    it "is invalid with an unknown status" do
      upload = build_upload_with_file(status: "unknown")
      expect(upload).not_to be_valid
    end
  end

  describe "status predicates" do
    it "returns pending? correctly" do
      expect(build_upload_with_file(status: "pending").pending?).to be true
    end

    it "returns processing? correctly" do
      expect(build_upload_with_file(status: "processing").processing?).to be true
    end

    it "returns completed? correctly" do
      expect(build_upload_with_file(status: "completed").completed?).to be true
    end

    it "returns failed? correctly" do
      expect(build_upload_with_file(status: "failed").failed?).to be true
    end
  end
end
