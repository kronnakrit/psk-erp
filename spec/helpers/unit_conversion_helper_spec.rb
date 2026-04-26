# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnitConversionHelper do
  include described_class

  # Stub `number_with_precision` since we're not in a Rails view context
  def number_with_precision(value, precision: 2, strip_insignificant_zeros: false)
    result = format("%.#{precision}f", value)
    strip_insignificant_zeros ? result.sub(/\.?0+$/, "") : result
  end

  let(:unit_group) { create(:unit_group) }
  let!(:pcs)       { create(:unit_definition, unit_group: unit_group, name: "pcs",   ratio: 1) }
  let!(:dozen)     { create(:unit_definition, unit_group: unit_group, name: "dozen", ratio: 12) }

  describe "#format_stock_amount" do
    # AC-01 — 37 => "3 dozen 1 pcs"
    it "formats 37 as '3 dozen 1 pcs'" do
      expect(format_stock_amount(37, unit_group)).to eq("3 dozen 1 pcs")
    end

    # AC-02 — 13 => "1 dozen 1 pcs"; 24 => "2 dozen"
    it "formats 13 as '1 dozen 1 pcs'" do
      expect(format_stock_amount(13, unit_group)).to eq("1 dozen 1 pcs")
    end

    it "formats 24 as '2 dozen' (no trailing zero units)" do
      expect(format_stock_amount(24, unit_group)).to eq("2 dozen")
    end

    # AC-05 — 3-unit group: pcs(1), dozen(12), gross(144); 200 => "1 gross 4 dozen 8 pcs"
    context "with a 3-level unit group" do
      let!(:gross) { create(:unit_definition, unit_group: unit_group, name: "gross", ratio: 144) }

      it "formats 200 as '1 gross 4 dozen 8 pcs'" do
        expect(format_stock_amount(200, unit_group)).to eq("1 gross 4 dozen 8 pcs")
      end

      # AC-06 — 144 => "1 gross"
      it "formats 144 as '1 gross' (no trailing zero units)" do
        expect(format_stock_amount(144, unit_group)).to eq("1 gross")
      end
    end

    # AC-04 — no unit group configured (nil)
    it "falls back to raw number with warning when unit_group is nil" do
      result = format_stock_amount(37, nil, legacy_unit_name: "item")
      expect(result).to include("37")
      expect(result).to include("item")
      expect(result).to include("No unit group")
    end

    it "falls back gracefully when unit_group is nil and no legacy label given" do
      result = format_stock_amount(10, nil)
      expect(result).to include("10")
      expect(result).to include("No unit group")
    end

    # Edge case: zero amount
    it "displays '0 pcs' for zero amount" do
      expect(format_stock_amount(0, unit_group)).to eq("0 pcs")
    end

    # Edge case: single-unit group (pcs only)
    context "with a single-unit group" do
      let(:single_group)  { create(:unit_group) }
      let!(:single_unit)  { create(:unit_definition, unit_group: single_group, name: "pcs", ratio: 1) }

      it "displays the raw integer followed by the unit name" do
        expect(format_stock_amount(5, single_group)).to eq("5 pcs")
      end
    end

    # Edge case: fractional remainder
    it "appends fractional remainder to display" do
      result = format_stock_amount(2.5, unit_group)
      expect(result).to include("+0.5 pcs")
    end

    # Edge case: negative amount
    it "prefixes negative amounts with '-'" do
      result = format_stock_amount(-13, unit_group)
      expect(result).to start_with("-")
      expect(result).to include("dozen")
    end
  end
end
