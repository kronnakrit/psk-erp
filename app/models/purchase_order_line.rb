# frozen_string_literal: true

class PurchaseOrderLine < ApplicationRecord
  belongs_to :purchase_order
  belongs_to :product
  belongs_to :unit_definition

  validates :quantity,  numericality: { greater_than: 0 }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }

  validate :unit_definition_belongs_to_product_group, if: -> { unit_definition.present? && product.present? }

  after_commit :recalc_po_total

  def line_total
    (quantity * unit_cost).round(2)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[purchase_order_id product_id quantity unit_cost]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[purchase_order product unit_definition]
  end

  private

  def unit_definition_belongs_to_product_group
    group = product.effective_unit_group
    return if group.nil?
    return if unit_definition.unit_group_id == group.id

    errors.add(:unit_definition, "Invalid unit for this product.")
  end

  def recalc_po_total
    # Placeholder: PO total will be calculated and stored in STORY-16-04
    # when we have confirmed lots. For now just touch the PO to invalidate caches.
    purchase_order.touch # rubocop:disable Rails/SkipsModelValidations
  end
end
