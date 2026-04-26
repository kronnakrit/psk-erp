# frozen_string_literal: true

class CreateCompanySettings < ActiveRecord::Migration[8.0]
  def change
    create_table :company_settings do |t|
      t.string  :company_name,      null: false, default: "PSK ERP"
      t.text    :company_address
      t.string  :company_telephone, limit: 20
      t.string  :company_tax_id
      t.string  :company_email
      t.string  :company_website
      t.timestamps
    end
  end
end
