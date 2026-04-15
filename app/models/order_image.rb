# frozen_string_literal: true

class OrderImage < ApplicationRecord
  include ImageCompressible

  belongs_to :order

  has_one_attached :image
  has_one_attached :thumb_image

  def self.ransackable_attributes(_auth_object = nil)
    %w[order_id position created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[order]
  end

  private

  def purge_attachments
    image.purge_later if image.attached?
    thumb_image.purge_later if thumb_image.attached?
  end
end
