class ProductLineSimilarity < ApplicationRecord
  belongs_to :product_line
  belongs_to :similar_product_line, class_name: "ProductLine"

  validates :similar_product_line_id, uniqueness: {scope: :product_line_id}
  validate :not_self_referential

  private

  def not_self_referential
    if product_line_id == similar_product_line_id
      errors.add(:similar_product_line_id, "can't be the same as the product line")
    end
  end
end
