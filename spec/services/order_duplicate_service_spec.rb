# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDuplicateService, type: :service do
  let(:customer)  { create(:customer) }
  let(:product)   { create(:product, name: "Widget A") }
  let(:user)      { create(:user) }
  let(:source_order) do
    create(:order,
           customer: customer,
           status: "Pd",
           remark: "Original remark",
           internal_note: "Internal note")
  end
  let(:line1) { create(:order_line, order: source_order, product: product, quantity: 3, unit_price: 100) }
  let(:line2) { create(:order_line, order: source_order, product: product, quantity: 1, unit_price: 200) }

  before do
    Current.user = user
    source_order
    line1
    line2
  end

  subject(:service) { described_class.new(source_order, current_user: user) }

  describe "#call" do
    it "creates a new order" do
      expect { service.call }.to change(Order, :count).by(1)
    end

    it "sets status to Dr" do
      new_order = service.call
      expect(new_order.status).to eq("Dr")
    end

    it "sets running_date to today" do
      new_order = service.call
      expect(new_order.running_date).to eq(Date.today)
    end

    it "copies customer_id" do
      new_order = service.call
      expect(new_order.customer_id).to eq(source_order.customer_id)
    end

    it "copies remark and internal_note" do
      new_order = service.call
      expect(new_order.remark).to eq("Original remark")
      expect(new_order.internal_note).to eq("Internal note")
    end

    it "creates correct number of order lines" do
      new_order = service.call
      expect(new_order.order_lines.count).to eq(2)
    end

    it "copies order line fields" do
      new_order = service.call
      line = new_order.order_lines.first
      expect(line.product_id).to eq(product.id)
      expect(line.quantity).to eq(3).or eq(1)
    end

    it "does not copy order_images" do
      new_order = service.call
      expect(new_order.order_images.count).to eq(0)
    end

    it "generates a new order_number (different from source)" do
      new_order = service.call
      expect(new_order.order_number).not_to eq(source_order.order_number)
    end
  end
end
