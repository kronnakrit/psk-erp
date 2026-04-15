class CreateUploads < ActiveRecord::Migration[8.1]
  def change
    create_table :uploads do |t|
      t.string :status, null: false, default: "pending"
      t.jsonb :result_summary, default: {}
      t.bigint :user_id, null: false

      t.timestamps
    end

    add_index :uploads, :user_id
    add_index :uploads, :status
    add_foreign_key :uploads, :users
  end
end
