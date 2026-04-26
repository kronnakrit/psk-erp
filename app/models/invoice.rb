# frozen_string_literal: true

class Invoice < ApplicationRecord
  STATUSES = %w[Dr Pd Cc].freeze

  belongs_to :customer
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :invoice_orders,  dependent: :destroy
  has_many :orders,          through: :invoice_orders
  has_many :invoice_audits,  dependent: :destroy
  has_many :invoice_images,  dependent: :destroy

  validates :status,         inclusion: { in: STATUSES }
  validates :invoice_number, presence: true, uniqueness: true
  validates :invoice_date,   presence: true
  validate  :status_immutable_when_cancelled

  before_validation :generate_invoice_number, on: :create
  before_save       :set_updated_by
  before_create     :set_created_by
  after_update_commit :record_field_audits

  scope :draft,     -> { where(status: "Dr") }
  scope :paid,      -> { where(status: "Pd") }
  scope :cancelled, -> { where(status: "Cc") }

  def recalculate_total!
    update_columns( # rubocop:disable Rails/SkipsModelValidations
      total_amount: orders.sum(:grand_total)
    )
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[invoice_number status invoice_date customer_id
       created_by_id updated_by_id total_amount created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[customer created_by updated_by]
  end

  private

  def generate_invoice_number
    self.invoice_number ||= ::InvoiceNumberGenerator.new(invoice_date || Time.zone.today).call
  end

  def set_created_by
    self.created_by ||= Current.user
  end

  def set_updated_by
    self.updated_by = Current.user
  end

  def status_immutable_when_cancelled
    return unless persisted? && status_was == "Cc" && status_changed?

    errors.add(:status, :immutable_when_cancelled, message: "cannot be changed once cancelled")
  end

  def record_field_audits
    relevant = saved_changes.except("updated_at", "updated_by_id")
    return if relevant.blank?

    InvoiceAuditService.new.call(invoice: self, changes: relevant, changed_by: Current.user)
  end
end
