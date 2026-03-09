class Role < ApplicationRecord
  belongs_to :recruiting_company, class_name: "Company"
  belongs_to :target_company, class_name: "Company", optional: true

  validates :title, presence: true

  def formatted_compensation
    return nil unless min_compensation.present? && max_compensation.present?
    
    min_k = (min_compensation / 1000.0).round(1)
    max_k = (max_compensation / 1000.0).round(1)
    
    "$#{min_k}K - $#{max_k}K"
  end
end
