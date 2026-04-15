# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderExcelService do
  subject(:service) { described_class.new(order) }

  let(:customer) { create(:customer) }
  let(:product)  { create(:product) }
  let(:order) do
    create(:order, customer: customer, running_date: Date.new(2026, 4, 12),
                   has_vat: false, is_withholding_tax: false, discount_price: 0)
  end
  let!(:line) do
    create(:order_line, order: order, product: product,
                        quantity: 3, unit_price: 1000.00, discount_price: 0)
  end

  describe "#build" do
    it "returns an Axlsx::Package" do
      expect(service.build).to be_a(Axlsx::Package)
    end

    it "produces an xlsx workbook with one sheet named Invoice" do
      package = service.build
      expect(package.workbook.worksheets.count).to eq(1)
      expect(package.workbook.worksheets.first.name).to eq("Invoice")
    end

    it "includes the order number in the header rows" do
      package = service.build
      ws       = package.workbook.worksheets.first
      all_text = ws.rows.flat_map { |r| r.cells.map(&:value) }.map(&:to_s)
      expect(all_text).to include(order.order_number)
    end

    it "includes the customer fullname in the header rows" do
      package = service.build
      ws       = package.workbook.worksheets.first
      all_text = ws.rows.flat_map { |r| r.cells.map(&:value) }.map(&:to_s)
      expect(all_text).to include(customer.fullname)
    end

    it "includes a body row for each order line" do
      package   = service.build
      ws        = package.workbook.worksheets.first
      all_nums  = ws.rows.flat_map { |r| r.cells.map(&:value) }
      expect(all_nums).to include(3)       # quantity
      expect(all_nums).to include(1000.0)  # unit price
      expect(all_nums).to include(3000.0)  # line total
    end

    it "includes a Grand Total row" do
      package  = service.build
      ws       = package.workbook.worksheets.first
      all_text = ws.rows.flat_map { |r| r.cells.map(&:value) }.map(&:to_s)
      expect(all_text).to include("Grand Total")
    end
  end
end
