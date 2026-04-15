class Country < ApplicationRecord
  self.primary_key = "iso_3166_1_a2"

  validates :iso_3166_1_a2, presence: true, uniqueness: { case_sensitive: false },
                            length: { is: 2 }
  validates :printable_name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[iso_3166_1_a2 iso_3166_1_a3 iso_3166_1_numeric printable_name name]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
