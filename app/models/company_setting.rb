# frozen_string_literal: true

class CompanySetting < ApplicationRecord
  PERMITTED_LOGO_CONTENT_TYPES = %w[image/png image/jpeg image/gif].freeze

  has_one_attached :logo

  validates :company_name, presence: true
  validate  :logo_must_be_image

  # Returns a (possibly unsaved) CompanySetting — safe for reads.
  def self.current
    find_or_initialize_by(id: 1)
  end

  # Returns a persisted CompanySetting — use when you need to save or render.
  def self.current!
    find_or_create_by!(id: 1) { |s| s.company_name = "PSK ERP" }
  end

  private

  def logo_must_be_image
    return unless logo.attached? && !logo.content_type.in?(PERMITTED_LOGO_CONTENT_TYPES)

    errors.add(:logo, :invalid_type, message: "must be an image file")
  end
end
