# frozen_string_literal: true

class Upload < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  belongs_to :user
  has_one_attached :file

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :file, presence: true

  def pending?    = status == "pending"
  def processing? = status == "processing"
  def completed?  = status == "completed"
  def failed?     = status == "failed"
end
