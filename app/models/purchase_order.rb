# frozen_string_literal: true

class PurchaseOrder < ApplicationRecord
  STATUSES = %w[Dr Cf Cc].freeze
  STATUS_LABELS = { "Dr" => "Draft", "Cf" => "Confirmed", "Cc" => "Cancelled" }.freeze

  belongs_to :supplier
  has_many :purchase_order_lines, dependent: :destroy
  has_many :product_lots, dependent: :nullify
  accepts_nested_attributes_for :purchase_order_lines, allow_destroy: true, reject_if: :all_blank

  validates :po_number, presence: true, uniqueness: true
  validates :po_date,   presence: true
  validates :status,    inclusion: { in: STATUSES }

  before_validation :generate_po_number, on: :create
  before_destroy    :prevent_destroy_if_confirmed

  scope :draft,     -> { where(status: "Dr") }
  scope :confirmed, -> { where(status: "Cf") }
  scope :cancelled, -> { where(status: "Cc") }

  def status_label
    STATUS_LABELS[status] || status
  end

  def draft?
    status == "Dr"
  end

  def confirmed?
    status == "Cf"
  end

  def cancelled?
    status == "Cc"
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[po_number po_date status supplier_id remark]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[supplier]
  end

  private

  def generate_po_number
    self.po_number ||= PurchaseOrderNumberGenerator.new(po_date || Time.zone.today).call
  end

  def prevent_destroy_if_confirmed
    return unless confirmed?

    errors.add(:base, "Cannot delete a confirmed purchase order")
    throw :abort
  end
end
