FactoryBot.define do
  factory :product_line_similarity do
    association :product_line
    association :similar_product_line, factory: :product_line
  end
end
