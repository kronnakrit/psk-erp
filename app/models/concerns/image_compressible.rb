# frozen_string_literal: true

module ImageCompressible
  extend ActiveSupport::Concern

  included do
    after_create :generate_thumbnail
  end

  private

  def generate_thumbnail
    return unless image.attached?

    # Download the quality-20 variant and attach it as thumb_image
    variant_content = image.variant(quality: 20).processed.download
    thumb_image.attach(
      io: StringIO.new(variant_content),
      filename: "thumb_#{image.filename}",
      content_type: image.content_type
    )
  rescue StandardError => e
    Rails.logger.warn("[ImageCompressible] Thumbnail generation failed: #{e.message}")
  end
end
