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
  let!(:lot) do
    create(:product_lot, product: product, remaining_quantity: 80, original_quantity: 80)
  end

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
    it "deposits stock and lot remaining_quantity" do
      post deposit_stock_path(stock),
           params: { amount: "50", reason: "Purchase order", product_lot_id: lot.id }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.amount).to eq(150)
      expect(lot.reload.remaining_quantity).to eq(130)
    end

    it "rejects zero amount" do
      post deposit_stock_path(stock), params: { amount: "0", product_lot_id: lot.id }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.amount).to eq(100)
      expect(lot.reload.remaining_quantity).to eq(80)
    end

    it "rejects missing product_lot_id" do
      post deposit_stock_path(stock), params: { amount: "10" }
      expect(response).to redirect_to(stock_path(stock))
      follow_redirect!
      expect(response.body).to include(I18n.t("stocks.adjustment.lot_required"))
    end

    it "records adjuster_id and links transaction to lot" do
      post deposit_stock_path(stock),
           params: { amount: "10", reason: "In", product_lot_id: lot.id }
      txn = stock.product_stock_transactions.last
      expect(txn.adjuster_id).to eq(user.id)
      expect(txn.related_object).to eq(lot)
    end

    context "when product has no lots" do
      before { lot.destroy! }

      it "redirects with no lots message" do
        post deposit_stock_path(stock), params: { amount: "10", product_lot_id: 1 }
        follow_redirect!
        expect(response.body).to include(I18n.t("stocks.adjustment.no_lots_available"))
      end
    end
  end

  describe "POST /stocks/:id/withdraw" do
    it "withdraws stock and lot remaining_quantity" do
      post withdraw_stock_path(stock),
           params: { amount: "20", reason: "Sale", product_lot_id: lot.id }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.amount).to eq(80)
      expect(lot.reload.remaining_quantity).to eq(60)
    end

    it "rejects withdraw exceeding lot remaining_quantity" do
      post withdraw_stock_path(stock),
           params: { amount: "81", product_lot_id: lot.id }
      expect(response).to redirect_to(stock_path(stock))
      expect(stock.reload.amount).to eq(100)
      expect(lot.reload.remaining_quantity).to eq(80)
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

    it "shows linked lot information when transaction has a product lot" do
      lot = create(:product_lot, product: product)
      stock.deposit!(amount: 10, reason: "Lot deposit", related_object: lot)

      get transactions_stock_path(stock)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(lot.lot_number)
      expect(response.body).to include(lot.purchase_order.po_number)
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
