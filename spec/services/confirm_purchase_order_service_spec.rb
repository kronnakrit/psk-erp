# frozen_string_literal: true

require "rails_helper"

RSpec.describe ConfirmPurchaseOrderService do
  before { create(:branch, :main) }

  let(:unit_group) { create(:unit_group) }
  let(:unit_def)   { create(:unit_definition, unit_group: unit_group, ratio: 2) }
  let(:product)    { create(:product, unit_group: unit_group, enable_stock: true) }
  let(:po)         { create(:purchase_order) }

  def add_line(quantity: 5, unit_cost: 20.00)
    create(:purchase_order_line,
           purchase_order: po, product: product,
           unit_definition: unit_def, quantity: quantity, unit_cost: unit_cost)
  end

  describe "#call!" do
    context "with valid draft PO and lines" do
      before { add_line }

      it "creates one ProductLot per line" do
        expect { described_class.new(po).call! }.to change(ProductLot, :count).by(1)
      end

      it "sets lot attributes correctly" do # rubocop:disable RSpec/MultipleExpectations
        described_class.new(po).call!
        lot = ProductLot.last
        expect(lot.product).to eq(product)
        expect(lot.purchase_order).to eq(po)
        expect(lot.lot_number).to start_with("LOT-#{po.po_number}-")
        expect(lot.received_date).to eq(Date.current)
        expect(lot.original_quantity).to eq(10.0) # 5 qty * ratio 2
        expect(lot.remaining_quantity).to eq(10.0)
        expect(lot.unit_cost).to eq(20.00)
        expect(lot.status).to eq(ProductLot::STATUS_ACTIVE)
      end

      it "deposits stock for stock-enabled products" do
        described_class.new(po).call!
        stock = ProductStock.find_by(product: product)
        expect(stock).to be_present
        expect(stock.amount).to eq(10.0)
      end

      it "changes PO status to Cf" do
        described_class.new(po).call!
        expect(po.reload.status).to eq("Cf")
      end

      it "returns the count of lots created" do
        add_line
        count = described_class.new(po).call!
        expect(count).to eq(2)
      end
    end

    context "when PO has no lines" do
      it "raises Error" do
        expect { described_class.new(po).call! }
          .to raise_error(ConfirmPurchaseOrderService::Error, /no lines/)
      end
    end

    context "when PO is already confirmed" do
      before { po.update_columns(status: "Cf") } # rubocop:disable Rails/SkipsModelValidations

      it "raises Error" do
        expect { described_class.new(po).call! }
          .to raise_error(ConfirmPurchaseOrderService::Error, /already confirmed/)
      end
    end

    context "when PO is cancelled" do
      before { po.update_columns(status: "Cc") } # rubocop:disable Rails/SkipsModelValidations

      it "raises Error" do
        expect { described_class.new(po).call! }
          .to raise_error(ConfirmPurchaseOrderService::Error, /cancelled/)
      end
    end

    context "when lot creation fails (transaction rollback)" do
      before do
        add_line
        allow(ProductLot).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
      end

      it "does not change PO status" do
        begin
          described_class.new(po).call!
        rescue ActiveRecord::RecordInvalid
          nil
        end
        expect(po.reload.status).to eq("Dr")
      end
    end
  end
end
