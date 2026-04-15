# frozen_string_literal: true

require "rails_helper"

RSpec.describe GrandTotalCalculator do
  # Helpers to build a lightweight order double
  def build_order(attrs = {})
    line_total = attrs.delete(:line_total) || 1000
    order = double("Order") # rubocop:disable RSpec/VerifiedDoubles
    # Boolean attribute defaults (Rails predicate methods)
    # Numeric attributes
    # Order lines
    lines = double("order_lines")
    allow(lines).to receive(:sum).with(:total_price).and_return(line_total)
    allow(order).to receive_messages(has_vat?: attrs.fetch(:has_vat, false),
                                     is_included_vat?: attrs.fetch(:is_included_vat, false), is_discount_percentage?: attrs.fetch(:is_discount_percentage, false), is_withholding_tax?: attrs.fetch(:is_withholding_tax, false), discount_price: attrs.fetch(:discount_price, 0), discount_percentage: attrs.fetch(:discount_percentage, 0), withholding_tax: attrs.fetch(:withholding_tax, 0), order_lines: lines)
    order
  end

  subject(:calculator) { described_class.new(order) }

  describe "#call" do
    # Scenario 1: no VAT, no discount, no withholding tax
    context "with no VAT, no discount, no WHT (1000 subtotal)" do
      let(:order) { build_order(line_total: 1000) }

      it "returns grand_total == subtotal" do
        result = calculator.call
        expect(result[:total_price]).to eq(BigDecimal("1000"))
        expect(result[:discount_amount]).to eq(BigDecimal("0"))
        expect(result[:vat_price]).to eq(BigDecimal("0"))
        expect(result[:withholding_tax_amount]).to eq(BigDecimal("0"))
        expect(result[:grand_total]).to eq(BigDecimal("1000"))
      end
    end

    # Scenario 2: absolute discount
    context "with absolute discount of 100" do
      let(:order) { build_order(line_total: 1000, discount_price: 100) }

      it "applies the absolute discount" do
        result = calculator.call
        expect(result[:discount_amount]).to eq(BigDecimal("100"))
        expect(result[:price_with_discount]).to eq(BigDecimal("900"))
        expect(result[:grand_total]).to eq(BigDecimal("900"))
      end
    end

    # Scenario 3: percentage discount
    context "with 10% percentage discount" do
      let(:order) { build_order(line_total: 1000, is_discount_percentage: true, discount_percentage: 10) }

      it "applies 10% discount" do
        result = calculator.call
        expect(result[:discount_amount]).to eq(BigDecimal("100"))
        expect(result[:price_with_discount]).to eq(BigDecimal("900"))
      end
    end

    # Scenario 4: VAT add-on (not included)
    context "with VAT added on top (1000 subtotal, 7% add-on)" do
      let(:order) { build_order(line_total: 1000, has_vat: true, is_included_vat: false) }

      it "adds 7% VAT to the gross total" do
        result = calculator.call
        expect(result[:vat_price]).to eq(BigDecimal("70.00"))
        expect(result[:grand_total]).to eq(BigDecimal("1070.00"))
      end
    end

    # Scenario 5: VAT included (reverse extract)
    context "with VAT already included in price (1070 subtotal)" do
      let(:order) { build_order(line_total: 1070, has_vat: true, is_included_vat: true) }

      it "reverse-extracts VAT correctly" do
        result = calculator.call
        # price_excl_vat = 1070 / 1.07 = 1000.00
        expect(result[:price_excl_vat].round(2)).to eq(BigDecimal("1000.00"))
        expect(result[:vat_price].round(2)).to eq(BigDecimal("70.00"))
        expect(result[:grand_total].round(2)).to eq(BigDecimal("1070.00"))
      end
    end

    # Scenario 6: withholding tax 3% (no VAT)
    context "with 3% withholding tax on 1000 subtotal" do
      let(:order) { build_order(line_total: 1000, is_withholding_tax: true, withholding_tax: 3) }

      it "deducts WHT from grand total" do
        result = calculator.call
        expect(result[:withholding_tax_amount]).to eq(BigDecimal("30.00"))
        expect(result[:grand_total]).to eq(BigDecimal("970.00"))
      end
    end

    # Scenario 7: VAT add-on + WHT
    context "with VAT add-on and 3% WHT" do
      let(:order) do
        build_order(line_total: 1000, has_vat: true, is_included_vat: false,
                    is_withholding_tax: true, withholding_tax: 3)
      end

      it "calculates correctly: 1000 + 70 VAT - 30 WHT = 1040" do
        result = calculator.call
        expect(result[:vat_price]).to eq(BigDecimal("70.00"))
        expect(result[:withholding_tax_amount]).to eq(BigDecimal("30.00"))
        # grand_total = price_excl_vat(1000) + vat(70) - wht(30) = 1040
        expect(result[:grand_total]).to eq(BigDecimal("1040.00"))
      end
    end

    # Scenario 8: discount + VAT included + WHT
    context "with 100 absolute discount, VAT included (1070), 3% WHT" do
      let(:order) do
        build_order(line_total: 1070, discount_price: 100,
                    has_vat: true, is_included_vat: true,
                    is_withholding_tax: true, withholding_tax: 3)
      end

      it "applies all transformations in order" do
        result = calculator.call
        price_with_discount = BigDecimal("970") # 1070 - 100
        price_excl_vat      = (price_with_discount / BigDecimal("1.07")).round(2, BigDecimal::ROUND_HALF_UP)
        vat_price           = (price_with_discount - price_excl_vat).round(2, BigDecimal::ROUND_HALF_UP)
        wht                 = (price_excl_vat * BigDecimal("0.03")).round(2, BigDecimal::ROUND_HALF_UP)
        expected_grand      = (price_excl_vat + vat_price - wht).round(2, BigDecimal::ROUND_HALF_UP)

        expect(result[:discount_amount]).to eq(BigDecimal("100"))
        expect(result[:price_with_discount]).to eq(price_with_discount)
        expect(result[:price_excl_vat]).to eq(price_excl_vat)
        expect(result[:vat_price]).to eq(vat_price)
        expect(result[:withholding_tax_amount]).to eq(wht)
        expect(result[:grand_total]).to eq(expected_grand)
      end
    end
  end
end
