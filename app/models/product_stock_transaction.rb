# frozen_string_literal: true

class ProductStockTransaction < ApplicationRecord
  TYPES = %w[IB OB RS].freeze

  belongs_to :product_stock
  belongs_to :adjuster, class_name: "User", optional: true
  belongs_to :related_object, polymorphic: true, optional: true

  validates :transaction_type, presence: true, inclusion: { in: TYPES }
  validates :amount,           presence: true, numericality: { greater_than: 0 }
  validates :reason,           length: { maximum: 255 }, allow_blank: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[transaction_type amount reason recal_checkpoint created_at product_stock_id adjuster_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[product_stock]
  end
end
