# frozen_string_literal: true

class ProductImage < ApplicationRecord
  include ImageCompressible

  belongs_to :product

  has_one_attached :image
  has_one_attached :thumb_image

  after_destroy :purge_attachments

  def self.ransackable_attributes(_auth_object = nil)
    %w[product_id position created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[product]
  end

  private

  def purge_attachments
    image.purge_later if image.attached?
    thumb_image.purge_later if thumb_image.attached?
  end
end
