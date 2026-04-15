# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    default_scope -> { where(deleted_at: nil) }

    scope :active,       -> { where(deleted_at: nil) }
    scope :deleted,      -> { unscoped.where.not(deleted_at: nil) }
    scope :with_deleted, -> { unscoped }
  end

  def soft_delete!
    update_columns(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end

  def restore!
    update_columns(deleted_at: nil) # rubocop:disable Rails/SkipsModelValidations
  end

  def soft_deleted?
    deleted_at.present?
  end
end
