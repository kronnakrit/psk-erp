# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalesReportService do
  subject(:service) { described_class.new(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31)) }

  let!(:user1) { create(:user) }
  let!(:o1) do
    create(:order, :completed, customer: customer, created_by: user1,
                               grand_total: 2000, running_date: Date.new(2026, 1, 5))
  end
  let!(:o2) do
    create(:order, :completed, customer: customer, created_by: user1,
                               grand_total: 1000, running_date: Date.new(2026, 1, 10))
  end
  let!(:o3) do
    create(:order, :completed, customer: customer, created_by: user2,
                               grand_total: 5000, running_date: Date.new(2026, 1, 12))
  end
  let!(:user2) { create(:user) }
  let(:customer) { create(:customer) }

  before do
    user1.build_profile(first_name: "Alice", last_name: "Staff").save!
    user2.build_profile(first_name: "Bob", last_name: "Staff").save!
  end

  describe "#build" do
    it "returns an Axlsx::Package" do
      expect(service.build).to be_a(Axlsx::Package)
    end

    it "produces a sheet named Sales Report" do
      pkg = service.build
      expect(pkg.workbook.worksheets.first.name).to eq("Sales Report")
    end

    it "sums grand_total per staff member" do
      pkg      = service.build
      ws       = pkg.workbook.worksheets.first
      all_nums = ws.rows.flat_map { |r| r.cells.map(&:value) }
      expect(all_nums).to include(3000.0)  # user1: 2000+1000
      expect(all_nums).to include(5000.0)  # user2
    end

    it "sorts descending by total (user2 first)" do
      pkg       = service.build
      ws        = pkg.workbook.worksheets.first
      data_rows = ws.rows.to_a.drop(4)
      first_row_vals = data_rows.first.cells.map(&:value)
      expect(first_row_vals).to include(5000.0)
    end
  end
end
