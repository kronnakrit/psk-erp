# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerReportService do
  subject(:service) { described_class.new(start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31)) }

  let!(:cust1) { create(:customer, first_name: "Alice", last_name: "Smith") }
  let!(:cust2) { create(:customer, first_name: "Bob", last_name: "Jones") }

  let!(:order1) { create(:order, :completed, customer: cust1, grand_total: 3000, running_date: Date.new(2026, 1, 10)) }
  let!(:order2) { create(:order, :completed, customer: cust1, grand_total: 1500, running_date: Date.new(2026, 1, 20)) }
  let!(:order3) { create(:order, :completed, customer: cust2, grand_total: 5000, running_date: Date.new(2026, 1, 15)) }
  let!(:out_of_range) do
    create(:order, :completed, customer: cust1, grand_total: 9999, running_date: Date.new(2025, 12, 31))
  end
  let!(:draft_order) { create(:order, customer: cust1, grand_total: 9999, running_date: Date.new(2026, 1, 5)) }

  describe "#build" do
    it "returns an Axlsx::Package" do
      expect(service.build).to be_a(Axlsx::Package)
    end

    it "produces a sheet named Customer Report" do
      pkg = service.build
      expect(pkg.workbook.worksheets.first.name).to eq("Customer Report")
    end

    it "excludes orders outside the date range" do
      pkg = service.build
      ws  = pkg.workbook.worksheets.first
      all_nums = ws.rows.flat_map { |r| r.cells.map(&:value) }
      expect(all_nums).not_to include(9999.0)
    end

    it "excludes non-completed orders" do
      pkg = service.build
      ws  = pkg.workbook.worksheets.first
      all_nums = ws.rows.flat_map { |r| r.cells.map(&:value) }
      expect(all_nums).not_to include(9999.0)
    end

    it "sums grand_total per customer" do
      pkg = service.build
      ws  = pkg.workbook.worksheets.first
      all_nums = ws.rows.flat_map { |r| r.cells.map(&:value) }
      expect(all_nums).to include(4500.0) # cust1: 3000+1500
      expect(all_nums).to include(5000.0) # cust2
    end

    it "sorts by total descending (cust2 first at 5000)" do
      pkg       = service.build
      ws        = pkg.workbook.worksheets.first
      data_rows = ws.rows.to_a.drop(4)
      first_row_vals = data_rows.first.cells.map(&:value)
      expect(first_row_vals).to include(5000.0)
    end
  end
end
