# frozen_string_literal: true

module Products
  class DuplicateService
    COPIED_ATTRS = %w[
      product_type price cost unit enable_stock description description_th remark
      vendor_id brand_id product_class_id unit_group_id
    ].freeze

    def initialize(product)
      @product = product
    end

    def call
      copy = Product.new
      COPIED_ATTRS.each { |attr| copy.public_send(:"#{attr}=", @product.public_send(attr)) }
      copy.name        = "Copy of #{@product.name}"
      copy.parent_id   = nil
      # SKU and barcode are auto-generated in before_validation callbacks
      copy
    end
  end
end
