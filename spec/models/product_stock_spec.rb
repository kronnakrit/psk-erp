# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductStock, type: :model do
  let(:branch)  { create(:branch, :main) }
  let(:product) { create(:product) }
  let(:stock)   { create(:product_stock, branch: branch, product: product) }

  describe "#total_amount" do
    it "returns amount minus holding_amount" do
      stock.update!(amount: 100, holding_amount: 30)
      expect(stock.total_amount).to eq(70)
    end
  end

  describe ".find_or_create_for!" do
    it "creates a stock record for a product+branch pair" do
      expect do
        described_class.find_or_create_for!(product: product, branch: branch)
      end.to change(described_class, :count).by(1)
    end

    it "returns existing record on second call" do
      existing = described_class.find_or_create_for!(product: product, branch: branch)
      found    = described_class.find_or_create_for!(product: product, branch: branch)
      expect(found).to eq(existing)
    end
  end

  describe "#deposit!" do
    it "increments amount by the given value" do
      stock.deposit!(amount: 50, reason: "Initial stock")
      expect(stock.reload.amount).to eq(50)
    end

    it "creates an IB transaction" do
      expect do
        stock.deposit!(amount: 20, reason: "Purchase")
      end.to change { stock.product_stock_transactions.where(transaction_type: "IB").count }.by(1)
    end

    it "records adjuster_id when adjuster is provided" do
      adjuster = create(:user)
      stock.deposit!(amount: 10, reason: "In", adjuster: adjuster)
      txn = stock.product_stock_transactions.last
      expect(txn.adjuster_id).to eq(adjuster.id)
    end
  end

  describe "#withdraw!" do
    before { stock.update!(amount: 100) }

    it "decrements amount by the given value" do
      stock.withdraw!(amount: 30, reason: "Sale")
      expect(stock.reload.amount).to eq(70)
    end

    it "creates an OB transaction" do
      expect do
        stock.withdraw!(amount: 10, reason: "Sale")
      end.to change { stock.product_stock_transactions.where(transaction_type: "OB").count }.by(1)
    end

    it "records adjuster_id when adjuster is provided" do
      adjuster = create(:user)
      stock.withdraw!(amount: 10, reason: "Out", adjuster: adjuster)
      txn = stock.product_stock_transactions.last
      expect(txn.adjuster_id).to eq(adjuster.id)
    end
  end

  describe "#withdraw_from_holding!" do
    before { stock.update!(amount: 100, holding_amount: 40) }

    it "decrements both amount and holding_amount" do
      stock.withdraw_from_holding!(amount: 20, reason: "Fulfilled")
      stock.reload
      expect(stock.amount).to eq(80)
      expect(stock.holding_amount).to eq(20)
    end

    it "creates an OB transaction" do
      expect do
        stock.withdraw_from_holding!(amount: 5, reason: "Fulfilled")
      end.to change { stock.product_stock_transactions.where(transaction_type: "OB").count }.by(1)
    end

    it "creates a transaction with adjuster_id nil (no adjuster passed)" do
      stock.withdraw_from_holding!(amount: 5, reason: "Order fulfilled")
      txn = stock.product_stock_transactions.last
      expect(txn.adjuster_id).to be_nil
    end
  end

  describe "#recalculate_checkpoint!" do
    it "recalculates amount from transactions and sets checkpoint" do
      stock.deposit!(amount: 100, reason: "In")
      stock.withdraw!(amount: 30, reason: "Out")
      # Manually corrupt amount to simulate discrepancy
      stock.update_columns(amount: 999) # rubocop:disable Rails/SkipsModelValidations
      stock.recalculate_checkpoint!
      expect(stock.reload.amount).to eq(70)
    end
  end

  describe "#reset_stock!" do
    before { stock.update!(amount: 50) }

    it "sets amount to 0 and creates an RS transaction" do
      adjuster = create(:user)
      result = stock.reset_stock!(reason: "End of period", adjuster: adjuster)
      expect(result).to eq(:ok)
      expect(stock.reload.amount).to eq(0)
      txn = stock.product_stock_transactions.last
      expect(txn.transaction_type).to eq("RS")
      expect(txn.amount).to eq(50)
      expect(txn.adjuster_id).to eq(adjuster.id)
    end

    it "returns :already_zero and creates no transaction when amount is 0" do
      stock.update!(amount: 0)
      expect do
        result = stock.reset_stock!(reason: "Test")
        expect(result).to eq(:already_zero)
      end.not_to change(ProductStockTransaction, :count)
    end
  end
end
