# frozen_string_literal: true

class OrderAudit < ApplicationRecord
  EVENT_TYPES = %w[field_update status_change line_added line_removed line_updated].freeze
  EXCLUDED_FIELDS = %w[updated_at updated_by_id total_price vat_price grand_total order_number created_by_id].freeze

  belongs_to :order
  belongs_to :changed_by, class_name: "User", optional: true

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
end
