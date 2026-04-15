class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :role, null: true, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.text :address
      t.text :remark
      t.string :telephone

      t.timestamps
    end
  end
end
