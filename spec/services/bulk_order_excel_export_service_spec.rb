# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkOrderExcelExportService do
  let(:customer) { create(:customer, first_name: "Alice", last_name: "Smith") }
  let(:product)  { create(:product, name: "Widget A", description: "Blue large") }
  let(:product_no_desc) { create(:product, name: "Widget B", description: nil) }

  let(:order) do
    create(:order, customer: customer, running_date: Date.new(2026, 4, 22),
                   order_number: "20260422001",
                   has_vat: false, is_withholding_tax: false, discount_price: 0)
  end

  before do
    create(:order_line, order: order, product: product,
                        quantity: 3, unit_price: 1000.00, discount_price: 0)
  end

  def build_service(orders)
    described_class.new(orders)
  end

  def all_cell_values(worksheet)
    worksheet.rows.flat_map { |r| r.cells.map(&:value) }
  end

  describe "#build" do
    context "with a single order" do
      subject(:package) do
        build_service(Order.where(id: order.id).includes(order_lines: %i[product unit_definition], customer: [])).build
      end

      it "returns an Axlsx::Package" do
        expect(package).to be_a(Axlsx::Package)
      end

      it "contains exactly 1 worksheet" do
        expect(package.workbook.worksheets.count).to eq(1)
      end

      it "names the sheet '{order_number} - {customer_fullname}'" do
        expected = "#{order.order_number} - #{customer.fullname}"
        expect(package.workbook.worksheets.first.name).to eq(expected[0, 31])
      end

      it "includes the date in row 1" do
        values = all_cell_values(package.workbook.worksheets.first)
        expect(values).to include(order.running_date.strftime("%d-%b-%Y"))
      end

      it "includes the order number in row 2" do
        values = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).to include(order.order_number.to_s)
      end

      it "includes the customer fullname in row 3" do
        values = all_cell_values(package.workbook.worksheets.first)
        expect(values).to include(customer.fullname)
      end

      it "includes column headers row with 'NO', 'Quantity', 'Unit', 'Description', 'Price per Unit', 'Total'" do
        values = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).to include("NO", "Quantity", "Unit", "Description", "Price per Unit", "Total")
      end

      it "includes a data row with quantity and prices" do
        values = all_cell_values(package.workbook.worksheets.first)
        expect(values).to include(3.0)      # quantity
        expect(values).to include(1000.0)   # unit price
        expect(values).to include(3000.0)   # total price
      end

      it "sets Description as 'product.name product.description' when description is present" do
        values = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).to include("Widget A Blue large")
      end

      it "includes 'Total' and 'Grand Total' footer rows" do
        values = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).to include("Total", "Grand Total")
      end

      it "does not include 'Discount' row when discount is zero" do
        values = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).not_to include("Discount")
      end

      it "does not include VAT rows when has_vat is false" do
        values = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).not_to include("Price excl. VAT")
        expect(values).not_to include("VAT 7%")
      end

      it "does not include WHT row when is_withholding_tax is false" do
        values = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).not_to include(match(/WHT/))
      end
    end

    context "with description-less product" do
      let(:order2) do
        create(:order, customer: customer, running_date: Date.new(2026, 4, 22),
                       has_vat: false, is_withholding_tax: false, discount_price: 0)
      end

      before do
        create(:order_line, order: order2, product: product_no_desc,
                            quantity: 1, unit_price: 200.00, discount_price: 0)
      end

      it "sets Description as product.name only (no trailing space)" do
        service = build_service(Order.where(id: order2.id).includes(order_lines: %i[product unit_definition],
                                                                    customer: []))
        package = service.build
        values  = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).to include("Widget B")
        expect(values).not_to include("Widget B ")
      end
    end

    context "with sheet name truncation" do # rubocop:disable RSpec/MultipleMemoizedHelpers
      let(:long_name_customer) do
        create(:customer, first_name: "Supercalifragilistic", last_name: "Expialidocious")
      end
      let(:long_order) do
        create(:order, customer: long_name_customer, running_date: Date.new(2026, 4, 22),
                       has_vat: false, is_withholding_tax: false)
      end

      it "truncates sheet name to 31 characters" do
        service = build_service(Order.where(id: long_order.id).includes(order_lines: %i[product unit_definition],
                                                                        customer: []))
        package = service.build
        expect(package.workbook.worksheets.first.name.length).to be <= 31
      end
    end

    context "with N orders" do
      let(:order_b) do
        create(:order, customer: customer, running_date: Date.new(2026, 4, 22),
                       has_vat: false, is_withholding_tax: false)
      end

      it "produces one worksheet per order" do
        service = build_service(Order.where(id: [order.id, order_b.id]).includes(
                                  order_lines: %i[product unit_definition], customer: []
                                ))
        package = service.build
        expect(package.workbook.worksheets.count).to eq(2)
      end
    end

    context "with duplicate truncated sheet names" do
      subject(:service) { build_service(Order.none) }

      it "deduplicates sheet names by appending ' (2)'" do
        name   = "ORDER-SAME - Customer A"
        used   = [name]
        result = service.send(:deduplicate_sheet_name, name, used)
        expect(result).to eq("#{name} (2)")
      end

      it "deduplicates further by appending ' (3)'" do
        name   = "ORDER-SAME - Customer A"
        used   = [name, "#{name} (2)"]
        result = service.send(:deduplicate_sheet_name, name, used)
        expect(result).to eq("#{name} (3)")
      end

      it "keeps deduplicated names within 31 characters" do
        long_name = "A" * 31
        used      = [long_name]
        result    = service.send(:deduplicate_sheet_name, long_name, used)
        expect(result.length).to be <= 31
      end
    end

    context "with VAT order" do
      let(:vat_order) do
        create(:order, :with_vat, customer: customer, running_date: Date.new(2026, 4, 22),
                                  discount_price: 0, is_withholding_tax: false)
      end

      before do
        create(:order_line, order: vat_order, product: product,
                            quantity: 1, unit_price: 1000.00, discount_price: 0)
      end

      it "includes Price excl. VAT and VAT 7% footer rows" do
        service = build_service(Order.where(id: vat_order.id).includes(order_lines: %i[product unit_definition],
                                                                       customer: []))
        package = service.build
        values  = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).to include("Price excl. VAT", "VAT 7%")
      end
    end

    context "with withholding tax order" do
      let(:wht_order) do
        create(:order, :with_withholding_tax, customer: customer, running_date: Date.new(2026, 4, 22),
                                              discount_price: 0, has_vat: false)
      end

      before do
        create(:order_line, order: wht_order, product: product,
                            quantity: 1, unit_price: 1000.00, discount_price: 0)
      end

      it "includes WHT footer row" do
        service = build_service(Order.where(id: wht_order.id).includes(order_lines: %i[product unit_definition],
                                                                       customer: []))
        package = service.build
        values  = all_cell_values(package.workbook.worksheets.first).map(&:to_s)
        expect(values).to include(match(/WHT/))
      end
    end
  end
end
