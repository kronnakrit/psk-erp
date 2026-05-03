# frozen_string_literal: true

class OrderImage < ApplicationRecord
  include ImageCompressible

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze

  belongs_to :order

  has_one_attached :image
  has_one_attached :thumb_image

  validate :image_content_type

  def self.ransackable_attributes(_auth_object = nil)
    %w[order_id position created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[order]
  end

  private

  def image_content_type
    return unless image.attached?

    unless ALLOWED_CONTENT_TYPES.include?(image.blob.content_type)
      errors.add(:image, "must be JPEG, PNG, WebP, or GIF")
    end
  end

  def purge_attachments
    image.purge_later if image.attached?
    thumb_image.purge_later if thumb_image.attached?
  end
end
