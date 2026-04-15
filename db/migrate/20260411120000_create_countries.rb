class CreateCountries < ActiveRecord::Migration[8.1]
  def up
    create_table :countries, id: false, force: :cascade do |t|
      t.string :iso_3166_1_a2, limit: 2, null: false
      t.string :iso_3166_1_a3, limit: 3
      t.string :iso_3166_1_numeric, limit: 3
      t.string :printable_name, limit: 255
      t.string :name, limit: 255
    end

    execute "ALTER TABLE countries ADD PRIMARY KEY (iso_3166_1_a2);"
  end

  def down
    drop_table :countries
  end
end
