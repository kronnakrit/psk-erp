class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :email,    presence: true

  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile, update_only: true

  after_create :create_default_profile

  def active_for_authentication?
    super && is_active?
  end

  def inactive_message
    is_active? ? super : :account_inactive
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id email username is_active created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[profile]
  end

  def self.find_for_database_authentication(conditions)
    username_val = conditions[:username].to_s.strip
    find_by("lower(username) = lower(?)", username_val)
  end

  private

  def create_default_profile
    build_profile.save!
  end
end
