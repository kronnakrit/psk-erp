class ReplaceCustomerTelephoneWithTelephones < ActiveRecord::Migration[8.1]
  def up
    add_column :customers, :telephones, :jsonb, null: false, default: []

    execute <<~SQL.squish
      UPDATE customers
      SET telephones = jsonb_build_array(telephone)
      WHERE telephone IS NOT NULL AND telephone <> ''
    SQL

    remove_column :customers, :telephone
  end

  def down
    add_column :customers, :telephone, :string

    execute <<~SQL.squish
      UPDATE customers
      SET telephone = telephones->>0
      WHERE jsonb_array_length(telephones) > 0
    SQL

    remove_column :customers, :telephones
  end
end
