class CreateBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :branches do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :branches, :name, unique: true
  end
end
