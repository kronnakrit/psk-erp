# frozen_string_literal: true

class ProductLot < ApplicationRecord
  STATUS_ACTIVE   = "active"
  STATUS_DEPLETED = "depleted"

  belongs_to :product
  belongs_to :purchase_order
  has_many :order_lines, dependent: :nullify # rubocop:disable Rails/HasManyOrHasOneDependent

  validates :lot_number,        presence: true, uniqueness: true
  validates :received_date,     presence: true
  validates :original_quantity, numericality: { greater_than: 0 }
  validates :remaining_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_cost,         numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(status: STATUS_ACTIVE) }
  scope :by_latest_received, -> { order(received_date: :desc, id: :desc) }

  after_save :update_status_if_depleted

  private

  def update_status_if_depleted
    if remaining_quantity.zero? && status != STATUS_DEPLETED
      update_column(:status, STATUS_DEPLETED) # rubocop:disable Rails/SkipsModelValidations
    elsif remaining_quantity.positive? && status == STATUS_DEPLETED
      update_column(:status, STATUS_ACTIVE) # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
