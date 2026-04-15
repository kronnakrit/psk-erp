# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderNumberGenerator do
  subject(:generator) { described_class.new(date) }

  let(:date) { Date.new(2025, 3, 15) }
  let(:scope_double) { instance_double(ActiveRecord::Relation) }

  before do
    allow(Order).to receive(:where).with(running_date: date).and_return(scope_double)
  end

  describe "#call" do
    context "when no orders exist for the date" do
      before do
        allow(scope_double).to receive(:count).and_return(0)
        allow(Order).to receive(:exists?).with(order_number: "20250315001").and_return(false)
      end

      it "returns YYYYMMDD001 format" do
        expect(generator.call).to eq("20250315001")
      end
    end

    context "when 4 orders already exist for the date" do
      before do
        allow(scope_double).to receive(:count).and_return(4)
        allow(Order).to receive(:exists?).with(order_number: "20250315005").and_return(false)
      end

      it "starts from sequence 005" do
        expect(generator.call).to eq("20250315005")
      end
    end

    context "when there is a collision on the first candidate" do
      before do
        allow(scope_double).to receive(:count).and_return(0)
        allow(Order).to receive(:exists?).with(order_number: "20250315001").and_return(true)
        allow(Order).to receive(:exists?).with(order_number: "20250315002").and_return(false)
      end

      it "loops until a unique number is found" do
        expect(generator.call).to eq("20250315002")
      end
    end

    context "resets per day" do
      let(:other_date) { Date.new(2025, 3, 16) }
      let(:other_scope) { instance_double(ActiveRecord::Relation) }

      before do
        allow(Order).to receive(:where).with(running_date: other_date).and_return(other_scope)
        allow(other_scope).to receive(:count).and_return(0)
        allow(Order).to receive(:exists?).with(order_number: "20250316001").and_return(false)
      end

      it "returns 001 for a different day" do
        expect(described_class.new(other_date).call).to eq("20250316001")
      end
    end
  end
end
