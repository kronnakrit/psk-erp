module CustomerParams
  extend ActiveSupport::Concern

  private

  def customer_params
    customer = params.require(:customer)
    permitted = customer.permit(
      :first_name, :last_name, :address, :remark, :country_id, :logistic_company_id
    )

    if customer.key?(:telephones)
      permitted[:telephones] = normalize_telephones_param(customer[:telephones])
    end

    permitted
  end

  def normalize_telephones_param(raw)
    list = case raw
           when Array then raw
           when Hash then raw.values
           when ActionController::Parameters then raw.values
           when String then raw.blank? ? [] : [raw]
           else []
           end

    list.map { |n| n.to_s.strip }.reject(&:blank?)
  end
end
