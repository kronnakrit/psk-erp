# frozen_string_literal: true

require "rails_helper"

RSpec.describe LotAwareStockAdjustmentService do
  let(:branch) { create(:branch, :main) }
  let(:product) { create(:product) }
  let(:stock) { create(:product_stock, product: product, branch: branch, amount: 50, holding_amount: 10) }
  let(:lot) do
    create(:product_lot, product: product, remaining_quantity: 30, original_quantity: 30, status: ProductLot::STATUS_ACTIVE)
  end
  let(:adjuster) { create(:user) }

  def call(overrides = {})
    defaults = {
      stock: stock,
      product_lot: lot,
      amount: 5,
      action: :deposit,
      reason: "test",
      adjuster: adjuster
    }
    described_class.call(**defaults.merge(overrides))
  end

  describe "#call — deposit" do
    it "returns success" do
      expect(call).to be_success
    end

    it "increases stock amount and lot remaining_quantity" do
      call(amount: 5)
      expect(stock.reload.amount).to eq(55)
      expect(lot.reload.remaining_quantity).to eq(35)
    end

    it "does not change original_quantity" do
      call(amount: 5)
      expect(lot.reload.original_quantity).to eq(30)
    end

    it "creates IB transaction linked to the lot" do
      call(amount: 5, reason: "restock")
      txn = stock.product_stock_transactions.last
      expect(txn.transaction_type).to eq("IB")
      expect(txn.amount).to eq(5)
      expect(txn.reason).to eq("restock")
      expect(txn.related_object).to eq(lot)
      expect(txn.adjuster_id).to eq(adjuster.id)
    end

    it "reactivates a depleted lot" do
      lot.update!(remaining_quantity: 0, status: ProductLot::STATUS_DEPLETED)
      call(amount: 3)
      expect(lot.reload.status).to eq(ProductLot::STATUS_ACTIVE)
      expect(lot.remaining_quantity).to eq(3)
    end

    it "rejects non-positive amount" do
      result = call(amount: 0)
      expect(result).not_to be_success
      expect(result.error).to eq(I18n.t("stocks.adjustment.amount_must_be_positive"))
    end

    it "rejects lot from another product" do
      other_lot = create(:product_lot)
      result = call(product_lot: other_lot)
      expect(result).not_to be_success
      expect(result.error).to be_present
    end
  end

  describe "#call — withdraw" do
    it "returns success when amount is within lot and available stock" do
      expect(call(action: :withdraw, amount: 5)).to be_success
    end

    it "decreases stock amount and lot remaining_quantity" do
      call(action: :withdraw, amount: 5)
      expect(stock.reload.amount).to eq(45)
      expect(lot.reload.remaining_quantity).to eq(25)
    end

    it "creates OB transaction linked to the lot" do
      call(action: :withdraw, amount: 5, reason: "adjustment")
      txn = stock.product_stock_transactions.last
      expect(txn.transaction_type).to eq("OB")
      expect(txn.related_object).to eq(lot)
    end

    it "marks lot depleted when remaining hits zero" do
      call(action: :withdraw, amount: 30)
      expect(lot.reload.status).to eq(ProductLot::STATUS_DEPLETED)
      expect(lot.remaining_quantity).to eq(0)
    end

    it "rejects when amount exceeds lot remaining_quantity" do
      result = call(action: :withdraw, amount: 31)
      expect(result).not_to be_success
      expect(stock.reload.amount).to eq(50)
      expect(lot.reload.remaining_quantity).to eq(30)
    end

    it "rejects when amount exceeds available stock (amount - holding)" do
      stock.update!(amount: 15, holding_amount: 10)
      result = call(action: :withdraw, amount: 6)
      expect(result).not_to be_success
      expect(lot.reload.remaining_quantity).to eq(30)
    end
  end
end
