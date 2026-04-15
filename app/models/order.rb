# frozen_string_literal: true

class Order < ApplicationRecord
  STATUSES = %w[Dr Pd Cp Cc].freeze
  LOGISTIC_STATUSES = %w[WTS ST HP TWH].freeze
  LOGISTIC_STATUS_LABELS = {
    "WTS" => "Wait to Send",
    "ST" => "Sent",
    "HP" => "Handpick",
    "TWH" => "To Warehouse"
  }.freeze

  belongs_to :customer
  belongs_to :logistic_company, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true
  has_many :order_lines,  dependent: :destroy
  has_many :order_images, dependent: :destroy
  has_many :order_audits, dependent: :destroy
  accepts_nested_attributes_for :order_lines, allow_destroy: true,
                                              reject_if: ->(attrs) { attrs[:product_id].blank? }

  validates :status,          inclusion: { in: STATUSES }
  validates :logistic_status, inclusion: { in: LOGISTIC_STATUSES }, allow_blank: true
  validates :order_number,    presence: true, uniqueness: true
  validates :running_date,    presence: true
  validate  :status_immutable_when_cancelled

  before_validation :set_running_date, on: :create
  before_validation :generate_order_number, on: :create
  before_save   :set_updated_by
  before_create :set_created_by
  after_update  :return_stock_on_cancellation
  after_update_commit :record_field_audits
  after_create_commit :enqueue_duplicate_check

  scope :draft,     -> { where(status: "Dr") }
  scope :paid,      -> { where(status: "Pd") }
  scope :completed, -> { where(status: "Cp") }
  scope :cancelled, -> { where(status: "Cc") }
  scope :for_date,  ->(date) { where(running_date: date) }

  def recalculate_grand_total!
    result = ::GrandTotalCalculator.new(self).call
    update_columns( # rubocop:disable Rails/SkipsModelValidations
      total_price: result[:total_price],
      vat_price: result[:vat_price],
      grand_total: result[:grand_total]
    )
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[order_number status logistic_status running_date customer_id
       logistic_company_id created_by_id updated_by_id
       has_vat is_discount_percentage is_withholding_tax
       total_price grand_total created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[customer logistic_company created_by updated_by]
  end

  private

  def set_running_date
    self.running_date ||= Time.zone.today
  end

  def generate_order_number
    self.order_number ||= ::OrderNumberGenerator.new(running_date).call
  end

  def set_created_by
    self.created_by ||= Current.user
  end

  def set_updated_by
    self.updated_by = Current.user
  end

  def status_immutable_when_cancelled
    return unless status_was == "Cc" && status_changed? && status != "Cc"

    errors.add(:base, "Cancelled orders cannot be re-activated.")
  end

  def return_stock_on_cancellation
    return unless saved_change_to_status? && status == "Cc" && status_before_last_save != "Cc"

    order_lines.includes(:product).find_each do |line|
      next unless line.product&.enable_stock?

      stock = ProductStock.find_or_create_for!(product: line.product)
      stock.deposit!(
        amount: line.quantity,
        reason: "Order #{order_number} cancelled",
        related_object: line
      )
    end
  end

  def record_field_audits
    return if (saved_changes.keys - OrderAudit::EXCLUDED_FIELDS).empty?

    OrderAuditService.new.call(order: self, changes: saved_changes, changed_by: Current.user)
  end

  def enqueue_duplicate_check
    MarkDuplicateOrdersJob.perform_later(id)
  end
end
