# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationMailer do
  it "inherits from ActionMailer::Base" do
    expect(described_class.superclass).to eq(ActionMailer::Base)
  end

  it "uses mailer layout" do
    expect(described_class._layout).to eq("mailer")
  end
end
