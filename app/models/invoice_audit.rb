# frozen_string_literal: true

class InvoiceAudit < ApplicationRecord
  EVENT_TYPES = %w[status_change field_update order_added order_removed].freeze

  belongs_to :invoice
  belongs_to :changed_by, class_name: "User", optional: true

  validates :event_type, inclusion: { in: EVENT_TYPES }
end
