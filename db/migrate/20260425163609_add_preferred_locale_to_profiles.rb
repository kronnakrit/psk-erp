class AddPreferredLocaleToProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :profiles, :preferred_locale, :string, null: false, default: "th"
    add_check_constraint :profiles, "preferred_locale IN ('th', 'en')",
                         name: "chk_profiles_preferred_locale"
  end
end
