# frozen_string_literal: true

class OrderLine < ApplicationRecord
  UNITS = %w[Dz Pc Pa Se Ct].freeze
  UNIT_DISPLAY_LABELS = {
    "Dz" => "โหล",
    "Pc" => "ชิ้น",
    "Pa" => "คู่",
    "Se" => "ชุด",
    "Ct" => "กล่อง"
  }.freeze

  # Virtual attribute so forms can still use :unit while the column is gone
  attribute :unit, :string

  belongs_to :order
  belongs_to :product

  validates :quantity,   presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit,       inclusion: { in: UNITS }

  before_validation :calculate_total_price

  after_create :handle_stock_on_create
  after_update :handle_stock_on_update
  before_destroy :handle_stock_on_destroy
  before_destroy :capture_line_snapshot
  after_commit :recalc_order_grand_total, on: %i[create update destroy]

  after_create_commit  :record_line_added
  after_destroy_commit :record_line_removed
  after_update_commit  :record_line_updates
  after_commit :enqueue_parent_order_duplicate_check, on: %i[create destroy]

  def self.ransackable_attributes(_auth_object = nil)
    %w[order_id product_id unit quantity unit_price discount_price total_price idx created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[order product]
  end

  private

  def calculate_total_price
    return unless quantity.present? && unit_price.present?

    self.total_price = (quantity * unit_price) - (discount_price || 0)
  end

  def recalc_order_grand_total
    order.recalculate_grand_total!
  end

  # Stock integration callbacks

  def handle_stock_on_create
    return unless product.enable_stock?

    stock = ProductStock.find_or_create_for!(product: product)
    stock.withdraw!(amount: quantity, reason: "Order #{order.order_number}", related_object: self)
  end

  def handle_stock_on_update
    return unless product.enable_stock?
    return unless saved_change_to_quantity?

    previous_qty = quantity_before_last_save
    stock = ProductStock.find_or_create_for!(product: product)
    stock.deposit!(amount: previous_qty, reason: "Order line update (reverse)", related_object: self)
    stock.withdraw!(amount: quantity, reason: "Order line update (restock)", related_object: self)
  end

  def handle_stock_on_destroy
    return unless product.enable_stock?

    stock = ProductStock.find_or_create_for!(product: product)
    stock.deposit!(amount: quantity, reason: "Order line deleted (reversal)", related_object: self)
  end

  def record_line_added
    order.order_audits.create!(
      event_type: "line_added",
      changed_by: Current.user,
      new_value: { product_id: product_id, product_name: product.name,
                   quantity: quantity, unit_price: unit_price }.to_json,
      changed_at: Time.current
    )
  end

  def capture_line_snapshot
    @line_snapshot = {
      product_id: product_id,
      product_name: product.name,
      quantity: quantity,
      unit_price: unit_price
    }
  end

  def record_line_removed
    order.order_audits.create!(
      event_type: "line_removed",
      changed_by: Current.user,
      previous_value: @line_snapshot.to_json,
      changed_at: Time.current
    )
  end

  def record_line_updates
    %w[quantity unit_price unit discount_price].each do |field|
      next unless public_send(:"saved_change_to_#{field}?")

      prev_val, new_val = public_send(:"saved_change_to_#{field}")
      order.order_audits.create!(
        event_type: "line_updated",
        field_name: field,
        previous_value: prev_val.to_s,
        new_value: new_val.to_s,
        changed_by: Current.user,
        changed_at: Time.current
      )
    end
  end

  def enqueue_parent_order_duplicate_check
    MarkDuplicateOrdersJob.perform_later(order_id)
  end
end
