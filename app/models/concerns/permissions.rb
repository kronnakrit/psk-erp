# frozen_string_literal: true

module Permissions
  ALL = %w[
    view_users add_users change_users delete_users
    view_roles add_roles change_roles delete_roles
    view_invoices add_invoices change_invoices delete_invoices view_invoice_audit
    view_orders add_orders change_orders delete_orders
    view_order_lines add_order_lines change_order_lines delete_order_lines
    view_order_images add_order_images change_order_images delete_order_images
    view_purchase_orders add_purchase_orders change_purchase_orders delete_purchase_orders
    view_products add_products change_products delete_products
    view_product_classes add_product_classes change_product_classes delete_product_classes
    view_product_categories add_product_categories change_product_categories delete_product_categories
    view_product_attributes add_product_attributes change_product_attributes delete_product_attributes
    view_product_images add_product_images change_product_images delete_product_images
    view_vendors add_vendors change_vendors delete_vendors
    view_brands add_brands change_brands delete_brands
    view_attributes add_attributes change_attributes delete_attributes
    view_customers add_customers change_customers delete_customers
    view_suppliers add_suppliers change_suppliers delete_suppliers
    view_logistic_companies add_logistic_companies change_logistic_companies delete_logistic_companies
    view_branches add_branches change_branches delete_branches
    view_product_stocks add_product_stocks change_product_stocks delete_product_stocks
    view_uploads add_uploads change_uploads delete_uploads
    add_countries change_countries delete_countries
    manage_unit_groups
    change_company_settings
    can_view_cost see_sale_graph see_price_monitor view_order_audit
  ].freeze
end
