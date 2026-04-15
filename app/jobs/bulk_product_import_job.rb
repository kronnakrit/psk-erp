# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class BulkProductImportJob < ApplicationJob
  queue_as :imports

  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
  def perform(upload_id)
    upload = Upload.find_by(id: upload_id)
    return unless upload

    upload.update!(status: "processing")

    rows_processed = 0
    rows_failed    = 0
    errors         = []

    begin
      file = upload.file
      raise ArgumentError, "No file attached" unless file.attached?

      tmp = Tempfile.new(["import", ".xlsx"])
      tmp.binmode
      tmp.write(file.download)
      tmp.rewind

      spreadsheet = Roo::Spreadsheet.open(tmp.path)

      spreadsheet.sheets.each do |sheet_name|
        product_class = ProductClass.find_or_create_by!(name: sheet_name)
        sheet         = spreadsheet.sheet(sheet_name)
        headers       = sheet.row(1).map { |h| h.to_s.strip.downcase }

        last_parent = nil

        (2..sheet.last_row).each do |row_idx|
          row  = sheet.row(row_idx)
          data = headers.zip(row).to_h

          next if data.values.all?(&:blank?)

          result = import_row(data: data, product_class: product_class, last_parent: last_parent)

          if result[:error]
            rows_failed += 1
            errors << "Sheet '#{sheet_name}' row #{row_idx}: #{result[:error]}"
          else
            rows_processed += 1
            last_parent = result[:product] if result[:product]&.product_type.in?(%w[Pr Sa])
          end
        rescue StandardError => e
          rows_failed += 1
          errors << "Sheet '#{sheet_name}' row #{row_idx}: #{e.message}"
        end
      end

      upload.update!(
        status: "completed",
        result_summary: { rows_processed: rows_processed, rows_failed: rows_failed, errors: errors }
      )
    rescue StandardError => e
      upload.update!(
        status: "failed",
        result_summary: { rows_processed: rows_processed, rows_failed: rows_failed,
                          errors: errors + ["Fatal: #{e.message}"] }
      )
    ensure
      tmp&.close
      tmp&.unlink
    end

    broadcast_result(upload)
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

  private

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def import_row(data:, product_class:, last_parent:)
    product_type = data["product_type"].to_s.strip
    return { error: "Unknown product_type '#{product_type}'" } unless product_type.in?(%w[Sa Pr Ch])

    vendor  = upsert_vendor(data["vendor"].to_s.strip)
    brand   = upsert_brand(data["brand"].to_s.strip)
    sku     = data["sku"].to_s.strip
    name    = data["name"].to_s.strip
    price   = data["price"].to_f
    cost    = data["cost"].to_f

    if product_type == "Ch"
      return { error: "No parent product found for child row" } unless last_parent

      product = find_or_initialize_product(sku: sku, product_type: "Ch")
      product.assign_attributes(
        sku: sku.presence,
        name: name.presence || "Child of #{last_parent.name}",
        price: price,
        cost: cost,
        barcode: data["barcode"].to_s.strip.presence,
        unit: data["unit"].to_s.strip.presence,
        description: data["description_en"].to_s.strip,
        description_th: data["description_th"].to_s.strip,
        parent: last_parent,
        vendor: last_parent.vendor,
        brand: last_parent.brand,
        product_class: last_parent.product_class
      )
    else
      product = find_or_initialize_product(sku: sku, product_type: product_type)
      product.assign_attributes(
        sku: sku.presence,
        name: name,
        price: price,
        cost: cost,
        barcode: data["barcode"].to_s.strip.presence,
        unit: data["unit"].to_s.strip.presence,
        description: data["description_en"].to_s.strip,
        description_th: data["description_th"].to_s.strip,
        vendor: vendor,
        brand: brand,
        product_class: product_class
      )
    end

    return { error: product.errors.full_messages.join(", ") } unless product.save

    product.product_categories = upsert_categories(data["product_categories"].to_s) unless product_type == "Ch"

    upsert_product_attributes(product: product, data: data, product_class: product_class)

    { product: product }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def find_or_initialize_product(sku:, product_type:)
    product = sku.present? ? Product.find_by(sku: sku) : nil
    product ||= Product.new(product_type: product_type)
    product.product_type = product_type
    product
  end

  def upsert_vendor(name)
    name.present? ? Vendor.find_or_create_by!(name: name) : nil
  end

  def upsert_brand(name)
    name.present? ? Brand.find_or_create_by!(name: name) : nil
  end

  def upsert_categories(raw)
    raw.split(",").map(&:strip).compact_blank.map do |cat_name|
      ProductCategory.find_or_create_by!(name: cat_name)
    end
  end

  def upsert_product_attributes(product:, data:, product_class:)
    data.each do |col_key, value|
      next unless col_key.to_s.start_with?("attr")

      attr_name = col_key.sub(/\Aattr\s*/i, "").strip
      val       = value.to_s.strip
      next if attr_name.blank? || val.blank?

      ActiveRecord::Base.transaction(requires_new: true) do
        attribute = Attribute.find_or_create_by!(name: attr_name, product_class: product_class)
        pa        = ProductAttribute.find_or_initialize_by(product_id: product.id, attribute_id: attribute.id)
        pa.value  = val
        pa.save!
      end
    rescue StandardError
      next
    end
  end

  def broadcast_result(upload)
    Turbo::StreamsChannel.broadcast_replace_to(
      "import_status_#{upload.user_id}",
      target: ActionView::RecordIdentifier.dom_id(upload),
      partial: "uploads/row",
      locals: { upload: upload }
    )
  rescue StandardError
    # Broadcast failures must not affect the job outcome
    nil
  end
end
# rubocop:enable Metrics/ClassLength
