module TelephonesCoercible
  extend ActiveSupport::Concern

  private

  def coerce_telephones(raw)
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
