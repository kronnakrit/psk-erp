# frozen_string_literal: true

class InvoiceImage < ApplicationRecord
  include ImageCompressible

  belongs_to :invoice

  has_one_attached :image
  has_one_attached :thumb_image

  def self.ransackable_attributes(_auth_object = nil)
    %w[invoice_id position created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[invoice]
  end
end
