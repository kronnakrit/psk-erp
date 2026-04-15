class CreateLogisticCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :logistic_companies do |t|
      t.string :name, null: false
      t.text :address
      t.text :remark
      t.string :telephone, limit: 255

      t.timestamps
    end

    add_index :logistic_companies, :name
  end
end
