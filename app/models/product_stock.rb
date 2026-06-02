# frozen_string_literal: true

class ProductStock < ApplicationRecord
  belongs_to :branch
  belongs_to :product
  belongs_to :stock_person, class_name: "User", optional: true
  has_many :product_stock_transactions, dependent: :destroy
  has_many :product_stock_locations, dependent: :destroy
  has_many :stock_locations, through: :product_stock_locations

  validates :branch_id, uniqueness: { scope: :product_id }
  validates :amount,         numericality: { greater_than_or_equal_to: 0 }
  validates :holding_amount, numericality: { greater_than_or_equal_to: 0 }

  # Returns the available (non-reserved) stock
  def total_amount
    amount - holding_amount
  end

  # Auto-creates a zero-stock record for a product+branch pair on first access
  def self.find_or_create_for!(product:, branch: Branch.default)
    find_or_create_by!(branch: branch, product: product)
  end

  # Adds stock and records an IB (in-bound) transaction
  def deposit!(amount:, reason: nil, related_object: nil, adjuster: nil)
    with_lock do
      increment!(:amount, amount) # rubocop:disable Rails/SkipsModelValidations
      create_transaction!(transaction_type: "IB", amount: amount, reason: reason, related_object: related_object,
                          adjuster: adjuster)
    end
  end

  # Removes stock and records an OB (out-bound) transaction
  def withdraw!(amount:, reason: nil, related_object: nil, adjuster: nil)
    with_lock do
      decrement!(:amount, amount) # rubocop:disable Rails/SkipsModelValidations
      create_transaction!(transaction_type: "OB", amount: amount, reason: reason, related_object: related_object,
                          adjuster: adjuster)
    end
  end

  # Decrements both amount and holding_amount (converts a hold into an actual withdrawal)
  def withdraw_from_holding!(amount:, reason: nil, related_object: nil)
    with_lock do
      decrement!(:amount,         amount) # rubocop:disable Rails/SkipsModelValidations
      decrement!(:holding_amount, amount) # rubocop:disable Rails/SkipsModelValidations
      create_transaction!(transaction_type: "OB", amount: amount, reason: reason, related_object: related_object)
    end
  end

  # Recalculates the running balance from the last checkpoint and updates amount
  def recalculate_checkpoint!
    with_lock do
      last_checkpoint_tx = product_stock_transactions
                           .where.not(recal_checkpoint: 0)
                           .order(created_at: :desc)
                           .first

      base = last_checkpoint_tx&.recal_checkpoint || 0
      since = last_checkpoint_tx&.created_at

      txns = since ? product_stock_transactions.where("created_at > ?", since) : product_stock_transactions.all
      txns = txns.order(:created_at)

      balance = txns.reduce(base) do |sum, txn|
        txn.transaction_type == "IB" ? sum + txn.amount : sum - txn.amount
      end

      update_columns(amount: balance) # rubocop:disable Rails/SkipsModelValidations
      txns.last&.update_columns(recal_checkpoint: balance) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[branch_id product_id amount holding_amount created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[branch product]
  end

  private

  def create_transaction!(transaction_type:, amount:, reason:, related_object: nil, adjuster: nil)
    product_stock_transactions.create!(
      transaction_type: transaction_type,
      amount: amount,
      reason: reason,
      related_object: related_object,
      adjuster: adjuster
    )
  end
end
