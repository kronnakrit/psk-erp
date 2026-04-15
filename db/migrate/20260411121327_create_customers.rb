class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers do |t|
      t.string :first_name, null: false
      t.string :last_name
      t.text :address
      t.text :remark
      t.string :telephone
      t.string :country_id, limit: 2
      t.bigint :logistic_company_id
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :customers, :country_id
    add_index :customers, :logistic_company_id
    add_index :customers, :deleted_at

    add_foreign_key :customers, :countries, primary_key: :iso_3166_1_a2,
                                            column: :country_id, on_delete: :nullify
    add_foreign_key :customers, :logistic_companies, column: :logistic_company_id,
                                                     on_delete: :nullify
  end
end
