# frozen_string_literal: true

require "rails_helper"

RSpec.describe CombinedBillsService do
  subject(:service) { described_class.new(order_ids: [order1.id, order2.id], prepared_by: "Test Staff") }

  let(:customer)  { create(:customer) }
  let!(:order1)   { create(:order, customer: customer, grand_total: 1000) }
  let!(:order2)   { create(:order, customer: customer, grand_total: 2500) }

  describe "#build" do
    context "when all orders belong to same customer" do
      it "returns a package and customer_name" do
        result = service.build
        expect(result[:error]).to be_nil
        expect(result[:package]).to be_a(Axlsx::Package)
        expect(result[:customer_name]).to eq(customer.fullname)
      end

      it "produces a worksheet named ใบรวมบิล" do
        result = service.build
        expect(result[:package].workbook.worksheets.first.name).to eq("ใบรวมบิล")
      end

      it "includes both order numbers in the sheet" do
        result = service.build
        ws = result[:package].workbook.worksheets.first
        all_values = ws.rows.flat_map { |r| r.cells.map(&:value) }.map(&:to_s)
        expect(all_values).to include(order1.order_number)
        expect(all_values).to include(order2.order_number)
      end

      it "includes a total row summing grand totals" do
        result = service.build
        ws = result[:package].workbook.worksheets.first
        all_nums = ws.rows.flat_map { |r| r.cells.map(&:value) }
        expect(all_nums).to include(3500.0)
      end

      it "includes prepared_by in the sheet" do
        result = service.build
        ws = result[:package].workbook.worksheets.first
        all_values = ws.rows.flat_map { |r| r.cells.map(&:value) }.map(&:to_s)
        expect(all_values).to include("Test Staff")
      end
    end

    context "when orders belong to different customers" do
      let(:other_customer) { create(:customer) }
      let!(:other_order)   { create(:order, customer: other_customer) }

      it "returns an error" do
        svc    = described_class.new(order_ids: [order1.id, other_order.id], prepared_by: "Staff")
        result = svc.build
        expect(result[:error]).to include("same customer")
      end
    end

    context "when no orders found" do
      it "returns an error" do
        svc    = described_class.new(order_ids: [999_999], prepared_by: "Staff")
        result = svc.build
        expect(result[:error]).to be_present
      end
    end
  end
end
