class Customer < ApplicationRecord
  include SoftDeletable
  include TelephonesCoercible

  belongs_to :country, optional: true, primary_key: :iso_3166_1_a2
  belongs_to :logistic_company, optional: true

  attribute :telephones, :json, default: -> { [] }

  before_validation :normalize_telephones
  before_save { self.country_id = nil if country_id.blank? }

  validates :first_name, presence: true

  def fullname
    last_name.blank? ? first_name : "#{first_name} #{last_name}"
  end

  # Alias kept for backward compatibility
  alias get_fullname fullname

  # Primary phone — used by order autofill and legacy callers
  def telephone
    telephones_list.first
  end

  def telephones_list
    coerce_telephones(self[:telephones])
  end

  def telephones_display
    telephones_list.join(", ")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[first_name last_name address remark telephones telephone]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[logistic_company]
  end

  ransacker :telephone do
    Arel.sql("telephones::text")
  end

  private

  def normalize_telephones
    self.telephones = coerce_telephones(self[:telephones])
  end
end
