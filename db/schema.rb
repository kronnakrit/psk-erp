# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_25_163609) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "attributes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "product_class_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "product_class_id"], name: "index_attributes_on_name_and_product_class_id", unique: true
    t.index ["product_class_id"], name: "index_attributes_on_product_class_id"
  end

  create_table "branches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_branches_on_name", unique: true
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.text "remark"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_brands_on_name", unique: true
  end

  create_table "company_settings", force: :cascade do |t|
    t.text "company_address"
    t.string "company_email"
    t.string "company_name", default: "PSK ERP", null: false
    t.string "company_tax_id"
    t.string "company_telephone", limit: 20
    t.string "company_website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "countries", primary_key: "iso_3166_1_a2", id: { type: :string, limit: 2 }, force: :cascade do |t|
    t.string "iso_3166_1_a3", limit: 3
    t.string "iso_3166_1_numeric", limit: 3
    t.string "name", limit: 255
    t.string "printable_name", limit: 255
  end

  create_table "customers", force: :cascade do |t|
    t.text "address"
    t.string "country_id", limit: 2
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "first_name", null: false
    t.string "last_name"
    t.bigint "logistic_company_id"
    t.text "remark"
    t.string "telephone"
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_customers_on_country_id"
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["logistic_company_id"], name: "index_customers_on_logistic_company_id"
  end

  create_table "invoice_audits", force: :cascade do |t|
    t.datetime "changed_at", default: -> { "now()" }, null: false
    t.bigint "changed_by_id"
    t.string "event_type", limit: 20, null: false
    t.string "field_name", limit: 100
    t.bigint "invoice_id", null: false
    t.text "new_value"
    t.text "previous_value"
    t.index ["changed_by_id"], name: "index_invoice_audits_on_changed_by_id"
    t.index ["invoice_id", "changed_at"], name: "index_invoice_audits_on_invoice_id_and_changed_at"
    t.index ["invoice_id"], name: "index_invoice_audits_on_invoice_id"
  end

  create_table "invoice_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_images_on_invoice_id"
  end

  create_table "invoice_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "invoice_id", null: false
    t.bigint "order_id", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id", "order_id"], name: "index_invoice_orders_on_invoice_id_and_order_id", unique: true
    t.index ["invoice_id"], name: "index_invoice_orders_on_invoice_id"
    t.index ["order_id"], name: "index_invoice_orders_on_order_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "customer_id", null: false
    t.date "invoice_date", null: false
    t.string "invoice_number", limit: 20, null: false
    t.text "remark"
    t.string "status", limit: 2, default: "Dr", null: false
    t.decimal "total_amount", precision: 20, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["created_by_id"], name: "index_invoices_on_created_by_id"
    t.index ["customer_id"], name: "index_invoices_on_customer_id"
    t.index ["invoice_date"], name: "index_invoices_on_invoice_date"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["updated_by_id"], name: "index_invoices_on_updated_by_id"
  end

  create_table "logistic_companies", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.text "remark"
    t.string "telephone", limit: 255
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_logistic_companies_on_lower_name", unique: true
    t.index ["name"], name: "index_logistic_companies_on_name"
  end

  create_table "order_audits", force: :cascade do |t|
    t.datetime "changed_at", default: -> { "now()" }, null: false
    t.bigint "changed_by_id"
    t.string "event_type", limit: 20, null: false
    t.string "field_name", limit: 100
    t.text "new_value"
    t.bigint "order_id", null: false
    t.text "previous_value"
    t.index ["order_id", "changed_at"], name: "index_order_audits_on_order_id_and_changed_at"
    t.index ["order_id"], name: "index_order_audits_on_order_id"
  end

  create_table "order_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_images_on_order_id"
  end

  create_table "order_line_lot_allocations", force: :cascade do |t|
    t.decimal "allocated_quantity", precision: 8, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "order_line_id", null: false
    t.bigint "product_lot_id"
    t.decimal "unit_cost", precision: 20, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["order_line_id"], name: "index_order_line_lot_allocations_on_order_line_id"
    t.index ["product_lot_id"], name: "index_order_line_lot_allocations_on_product_lot_id"
  end

  create_table "order_lines", force: :cascade do |t|
    t.decimal "cogs", precision: 20, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.decimal "discount_price", precision: 20, scale: 2, default: "0.0", null: false
    t.integer "idx", default: 0
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.bigint "product_lot_id"
    t.decimal "quantity", precision: 8, scale: 2, null: false
    t.text "remark"
    t.decimal "total_price", precision: 20, scale: 2, null: false
    t.bigint "unit_definition_id", null: false
    t.decimal "unit_price", precision: 20, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_lines_on_order_id"
    t.index ["product_id"], name: "index_order_lines_on_product_id"
    t.index ["product_lot_id"], name: "index_order_lines_on_product_lot_id"
    t.index ["unit_definition_id"], name: "index_order_lines_on_unit_definition_id"
  end

  create_table "orders", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "customer_id", null: false
    t.decimal "discount_percentage", precision: 20, scale: 2, default: "0.0", null: false
    t.decimal "discount_price", precision: 20, scale: 2, default: "0.0", null: false
    t.decimal "grand_total", precision: 20, scale: 2, default: "0.0", null: false
    t.boolean "has_vat", default: false, null: false
    t.text "internal_note"
    t.boolean "is_discount_percentage", default: false, null: false
    t.boolean "is_included_vat", default: false, null: false
    t.boolean "is_possible_duplicate", default: false, null: false
    t.boolean "is_withholding_tax", default: true, null: false
    t.bigint "logistic_company_id"
    t.string "order_number", null: false
    t.text "remark"
    t.date "running_date", null: false
    t.bigint "salesperson_id"
    t.string "status", limit: 2, default: "Dr", null: false
    t.string "telephone", limit: 20
    t.decimal "total_price", precision: 20, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.decimal "vat_price", precision: 20, scale: 2, default: "0.0", null: false
    t.decimal "withholding_tax", precision: 20, scale: 2, default: "0.0", null: false
    t.index ["created_by_id"], name: "index_orders_on_created_by_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["is_possible_duplicate"], name: "idx_orders_is_possible_duplicate"
    t.index ["logistic_company_id"], name: "index_orders_on_logistic_company_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["running_date"], name: "index_orders_on_running_date"
    t.index ["salesperson_id"], name: "index_orders_on_salesperson_id"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["updated_by_id"], name: "index_orders_on_updated_by_id"
  end

  create_table "product_attributes", force: :cascade do |t|
    t.bigint "attribute_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["attribute_id"], name: "index_product_attributes_on_attribute_id"
    t.index ["product_id", "attribute_id"], name: "index_product_attributes_on_product_id_and_attribute_id", unique: true
    t.index ["product_id"], name: "index_product_attributes_on_product_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_product_categories_on_name", unique: true
  end

  create_table "product_category_products", id: false, force: :cascade do |t|
    t.bigint "product_category_id", null: false
    t.bigint "product_id", null: false
    t.index ["product_id", "product_category_id"], name: "idx_product_category_products_unique", unique: true
  end

  create_table "product_classes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_product_classes_on_name", unique: true
  end

  create_table "product_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_images_on_product_id"
  end

  create_table "product_lots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "lot_number", null: false
    t.decimal "original_quantity", precision: 12, scale: 2, null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_order_id", null: false
    t.date "received_date", null: false
    t.decimal "remaining_quantity", precision: 12, scale: 2, null: false
    t.string "status", default: "active", null: false
    t.decimal "unit_cost", precision: 20, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["lot_number"], name: "index_product_lots_on_lot_number", unique: true
    t.index ["product_id"], name: "index_product_lots_on_product_id"
    t.index ["purchase_order_id"], name: "index_product_lots_on_purchase_order_id"
    t.index ["received_date"], name: "index_product_lots_on_received_date"
    t.index ["status"], name: "index_product_lots_on_status"
  end

  create_table "product_stock_locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_stock_id", null: false
    t.bigint "stock_location_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_stock_id", "stock_location_id"], name: "index_product_stock_locations_unique_pair", unique: true
    t.index ["product_stock_id"], name: "index_product_stock_locations_on_product_stock_id"
    t.index ["stock_location_id"], name: "index_product_stock_locations_on_stock_location_id"
  end

  create_table "product_stock_transactions", force: :cascade do |t|
    t.bigint "adjuster_id"
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.bigint "product_stock_id", null: false
    t.string "reason", limit: 255
    t.decimal "recal_checkpoint", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "related_object_id"
    t.string "related_object_type"
    t.string "transaction_type", limit: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["adjuster_id"], name: "index_product_stock_transactions_on_adjuster_id"
    t.index ["product_stock_id"], name: "index_product_stock_transactions_on_product_stock_id"
    t.index ["related_object_type", "related_object_id"], name: "idx_on_related_object_type_related_object_id_e1aff0a56c"
    t.index ["transaction_type"], name: "index_product_stock_transactions_on_transaction_type"
  end

  create_table "product_stocks", force: :cascade do |t|
    t.decimal "amount", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "branch_id", null: false
    t.datetime "created_at", null: false
    t.decimal "holding_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "product_id", null: false
    t.bigint "stock_person_id"
    t.datetime "updated_at", null: false
    t.index ["branch_id", "product_id"], name: "index_product_stocks_on_branch_id_and_product_id", unique: true
    t.index ["branch_id"], name: "index_product_stocks_on_branch_id"
    t.index ["product_id"], name: "index_product_stocks_on_product_id"
    t.index ["stock_person_id"], name: "index_product_stocks_on_stock_person_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "barcode"
    t.bigint "brand_id"
    t.decimal "cost", precision: 20, scale: 2
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.text "description_th"
    t.boolean "enable_stock", default: false, null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.decimal "price", precision: 20, scale: 2
    t.bigint "product_class_id"
    t.string "product_type", limit: 2, null: false
    t.text "remark"
    t.string "sku", null: false
    t.string "unit"
    t.bigint "unit_group_id"
    t.datetime "updated_at", null: false
    t.bigint "vendor_id"
    t.index ["barcode"], name: "index_products_on_barcode"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["parent_id"], name: "index_products_on_parent_id"
    t.index ["product_class_id"], name: "index_products_on_product_class_id"
    t.index ["product_type"], name: "index_products_on_product_type"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["unit_group_id"], name: "index_products_on_unit_group_id"
    t.index ["vendor_id"], name: "index_products_on_vendor_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "preferred_locale", default: "th", null: false
    t.text "remark"
    t.bigint "role_id"
    t.string "telephone"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_profiles_on_role_id"
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
    t.check_constraint "preferred_locale::text = ANY (ARRAY['th'::character varying, 'en'::character varying]::text[])", name: "chk_profiles_preferred_locale"
  end

  create_table "purchase_order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.bigint "purchase_order_id", null: false
    t.decimal "quantity", precision: 8, scale: 2, null: false
    t.decimal "unit_cost", precision: 20, scale: 2, default: "0.0", null: false
    t.bigint "unit_definition_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_order_lines_on_product_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_lines_on_purchase_order_id"
    t.index ["unit_definition_id"], name: "index_purchase_order_lines_on_unit_definition_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "po_date", null: false
    t.string "po_number", null: false
    t.text "remark"
    t.string "status", limit: 2, default: "Dr", null: false
    t.bigint "supplier_id", null: false
    t.datetime "updated_at", null: false
    t.index ["po_date"], name: "index_purchase_orders_on_po_date"
    t.index ["po_number"], name: "index_purchase_orders_on_po_number", unique: true
    t.index ["status"], name: "index_purchase_orders_on_status"
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id"
    t.string "name", null: false
    t.string "permissions", default: [], array: true
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "stock_locations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_stock_locations_on_lower_name", unique: true
  end

  create_table "suppliers", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.text "remark"
    t.string "telephone"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_suppliers_on_name", unique: true
  end

  create_table "unit_definitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_main", default: false, null: false
    t.boolean "is_migration_placeholder", default: false, null: false
    t.string "name", null: false
    t.integer "ratio", null: false
    t.bigint "unit_group_id", null: false
    t.datetime "updated_at", null: false
    t.index ["unit_group_id", "name"], name: "index_unit_definitions_on_unit_group_id_and_name", unique: true
    t.index ["unit_group_id", "ratio"], name: "idx_unit_defs_on_group_and_ratio_1", unique: true, where: "((ratio = 1) AND (is_migration_placeholder = false))"
    t.index ["unit_group_id"], name: "idx_unit_defs_one_main_per_group", unique: true, where: "(is_main = true)"
    t.index ["unit_group_id"], name: "index_unit_definitions_on_unit_group_id"
    t.check_constraint "ratio > 0", name: "chk_unit_definitions_ratio_positive"
  end

  create_table "unit_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_unit_groups_on_name", unique: true
  end

  create_table "uploads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "result_summary", default: {}
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_uploads_on_status"
    t.index ["user_id"], name: "index_uploads_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_active", default: true, null: false
    t.string "jti", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.string "username", default: "", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "vendors", force: :cascade do |t|
    t.text "address"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "initial_name"
    t.string "name", null: false
    t.text "remark"
    t.string "telephone"
    t.datetime "updated_at", null: false
    t.index ["initial_name"], name: "index_vendors_on_initial_name", unique: true
    t.index ["name"], name: "index_vendors_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attributes", "product_classes"
  add_foreign_key "customers", "countries", primary_key: "iso_3166_1_a2", on_delete: :nullify
  add_foreign_key "customers", "logistic_companies", on_delete: :nullify
  add_foreign_key "invoice_audits", "invoices", on_delete: :cascade
  add_foreign_key "invoice_audits", "users", column: "changed_by_id", on_delete: :nullify
  add_foreign_key "invoice_images", "invoices", on_delete: :cascade
  add_foreign_key "invoice_orders", "invoices", on_delete: :cascade
  add_foreign_key "invoice_orders", "orders", on_delete: :restrict
  add_foreign_key "invoices", "customers"
  add_foreign_key "invoices", "users", column: "created_by_id"
  add_foreign_key "invoices", "users", column: "updated_by_id"
  add_foreign_key "order_audits", "orders", on_delete: :cascade
  add_foreign_key "order_audits", "users", column: "changed_by_id", on_delete: :nullify
  add_foreign_key "order_images", "orders", on_delete: :cascade
  add_foreign_key "order_line_lot_allocations", "order_lines"
  add_foreign_key "order_line_lot_allocations", "product_lots"
  add_foreign_key "order_lines", "orders", on_delete: :cascade
  add_foreign_key "order_lines", "product_lots"
  add_foreign_key "order_lines", "products", on_delete: :restrict
  add_foreign_key "order_lines", "unit_definitions", on_delete: :restrict
  add_foreign_key "orders", "customers", on_delete: :cascade
  add_foreign_key "orders", "logistic_companies", on_delete: :nullify
  add_foreign_key "orders", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "orders", "users", column: "salesperson_id"
  add_foreign_key "orders", "users", column: "updated_by_id", on_delete: :nullify
  add_foreign_key "product_attributes", "attributes"
  add_foreign_key "product_attributes", "products", on_delete: :cascade
  add_foreign_key "product_category_products", "product_categories", on_delete: :cascade
  add_foreign_key "product_category_products", "products", on_delete: :cascade
  add_foreign_key "product_images", "products", on_delete: :cascade
  add_foreign_key "product_lots", "products"
  add_foreign_key "product_lots", "purchase_orders"
  add_foreign_key "product_stock_locations", "product_stocks"
  add_foreign_key "product_stock_locations", "stock_locations"
  add_foreign_key "product_stock_transactions", "product_stocks", on_delete: :restrict
  add_foreign_key "product_stock_transactions", "users", column: "adjuster_id", on_delete: :nullify
  add_foreign_key "product_stocks", "branches", on_delete: :restrict
  add_foreign_key "product_stocks", "products", on_delete: :restrict
  add_foreign_key "product_stocks", "users", column: "stock_person_id"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "product_classes"
  add_foreign_key "products", "products", column: "parent_id"
  add_foreign_key "products", "unit_groups", on_delete: :restrict
  add_foreign_key "products", "vendors"
  add_foreign_key "profiles", "roles"
  add_foreign_key "profiles", "users"
  add_foreign_key "purchase_order_lines", "products"
  add_foreign_key "purchase_order_lines", "purchase_orders"
  add_foreign_key "purchase_order_lines", "unit_definitions"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "unit_definitions", "unit_groups"
  add_foreign_key "uploads", "users"
end
