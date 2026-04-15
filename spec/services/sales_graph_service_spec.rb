# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalesGraphService do
  subject(:service) do
    described_class.new(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 2, 28))
  end

  let(:customer) { create(:customer) }

  let!(:jan_completed) do
    create(:order, :completed, customer: customer, grand_total: 3000, running_date: Date.new(2026, 1, 10))
  end
  let!(:jan_draft) do
    create(:order, customer: customer, grand_total: 500, running_date: Date.new(2026, 1, 5))
  end
  let!(:feb_paid) do
    create(:order, :paid, customer: customer, grand_total: 1500, running_date: Date.new(2026, 2, 14))
  end

  describe "#call" do
    it "returns a hash with keys :draft, :paid, :completed, :cancelled" do
      result = service.call
      expect(result.keys).to match_array(%i[draft paid completed cancelled])
    end

    it "sums completed grand_total for January" do
      result = service.call
      jan_entry = result[:completed].find { |e| e[:month] == 1 && e[:year] == 2026 }
      expect(jan_entry).not_to be_nil
      expect(jan_entry[:grand_total__sum]).to eq(3000.0)
    end

    it "separates draft orders" do
      result = service.call
      jan_draft_entry = result[:draft].find { |e| e[:month] == 1 && e[:year] == 2026 }
      expect(jan_draft_entry).not_to be_nil
      expect(jan_draft_entry[:grand_total__sum]).to eq(500.0)
    end

    it "sums paid grand_total for February" do
      result = service.call
      feb_entry = result[:paid].find { |e| e[:month] == 2 && e[:year] == 2026 }
      expect(feb_entry).not_to be_nil
      expect(feb_entry[:grand_total__sum]).to eq(1500.0)
    end

    it "returns 0.0 for months with no orders" do
      result = service.call
      # February should have 0 completed orders
      feb_completed = result[:completed].find { |e| e[:month] == 2 && e[:year] == 2026 }
      expect(feb_completed[:grand_total__sum]).to eq(0.0)
    end

    context "with empty date range" do
      subject(:empty_service) do
        described_class.new(start_date: Date.new(2020, 1, 1), end_date: Date.new(2020, 1, 31))
      end

      it "returns arrays with zero-fill for specified range" do
        result = empty_service.call
        expect(result[:completed]).to all(satisfy { |e| e[:grand_total__sum] == 0.0 })
      end
    end
  end
end
