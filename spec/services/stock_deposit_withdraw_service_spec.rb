# frozen_string_literal: true

require "rails_helper"

RSpec.describe StockDepositWithdrawService do
  let(:unit_group) { create(:unit_group) }
  let!(:pcs)       { create(:unit_definition, unit_group: unit_group, name: "pcs",   ratio: 1) }
  let!(:dozen)     { create(:unit_definition, unit_group: unit_group, name: "dozen", ratio: 12) }
  let(:product)    { create(:product, unit_group: unit_group) }
  let(:branch)     { create(:branch, :main) }
  let(:stock)      { create(:product_stock, product: product, branch: branch, amount: 0) }
  let(:adjuster)   { create(:user) }

  def call(overrides = {})
    defaults = {
      stock:              stock,
      quantity:           1,
      unit_definition_id: pcs.id,
      action:             :deposit,
      reason:             "test",
      adjuster:           adjuster
    }
    described_class.call(**defaults.merge(overrides))
  end

  describe "#call — deposit" do
    context "when quantity and unit are valid" do
      it "returns success" do
        result = call(quantity: 2, unit_definition_id: pcs.id, action: :deposit)
        expect(result).to be_success
      end

      it "converts to base units: 1 dozen = 12 pcs" do
        result = call(quantity: 1, unit_definition_id: dozen.id, action: :deposit)
        expect(result.base_amount).to eq(BigDecimal("12"))
        expect(stock.reload.amount).to eq(12)
      end

      it "converts to base units: 2 dozen = 24 pcs" do
        result = call(quantity: 2, unit_definition_id: dozen.id, action: :deposit)
        expect(result.base_amount).to eq(BigDecimal("24"))
        expect(stock.reload.amount).to eq(24)
      end

      it "deposits single pcs correctly" do
        result = call(quantity: 5, unit_definition_id: pcs.id, action: :deposit)
        expect(result.base_amount).to eq(BigDecimal("5"))
        expect(stock.reload.amount).to eq(5)
      end
    end

    context "when quantity is zero" do
      it "returns failure with error message" do
        result = call(quantity: 0, action: :deposit)
        expect(result).not_to be_success
        expect(result.error).to eq("Quantity must be greater than 0.")
      end

      it "does not change stock amount" do
        expect { call(quantity: 0, action: :deposit) }.not_to change { stock.reload.amount }
      end
    end

    context "when quantity is negative" do
      it "returns failure with error message" do
        result = call(quantity: -3, action: :deposit)
        expect(result).not_to be_success
        expect(result.error).to eq("Quantity must be greater than 0.")
      end
    end
  end

  describe "#call — withdraw" do
    before { stock.update!(amount: 100) }

    context "when sufficient stock is available" do
      it "withdraws and returns success" do
        result = call(quantity: 2, unit_definition_id: pcs.id, action: :withdraw)
        expect(result).to be_success
        expect(stock.reload.amount).to eq(98)
      end

      it "withdraws in dozens: 1 dozen = 12 pcs" do
        result = call(quantity: 1, unit_definition_id: dozen.id, action: :withdraw)
        expect(result.base_amount).to eq(BigDecimal("12"))
        expect(stock.reload.amount).to eq(88)
      end
    end

    # NOTE: ProductStock#withdraw! uses decrement! which skips model validations.
    # The service does not enforce a stock floor — callers must check availability.
    context "when stock would go negative (decrement! skips validation)" do
      before { stock.update!(amount: 5) }

      it "still succeeds (no floor enforcement in service layer)" do
        result = call(quantity: 1, unit_definition_id: dozen.id, action: :withdraw)
        expect(result).to be_success
        expect(result.base_amount).to eq(12)
      end
    end
  end

  describe "#call — invalid unit_definition_id" do
    context "when unit_definition does not belong to product's effective unit group" do
      let(:other_group) { create(:unit_group) }
      let!(:other_unit) { create(:unit_definition, unit_group: other_group, name: "kg", ratio: 1) }

      it "returns failure with invalid unit error" do
        result = call(unit_definition_id: other_unit.id, action: :deposit)
        expect(result).not_to be_success
        expect(result.error).to eq("Invalid unit for this product.")
      end
    end

    context "when unit_definition_id does not exist" do
      it "returns failure" do
        result = call(unit_definition_id: 999_999, action: :deposit)
        expect(result).not_to be_success
        expect(result.error).to eq("Invalid unit for this product.")
      end
    end
  end

  describe "#call — no effective unit group" do
    let(:product_no_group) { create(:product, unit_group: nil) }
    let(:stock_no_group)   { create(:product_stock, product: product_no_group, branch: branch, amount: 0) }

    before { UnitGroup.update_all(is_default: false) } # rubocop:disable Rails/SkipsModelValidations

    it "returns failure when no unit group exists" do
      result = call(stock: stock_no_group, unit_definition_id: pcs.id, action: :deposit)
      expect(result).not_to be_success
      expect(result.error).to eq("Invalid unit for this product.")
    end
  end

  describe "#call — unknown action" do
    it "returns failure with unknown action error" do
      result = call(action: :transfer)
      expect(result).not_to be_success
      expect(result.error).to eq("Unknown action.")
    end
  end

  describe "Result struct" do
    it "exposes success? as a predicate" do
      result = call(quantity: 1, unit_definition_id: pcs.id, action: :deposit)
      expect(result.success?).to be true
    end

    it "exposes base_amount on success" do
      result = call(quantity: 2, unit_definition_id: dozen.id, action: :deposit)
      expect(result.base_amount).to eq(24)
    end

    it "exposes error on failure" do
      result = call(quantity: 0)
      expect(result.error).to be_present
    end
  end

  describe "#call — RecordInvalid rescue" do
    it "returns failure when deposit! raises RecordInvalid" do
      invalid_stock = ProductStock.new
      allow(stock).to receive(:deposit!).and_raise(ActiveRecord::RecordInvalid.new(invalid_stock))
      result = call(quantity: 1, unit_definition_id: pcs.id, action: :deposit)
      expect(result).not_to be_success
      expect(result.error).to be_present
    end
  end
end
