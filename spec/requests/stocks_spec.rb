# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stocks", type: :request do
  let(:admin_role) do
    create(:role, permissions: %w[view_product_stocks change_product_stocks])
  end
  let(:user)    { create(:user) }
  let(:branch)  { create(:branch, :main) }
  let(:product) { create(:product) }
  let!(:stock)  { create(:product_stock, branch: branch, product: product, amount: 100) }

  before do
    user.profile.update!(role: admin_role)
    sign_in user
  end

  describe "GET /stocks" do
    it "returns 200" do
      get stocks_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /stocks/:id" do
    it "returns 200" do
      get stock_path(stock)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /stocks/:id/deposit" do
    it "deposits stock and redirects" do
      post deposit_stock_path(stock), params: { amount: "50", reason: "Purchase order" }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.amount).to eq(150)
    end

    it "rejects zero amount" do
      post deposit_stock_path(stock), params: { amount: "0" }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.amount).to eq(100)
    end

    it "records adjuster_id as current_user.id" do
      post deposit_stock_path(stock), params: { amount: "10", reason: "In" }
      txn = stock.product_stock_transactions.last
      expect(txn.adjuster_id).to eq(user.id)
    end
  end

  describe "POST /stocks/:id/withdraw" do
    it "withdraws stock and redirects" do
      post withdraw_stock_path(stock), params: { amount: "20", reason: "Sale" }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.amount).to eq(80)
    end
  end

  describe "POST /stocks/:id/recalculate_checkpoint" do
    it "recalculates and redirects" do
      stock.deposit!(amount: 10, reason: "In")
      post recalculate_checkpoint_stock_path(stock)
      expect(response).to redirect_to(stock_path(stock))
    end
  end

  describe "GET /stocks/:id/transactions" do
    it "returns 200" do
      stock.deposit!(amount: 10, reason: "Test")
      get transactions_stock_path(stock)
      expect(response).to have_http_status(:ok)
    end

    it "lists transactions" do
      stock.deposit!(amount: 25, reason: "Delivery")
      get transactions_stock_path(stock)
      expect(response.body).to include("Delivery")
    end
  end

  describe "GET /stocks with search filters" do
    let(:other_branch) { create(:branch, name: "Other Branch") }
    let(:other_product) { create(:product, name: "Widget XYZ") }
    let!(:other_stock) { create(:product_stock, branch: other_branch, product: other_product) }

    it "filters by product name" do
      get stocks_path, params: { q: { product_name_or_product_sku_cont: product.name } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product.name)
    end

    it "filters by branch_id" do
      get stocks_path, params: { q: { branch_id_eq: branch.id } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product.name)
    end

    it "filters by product_id_eq" do
      get stocks_path, params: { q: { product_id_eq: product.id } }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(product.name)
      expect(response.body).not_to include(other_product.name)
    end
  end

end
