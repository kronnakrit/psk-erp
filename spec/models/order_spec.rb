# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order, type: :model do
  subject(:order) { build(:order) }

  describe "validations" do
    it { is_expected.to belong_to(:customer) }
    it { is_expected.to have_many(:order_lines).dependent(:destroy) }
    it { is_expected.to have_many(:order_images).dependent(:destroy) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Order::STATUSES) }

    context "status inclusion" do
      it "is valid with each allowed status" do
        Order::STATUSES.each do |s|
          order.status = s
          expect(order).to be_valid, "Expected #{s} to be valid"
        end
      end

      it "is invalid with an unknown status" do
        order.status = "XX"
        expect(order).not_to be_valid
      end
    end
  end

  describe "callbacks" do
    describe "#set_running_date" do
      it "defaults running_date to today when not provided" do
        order = build(:order, running_date: nil)
        order.valid?
        expect(order.running_date).to eq(Time.zone.today)
      end

      it "does not overwrite an explicitly provided running_date" do
        date  = Date.new(2024, 6, 15)
        order = build(:order, running_date: date)
        order.valid?
        expect(order.running_date).to eq(date)
      end
    end

    describe "#generate_order_number" do
      it "assigns a YYYYMMDD### order number before create" do
        order = create(:order)
        expect(order.order_number).to match(/\A\d{8}\d{3}\z/)
      end

      it "does not overwrite an existing order_number" do
        order = create(:order)
        original = order.order_number
        order.update!(status: "Pd")
        expect(order.order_number).to eq(original)
      end
    end

    describe "#set_created_by / #set_updated_by" do
      it "sets created_by from Current.user on create when not provided" do
        user = create(:user)
        Current.user = user
        # Build order without the factory's created_by so the callback fires
        order = build(:order, created_by: nil)
        order.save!
        expect(order.created_by).to eq(user)
        Current.user = nil
      end
    end
  end

  describe "scopes" do
    let!(:draft)     { create(:order) }
    let!(:paid)      { create(:order, :paid) }
    let!(:completed) { create(:order, :completed) }
    let!(:cancelled) { create(:order, :cancelled) }

    it { expect(described_class.draft).to     include(draft) }
    it { expect(described_class.paid).to      include(paid) }
    it { expect(described_class.completed).to include(completed) }
    it { expect(described_class.cancelled).to include(cancelled) }
    it { expect(described_class.draft).not_to include(paid) }

    describe ".for_date" do
      it "returns orders with the given running_date" do
        today_order = create(:order, running_date: Time.zone.today)
        old_order   = create(:order, running_date: Time.zone.today - 1)
        expect(described_class.for_date(Time.zone.today)).to include(today_order)
        expect(described_class.for_date(Time.zone.today)).not_to include(old_order)
      end
    end
  end

  describe "#recalculate_grand_total!" do
    it "updates grand_total based on GrandTotalCalculator" do
      order = create(:order)
      calc_result = {
        total_price: BigDecimal("500"),
        vat_price: BigDecimal("35"),
        grand_total: BigDecimal("535")
      }
      allow(GrandTotalCalculator).to receive_message_chain(:new, :call).and_return(calc_result)
      order.recalculate_grand_total!
      expect(order.reload.grand_total.to_f).to eq(535.0)
    end
  end

  describe "LOGISTIC_STATUS_LABELS" do
    it "maps all four logistic status codes to human-readable labels" do
      expect(described_class::LOGISTIC_STATUS_LABELS).to include(
        "WTS" => "Wait to Send",
        "ST"  => "Sent",
        "HP"  => "Handpick",
        "TWH" => "To Warehouse"
      )
    end

    it "covers all LOGISTIC_STATUSES" do
      expect(described_class::LOGISTIC_STATUS_LABELS.keys).to match_array(described_class::LOGISTIC_STATUSES)
    end
  end

  describe "cancelled order immutability" do
    let(:branch) { create(:branch, :main) }
    let!(:cancelled_order) { create(:order, :cancelled) }

    it "prevents changing status away from Cc" do
      cancelled_order.status = "Dr"
      expect(cancelled_order).not_to be_valid
      expect(cancelled_order.errors[:base]).to include("Cancelled orders cannot be re-activated.")
    end

    it "allows keeping status as Cc" do
      cancelled_order.status = "Cc"
      expect(cancelled_order).to be_valid
    end

    %w[Pd Cp Dr].each do |s|
      it "rejects transition to #{s}" do
        cancelled_order.status = s
        expect(cancelled_order).not_to be_valid
      end
    end
  end

  describe "#return_stock_on_cancellation" do
    let(:branch) { create(:branch, :main) }
    let(:stock_product) { create(:product, enable_stock: true) }
    let(:non_stock_product) { create(:product, enable_stock: false) }
    let!(:stock) do
      create(:product_stock, product: stock_product, branch: branch, amount: 100)
    end
    let!(:draft_order) { create(:order, status: "Dr") }

    it "deposits stock for stock-enabled order lines when order is cancelled" do
      create(:order_line, order: draft_order, product: stock_product, quantity: 5)
      amount_before_cancel = stock.reload.amount
      draft_order.update!(status: "Cc")
      expect(stock.reload.amount).to eq(amount_before_cancel + 5)
      txn = stock.product_stock_transactions.where(transaction_type: "IB").last
      expect(txn&.reason).to include(draft_order.order_number)
    end

    it "does not deposit for non-stock products" do
      create(:order_line, order: draft_order, product: non_stock_product, quantity: 3)
      expect do
        draft_order.update!(status: "Cc")
      end.not_to change { stock.reload.product_stock_transactions.count }
    end

    it "does not double-deposit when already cancelled" do
      draft_order.update!(status: "Cc")
      original_count = ProductStockTransaction.count
      draft_order.update!(status: "Cc")
      expect(ProductStockTransaction.count).to eq(original_count)
    end
  end

  describe "after_create_commit :enqueue_duplicate_check" do
    it "enqueues MarkDuplicateOrdersJob with the order id after creation" do
      expect do
        create(:order)
      end.to have_enqueued_job(MarkDuplicateOrdersJob)
    end
  end
end
