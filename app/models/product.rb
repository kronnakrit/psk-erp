# frozen_string_literal: true

class Product < ApplicationRecord
  include SoftDeletable

  PRODUCT_TYPES = %w[Sa Pr Ch].freeze

  belongs_to :vendor,        optional: true
  belongs_to :brand,         optional: true
  belongs_to :product_class, optional: true
  belongs_to :unit_group,    optional: true
  belongs_to :parent, class_name: "Product", optional: true, inverse_of: :children
  has_many :children, class_name: "Product", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :product_attributes, dependent: :destroy
  accepts_nested_attributes_for :product_attributes, allow_destroy: true, reject_if: :all_blank
  has_many :product_images,     dependent: :destroy
  has_many :product_stocks,     dependent: :destroy
  has_many :order_lines,        dependent: :restrict_with_error
  has_many :product_lots,       dependent: :destroy
  has_and_belongs_to_many :product_categories, # rubocop:disable Rails/HasAndBelongsToMany
                          join_table: :product_category_products

  has_one_attached :featured_image

  validates :name,         presence: true
  validates :product_type, presence: true, inclusion: { in: PRODUCT_TYPES }
  validates :sku,          presence: true, uniqueness: true

  before_validation :auto_generate_sku,     on: :create
  before_validation :auto_generate_barcode, on: :create
  validate :unique_name_for_non_child

  def self.ransackable_attributes(_auth_object = nil)
    %w[name sku barcode product_type price cost remark description description_th
       vendor_id brand_id product_class_id unit_group_id enable_stock deleted_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[vendor brand product_class product_categories]
  end

  # Returns the most recent unit_price from order lines for a given product/customer combo.
  # Falls back to product.price when no order line exists.
  def self.last_price_for(product_id:, customer_id:)
    product = find(product_id)
    # OrderLine model will be introduced in EPIC-06; guard with a check
    if defined?(OrderLine)
      last_line = OrderLine
                  .joins(:order)
                  .where(product_id: product_id, orders: { customer_id: customer_id })
                  .order("orders.running_date DESC")
                  .first
      last_line&.unit_price || product.price
    else
      product.price
    end
  end

  # Returns the most recent unit_price for a product/customer pair, or nil if no prior order exists.
  def self.last_selling_price_for(product_id:, customer_id:)
    return nil unless defined?(OrderLine)

    OrderLine
      .joins(:order)
      .where(product_id: product_id, orders: { customer_id: customer_id })
      .order("orders.running_date DESC")
      .first
      &.unit_price
  end

  # Total available stock across all branches (amount - holding_amount)
  def total_stock
    product_stocks.sum { |s| s.amount - s.holding_amount }
  end

  # Returns the product's own unit_group, or the system default UnitGroup if none is set.
  def effective_unit_group
    unit_group || UnitGroup.find_by(is_default: true)
  end

  private

  def auto_generate_sku
    return if sku.present?

    prefix = vendor&.initial_name.presence || "SKU"
    self.sku = "#{prefix}#{Time.now.to_i}#{SecureRandom.hex(3)}"
  end

  def auto_generate_barcode
    self.barcode = "#{Time.now.to_i}#{SecureRandom.hex(3)}" if barcode.blank?
  end

  def unique_name_for_non_child
    return if product_type == "Ch"

    # Exclude self from check on update
    scope = Product.where(name: name).where.not(product_type: "Ch")
    scope = scope.where.not(id: id) if persisted?
    errors.add(:name, "has already been taken") if scope.exists?
  end
end
